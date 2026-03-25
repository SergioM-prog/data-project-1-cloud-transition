import logging
import json
import argparse
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

class ProcessAirData(beam.DoFn):
    """
    Transformación para limpiar y preparar los datos para BigQuery.
    """
    def process(self, element):
        try:
            # El elemento es un string (una línea del archivo o el archivo entero)
            # Como tu JSON es una lista [{}, {}], lo cargamos
            data = json.loads(element)
            
            # Si el JSON es una lista, iteramos sobre cada registro
            # Si es un solo objeto, lo metemos en una lista para unificar
            records = data if isinstance(data, list) else [data]
            
            for record in records:
                # 1. Transformamos los objetos Geo a String para que quepan en el esquema BQ
                if "geo_shape" in record and record["geo_shape"] is not None:
                    record["geo_shape"] = json.dumps(record["geo_shape"])
                
                if "geo_point_2d" in record and record["geo_point_2d"] is not None:
                    record["geo_point_2d"] = json.dumps(record["geo_point_2d"])

                # 2. Aseguramos que objectid sea entero
                if "objectid" in record:
                    record["objectid"] = int(record["objectid"])

                yield record

        except Exception as e:
            logging.error(f"Error procesando registro: {str(e)}")

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True, help='Ruta del bucket GCS: gs://bucket/file.json')
    parser.add_argument('--output', required=True, help='Tabla BQ: proyecto:dataset.tabla')
    parser.add_argument('--temp_location', required=True, help='Ruta temporal GCS para Dataflow')
    
    args, pipeline_args = parser.parse_known_args()
    options = PipelineOptions(pipeline_args)

    with beam.Pipeline(options=options) as p:
        (
            p
            | "Leer de GCS" >> beam.io.ReadFromText(args.input)
            | "Parsear y Limpiar" >> beam.ParDo(ProcessAirData())
            | "Escribir en BigQuery" >> beam.io.WriteToBigQuery(
                args.output,
                schema=None, # Usamos el esquema ya existente en la tabla
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED
            )
        )

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()