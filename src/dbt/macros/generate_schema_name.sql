{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {# Leemos el entorno dinámicamente. Si no existe, usamos 'dev' por seguridad #}
    {%- set env_suffix = env_var('DBT_ENV', 'dev') -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif custom_schema_name in ('silver', 'gold') -%}
        air_quality_{{ custom_schema_name }}_{{ env_suffix }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
