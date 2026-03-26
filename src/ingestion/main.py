import os
import sys
import json
from datetime import datetime, timezone
from google.cloud import storage
import requests

def main():
    # 1. LEER VARIABLES DE ENTORNO (Inyectadas por Terraform/Cloud Run)
    # -----------------------------------------------------------------
    city = os.getenv("CITY")
    api_url = os.getenv("API_URL")
    bucket_name = os.getenv("RAW_BUCKET_NAME")

    if not all([city, api_url, bucket_name]):
        print("❌ ERROR: Faltan variables de entorno (CITY, API_URL, RAW_BUCKET_NAME)")
        sys.exit(1)

    print(f"🚀 Iniciando ingesta Serverless para {city.upper()}")

    # 2. OBTENER DATOS DE LA API ORIGINAL (Reutilizado de tu código)
    # -----------------------------------------------------------------
    try:
        print(f">> Conectando con {api_url} ...")
        response = requests.get(api_url, timeout=30)
        response.raise_for_status() # Lanza error si el status no es 200
        
        data = response.json()
        estaciones = data.get('results', [])

        if not estaciones:
            print(f"⚠️ No se obtuvieron resultados de la API para {city}.")
            sys.exit(0) # Salimos sin error, pero no guardamos nada
            
        print(f"✅ Descargados {len(estaciones)} registros de {city}.")

    except Exception as e:
        print(f"❌ Error al conectar con la API de {city}: {e}")
        sys.exit(1)

    # 3. GUARDAR EN GOOGLE CLOUD STORAGE (El nuevo Data Lake)
    # -----------------------------------------------------------------
    try:
        # Ruta particionada estilo Hive: raw/ciudad/YYYY/MM/DD/HH/archivo.json
        # Permite a Dataflow leer incrementalmente solo la carpeta de la hora anterior
        now = datetime.now(timezone.utc)
        filename = f"raw/{city}/{now.strftime('%Y/%m/%d/%H')}/{city}_{now.strftime('%Y%m%d_%H%M%S')}.json"

        print(f">> Subiendo datos a GCS: gs://{bucket_name}/{filename} ...")
        
        # Conexión a GCP usando la Service Account asignada al Cloud Run
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(filename)

        # Subir el JSON (como texto)
        blob.upload_from_string(
            data=json.dumps(estaciones, ensure_ascii=False),
            content_type='application/json'
        )
        
        print(f"✅ Archivo guardado con éxito en el Bucket Raw.")
        
    except Exception as e:
        print(f"❌ Error al subir a Google Cloud Storage: {e}")
        sys.exit(1)

    print(f"🏁 Ejecución finalizada correctamente para {city}.")

if __name__ == "__main__":
    main()