{{ config(
    materialized='incremental',
    unique_key='SUPPLIER_HK',
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_suppliers
src_pk: SUPPLIER_HK
src_hashdiff: "SUPPLIER_HASHDIFF"
src_payload:
    - "SUPPLIER_NAME"
    - "SUPPLIER_ADDRESS"
    - "NATION_KEY"
    - "SUPPLIER_PHONE"
    - "ACCOUNT_BALANCE"
    - "SUPPLIER_COMMENT"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
