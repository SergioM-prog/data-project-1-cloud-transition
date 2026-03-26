{{
    config(
        materialized='incremental',
        unique_key=['fecha_hora', 'id_estacion'],
        incremental_strategy='merge',
        partition_by={
            'field': 'fecha_hora',
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
    -- Solo procesa las horas nuevas respecto al máximo ya cargado
    and TIMESTAMP_TRUNC(fecha_hora_medicion, HOUR) > (select max(fecha_hora) from {{ this }})
    {% endif %}

),

hourly_aggregates as (

    select
        TIMESTAMP_TRUNC(fecha_hora_medicion, HOUR) as fecha_hora,
        ciudad,
        id_estacion,
        nombre_estacion,
        ROUND(AVG(no2), 2)   as promedio_no2,
        ROUND(AVG(pm10), 2)  as promedio_pm10,
        ROUND(AVG(pm25), 2)  as promedio_pm25,
        ROUND(AVG(so2), 2)   as promedio_so2,
        ROUND(AVG(o3), 2)    as promedio_ozono,
        ROUND(AVG(co), 2)    as promedio_co,
        count(*)             as total_mediciones_hora
    from source
    group by 1, 2, 3, 4

)

select * from hourly_aggregates
