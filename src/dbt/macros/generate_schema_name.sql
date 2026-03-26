{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name in ('silver', 'gold') -%}
        air_quality_{{ custom_schema_name }}_{{ target.name }}
    {%- else -%}
        {{ target.schema }}
    {%- endif -%}
{%- endmacro %}
