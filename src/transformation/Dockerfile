# Imagen base optimizada para Dataflow con Python 3.11
FROM gcr.io/dataflow-templates-base/python311-template-launcher-base

# Variable de entorno que le dice a Dataflow qué archivo ejecutar
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="/app/main.py"

WORKDIR /app

# Copiamos el archivo de requisitos y el código
COPY requirements.txt .

# Instalamos las dependencias
# Nota: Instalamos apache-beam directamente en la imagen
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .



# El entrypoint es fijo para las Flex Templates de Google
ENTRYPOINT ["/opt/google/dataflow/python_template_launcher"]