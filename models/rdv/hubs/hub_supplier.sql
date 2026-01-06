{{ config(
    materialized='incremental',
    unique_key='SUPPLIER_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_suppliers
src_pk: SUPPLIER_HK
src_nk: SUPPLIER_KEY
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
