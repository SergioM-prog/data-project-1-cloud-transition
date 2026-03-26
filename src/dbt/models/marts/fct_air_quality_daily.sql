{{
    config(
        materialized='incremental',
        unique_key=['fecha_medicion', 'id_estacion'],
        incremental_strategy='merge',
        partition_by={
            'field': 'fecha_medicion',
            'data_type': 'date'
        }
    )
}}

with

source as (

    select * from {{ ref('stg_valencia_air') }}
    where fecha_hora_medicion is not null
    {% if is_incremental() %}
    -- Reprocesa el último día para actualizar el día en curso (datos parciales)
    and DATE(fecha_hora_medicion) >= DATE_SUB((select max(fecha_medicion) from {{ this }}), INTERVAL 1 DAY)
    {% endif %}

),

daily_aggregates as (

    select
        DATE(fecha_hora_medicion)    as fecha_medicion,
        ciudad,
        id_estacion,
        nombre_estacion,
        ROUND(AVG(no2), 2)           as promedio_diario_no2,
        ROUND(AVG(pm10), 2)          as promedio_diario_pm10,
        ROUND(AVG(pm25), 2)          as promedio_diario_pm25,
        ROUND(MAX(no2), 2)           as pico_no2,
        ROUND(MAX(pm10), 2)          as pico_pm10,
        count(*)                     as total_mediciones_dia
    from source
    group by 1, 2, 3, 4

)

select * from daily_aggregates
