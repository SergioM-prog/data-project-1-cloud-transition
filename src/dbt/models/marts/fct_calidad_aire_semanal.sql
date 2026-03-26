{{
    config(
        materialized='incremental',
        unique_key=['inicio_semana', 'id_estacion'],
        incremental_strategy='merge',
        partition_by={
            'field': 'inicio_semana',
            'data_type': 'date'
        }
    )
}}

with

source as (

    select * from {{ ref('stg_valencia_air') }}
    where fecha_hora_medicion is not null
    {% if is_incremental() %}
    -- Reprocesa los últimos 7 días para actualizar la semana en curso
    and DATE(fecha_hora_medicion) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    {% endif %}

),

weekly_aggregates as (

    select
        DATE_TRUNC(DATE(fecha_hora_medicion), WEEK)                                     as inicio_semana,
        DATE_ADD(DATE_TRUNC(DATE(fecha_hora_medicion), WEEK), INTERVAL 6 DAY)           as fin_semana,
        EXTRACT(WEEK FROM fecha_hora_medicion)                                          as numero_semana,
        EXTRACT(YEAR FROM fecha_hora_medicion)                                          as anio,
        id_estacion,
        nombre_estacion,
        ciudad,
        ROUND(AVG(no2), 2)                                                              as promedio_semanal_no2,
        ROUND(AVG(pm10), 2)                                                             as promedio_semanal_pm10,
        ROUND(AVG(pm25), 2)                                                             as promedio_semanal_pm25,
        ROUND(AVG(so2), 2)                                                              as promedio_semanal_so2,
        ROUND(AVG(o3), 2)                                                               as promedio_semanal_ozono,
        ROUND(AVG(co), 2)                                                               as promedio_semanal_co,
        ROUND(MAX(pm25), 2)                                                             as maximo_pm25_semana,
        ROUND(MAX(pm10), 2)                                                             as maximo_pm10_semana,
        ROUND(MAX(no2), 2)                                                              as maximo_no2_semana,
        ROUND(MIN(pm25), 2)                                                             as minimo_pm25_semana,
        ROUND(MIN(pm10), 2)                                                             as minimo_pm10_semana,
        ROUND(MIN(no2), 2)                                                              as minimo_no2_semana,
        count(*)                                                                        as total_mediciones_semana,
        count(distinct DATE(fecha_hora_medicion))                                       as dias_con_datos,
        case
            when avg(pm25) is null then 'Sin Datos'
            when avg(pm25) <= 10 then 'Semana Buena'
            when avg(pm25) <= 15 then 'Semana Moderada'
            when avg(pm25) <= 25 then 'Semana Pobre'
            else 'Semana Muy Contaminada'
        end as clasificacion_semana
    from source
    group by 1, 2, 3, 4, 5, 6, 7

)

select * from weekly_aggregates
