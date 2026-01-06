{{ config(
    materialized='incremental',
    unique_key='LINEITEM_ORDER_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{#-
    Raw Data Vault Link: LINK_LINEITEM_ORDER

    Captures the relationship between line items and orders
    Loaded from: stg_dv_lineitem

    Composite Primary Key: LINEITEM_ORDER_HK (hash of LINEITEM_HK || ORDER_HK)
    Foreign Keys: LINEITEM_HK, ORDER_HK
-#}

{%- set yaml_metadata -%}
source_model: stg_dv_lineitem
src_pk: LINEITEM_ORDER_HK
src_fk:
    - "LINEITEM_HK"
    - "ORDER_HK"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.link(**fromyaml(yaml_metadata)) }}
