{{ config(
    materialized='incremental',
    unique_key='CUSTOMER_NATION_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_customers
src_pk: CUSTOMER_NATION_HK
src_fk:
    - "CUSTOMER_HK"
    - "NATION_HK"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.link(**fromyaml(yaml_metadata)) }}
