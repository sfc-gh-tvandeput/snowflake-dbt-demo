{{ config(
    materialized='incremental',
    unique_key='LINEITEM_SUPPLIER_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_lineitem
src_pk: LINEITEM_SUPPLIER_HK
src_fk:
    - "LINEITEM_HK"
    - "SUPPLIER_HK"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.link(**fromyaml(yaml_metadata)) }}
