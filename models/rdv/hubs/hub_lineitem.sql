{{ config(
    materialized='incremental',
    unique_key='LINEITEM_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{#-
    Raw Data Vault Hub: HUB_LINEITEM

    Pattern: Hub (Unique business keys only)
    Grain: One row per unique lineitem (composite key: order_key + line_number)
    Source: TPC-H LINEITEM table via stg_dv_lineitem

    Note: LINEITEM has a composite business key (ORDER_KEY, LINE_NUMBER)
    The hash key LINEITEM_HK is generated from both columns
-#}

{%- set yaml_metadata -%}
source_model: stg_dv_lineitem
src_pk: LINEITEM_HK
src_nk:
    - "ORDER_KEY"
    - "LINE_NUMBER"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
