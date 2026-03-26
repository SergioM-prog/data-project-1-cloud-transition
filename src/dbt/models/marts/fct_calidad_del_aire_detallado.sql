{{
    config(
        materialized='incremental',
        unique_key=['fecha_hora_medicion', 'id_estacion'],
        incremental_strategy='merge',
        partition_by={
            'field': 'fecha_hora_medicion',
            'data_type': 'timestamp',
            'granularity': 'day'
        }
    )
}}

with

source as (

    select * from {{ ref('stg_valencia_air') }}
    where fecha_hora_medicion is not null
    {% if is_incremental() %}
    -- Solo procesa registros más nuevos que el último ya cargado
    and fecha_hora_medicion > (select max(fecha_hora_medicion) from {{ this }})
    {% endif %}

),

detailed_measurements as (

    select
        fecha_hora_medicion,
        TIMESTAMP_TRUNC(fecha_hora_medicion, HOUR)          as hora_agrupada,
        DATE(fecha_hora_medicion)                           as fecha,
        EXTRACT(HOUR FROM fecha_hora_medicion)              as hora_del_dia,
        EXTRACT(DAYOFWEEK FROM fecha_hora_medicion)         as dia_semana,
        id_estacion,
        nombre_estacion,
        'Valencia' as ciudad,
        no2  as dioxido_nitrogeno,
        pm10 as particulas_gruesas,
        pm25 as particulas_finas,
        so2  as dioxido_azufre,
        o3   as ozono,
        co   as monoxido_carbono,
        estado_calidad_aire,
        case
            when pm25 is null then 'Sin Datos'
            when pm25 <= 5    then 'Excelente'
            when pm25 <= 10   then 'Buena'
            when pm25 <= 15   then 'Moderada'
            when pm25 <= 25   then 'Pobre'
            when pm25 <= 35   then 'Muy Pobre'
            else 'Peligrosa'
        end as clasificacion_pm25,
        case
            when no2 is null then 'Sin Datos'
            when no2 <= 10   then 'Excelente'
            when no2 <= 25   then 'Buena'
            when no2 <= 40   then 'Moderada'
            when no2 <= 50   then 'Pobre'
            else 'Peligrosa'
        end as clasificacion_no2
    from source

)

select * from detailed_measurements
order by fecha_hora_medicion desc
