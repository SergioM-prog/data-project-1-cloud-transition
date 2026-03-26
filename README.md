# Air Quality Valencia — Cloud Pipeline

Pipeline serverless de monitorización de calidad del aire para Valencia, desplegado sobre Google Cloud Platform con arquitectura medallón (Bronze → Silver → Gold).

---

## Arquitectura

```
API Valencia (tiempo real)
        │
        ▼
┌─────────────────┐
│  Cloud Run Job  │  Ingesta horaria → GCS (Raw)
│   (ingestion)   │
└────────┬────────┘
         │  cada :30
         ▼
┌─────────────────┐
│    Dataflow     │  Flex Template → BigQuery Bronze
│ (transformation)│  air_quality_bronze_{env}
└────────┬────────┘
         │  cada :45
         ▼
┌─────────────────────────────────────────────────┐
│               BigQuery — Arquitectura Medallón  │
│                                                 │
│  BRONZE  →  SILVER (dbt staging)  →  GOLD       │
│  (raw)      air_quality_silver_{env}   (marts)  │
│             vistas normalizadas   air_quality_  │
│                                   gold_{env}    │
└─────────────────────────────────────────────────┘
         ▲
         │  cada :00
┌─────────────────┐
│  Cloud Run Job  │  dbt run (transforma Bronze → Silver → Gold)
│   (dbt runner)  │
└─────────────────┘

Toda la orquestación es gestionada por Cloud Scheduler.
```

### Componentes

| Servicio | Descripción |
|---|---|
| **Cloud Run Job** `ingestion` | Descarga datos de la API de Valencia y los deposita en GCS |
| **Dataflow** `transformation` | Flex Template que lee GCS y escribe en BigQuery Bronze |
| **Cloud Run Job** `dbt-runner` | Ejecuta `dbt run` para transformar Bronze → Silver → Gold |
| **Cloud Scheduler** | Orquesta los tres jobs con cadencia horaria |
| **BigQuery** | Data Warehouse con arquitectura medallón (3 datasets por entorno) |
| **Artifact Registry** | Repositorio Docker para las imágenes de los tres jobs |
| **Terraform** | Gestiona toda la infraestructura como código |

---

## Prerrequisitos

- [gcloud CLI](https://cloud.google.com/sdk/docs/install) instalado y autenticado
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) en ejecución
- Proyecto GCP con facturación activa
- Perfil de gcloud configurado con proyecto y región:

```bash
gcloud config set project TU_PROJECT_ID
gcloud config set compute/region europe-west1
gcloud auth application-default login
```

---

## Despliegue

Todo el ciclo de vida de la infraestructura se gestiona con un único script interactivo desde la raíz del repositorio:

```bash
./deploy.sh
```

### Selección de entorno

Al ejecutar el script, se pedirá el entorno objetivo:

```
¿Qué entorno quieres desplegar? (ej: dev, prod):
```

Introduce `dev` o `prod`. El script valida que exista la carpeta `envs/{entorno}/` antes de continuar.

### Configuración automática desde gcloud

El script **no requiere ningún archivo de variables manual**. Lee directamente del perfil activo de gcloud:

```bash
PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud config get-value compute/region)
```

Con esos valores genera automáticamente el `terraform.tfvars` para cada capa (`00_base` y `01_app`) antes de cada apply. Se mostrará un resumen para confirmación antes de proceder:

```
Entorno  : dev
Proyecto : mi-proyecto-123
Región   : europe-west1
Repo     : europe-west1-docker.pkg.dev/mi-proyecto-123/air-quality-dev

¿Continuar con el despliegue en este proyecto y región? (yes/no):
```

### Fases del despliegue

| Fase | Acción |
|---|---|
| **0** | Activa las APIs de GCP necesarias (idempotente) |
| **1** | `terraform apply` en `00_base` — datasets BigQuery, buckets GCS, service accounts, IAM |
| **2** | `docker build` + `docker push` de las 3 imágenes (ingestion, transformation, dbt) |
| **2.5** | Registra la Flex Template de Dataflow en Cloud Storage |
| **3** | `terraform apply` en `01_app` — Cloud Run Jobs y Cloud Schedulers |

---

## Destrucción de infraestructura

Al finalizar el despliegue, el script ofrece destruir todos los recursos **únicamente si el entorno elegido es `dev`**:

```
¿Quieres hacer un terraform destroy del entorno dev? (destroy/no):
```

Si se responde `destroy`, la destrucción se ejecuta **automáticamente sin confirmación adicional** (`-auto-approve`), eliminando primero `01_app` y luego `00_base` para respetar las dependencias. En entornos distintos de `dev` esta opción no se ofrece.

> **Nota:** El destroy incluye los datasets de BigQuery y su contenido. En dev esto es intencionado para permitir ciclos de prueba limpios.

---

## Estructura del repositorio

```
.
├── deploy.sh                   # Script de despliegue único
├── envs/
│   └── dev/
│       └── terraform/
│           ├── 00_base/        # Infraestructura base (BQ, GCS, SAs, IAM)
│           └── 01_app/         # Computación (Cloud Run Jobs, Schedulers)
├── modules/                    # Módulos Terraform reutilizables
├── src/
│   ├── ingestion/              # Cloud Run Job — descarga API Valencia
│   ├── transformation/         # Dataflow Flex Template — GCS → BigQuery
│   └── dbt/                    # Transformaciones SQL (Bronze → Silver → Gold)
│       ├── models/
│       │   ├── staging/        # Capa Silver: vistas normalizadas
│       │   └── marts/          # Capa Gold: tablas incrementales y particionadas
│       ├── macros/
│       └── profiles.yml
└── README.md
```

---

## Variables de entorno de dbt

El Cloud Run Job de dbt recibe las siguientes variables inyectadas por Terraform:

| Variable | Descripción | Ejemplo |
|---|---|---|
| `DBT_PROJECT_ID` | ID del proyecto GCP | `mi-proyecto-123` |
| `DBT_ENV` | Sufijo del entorno para los datasets | `dev` / `prod` |

Estas variables determinan los datasets que dbt utiliza en tiempo de ejecución:
- Fuente: `air_quality_bronze_{DBT_ENV}`
- Staging: `air_quality_silver_{DBT_ENV}`
- Marts: `air_quality_gold_{DBT_ENV}`

dbt **nunca crea datasets**: los tres son creados previamente por Terraform y dbt únicamente opera sobre ellos.
