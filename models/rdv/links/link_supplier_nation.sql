{{ config(
    materialized='incremental',
    unique_key='SUPPLIER_NATION_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_suppliers
src_pk: SUPPLIER_NATION_HK
src_fk:
    - "SUPPLIER_HK"
    - "NATION_HK"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.link(**fromyaml(yaml_metadata)) }}
