{{ config(
    materialized='incremental',
    unique_key='CUSTOMER_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_customers
src_pk: CUSTOMER_HK
src_nk: CUSTOMER_KEY
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}

{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
