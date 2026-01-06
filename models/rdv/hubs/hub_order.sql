{{ config(
    materialized='incremental',
    unique_key='ORDER_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_orders
src_pk: ORDER_HK
src_nk: ORDER_KEY
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}

{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
