FROM python:3.11-slim

#Variables de entorno recomendadas para contenedores Python en GCP
# Evita que Python escriba archivos .pyc temporales
ENV PYTHONDONTWRITEBYTECODE=1

# Obliga a que los print() salgan inmediatamente a los logs de Google Cloud
ENV PYTHONUNBUFFERED=1

# Creamos la carpeta de trabajo dentro del contenedor
WORKDIR /app


# Copiamos PRIMERO el archivo de dependencias. Hacerlo así hace que Docker use su caché y construya mucho más rápido si solo se cambia el código
COPY requirements.txt .


RUN pip install --no-cache-dir -r requirements.txt


COPY . .


CMD ["python", "main.py"]