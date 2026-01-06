{{ config(
    materialized='incremental',
    unique_key='PART_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{#-
    Raw Data Vault Hub: HUB_PRODUCT

    Contains unique list of all product/part business keys
    Loaded from: stg_dv_lineitem

    Business Key: PART_HK (hash of PART_KEY)
    Natural Key: PART_KEY (Part/Product ID)

    Note: In TPC-H, parts are products
-#}

{%- set yaml_metadata -%}
source_model: stg_dv_lineitem
src_pk: PART_HK
src_nk: PART_KEY
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
