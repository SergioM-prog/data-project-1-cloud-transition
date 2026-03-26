SELECT
    -- Identificadores
    objectid                                    AS id_estacion,
    fiwareid                                    AS fiware_id,
    nombre                                      AS nombre_estacion,
    'Valencia'                                  AS ciudad,

    -- Contaminantes (ya son FLOAT64 en BigQuery, no requieren cast)
    no2,
    pm10,
    pm25,
    so2,
    o3,
    co,

    -- Metadatos de calidad y zona
    calidad_am                                  AS estado_calidad_aire,
    direccion,
    tipozona                                    AS tipo_zona,
    tipoemisio                                  AS tipo_emision,
    parametros                                  AS parametros_medidos,
    mediciones                                  AS mediciones_texto,

    -- Coordenadas extraídas del STRING JSON (geo_point_2d serializado por Dataflow)
    CAST(JSON_VALUE(geo_point_2d, '$.lat') AS FLOAT64) AS latitud,
    CAST(JSON_VALUE(geo_point_2d, '$.lon') AS FLOAT64) AS longitud,

    -- Timestamps
    fecha_carg                                  AS fecha_hora_medicion

FROM {{ source('air_quality', 'valencia_air') }}

WHERE fecha_carg IS NOT NULL
