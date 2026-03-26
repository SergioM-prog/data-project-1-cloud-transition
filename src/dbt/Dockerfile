FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# git es requerido por dbt deps para descargar paquetes desde repositorios
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el proyecto dbt completo
COPY . .

# Pre-instalar paquetes dbt (dbt_utils) en tiempo de build.
# dbt deps solo lee packages.yml y descarga desde dbt Hub, no requiere conexión a BigQuery.
RUN dbt deps --profiles-dir /app

ENTRYPOINT ["dbt", "run", "--target", "prod", "--profiles-dir", "/app"]
