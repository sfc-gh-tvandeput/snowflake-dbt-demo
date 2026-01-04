{{ config(
    materialized='incremental',
    unique_key='ORDER_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{#-
    Raw Data Vault Hub: HUB_ORDER

    Contains unique list of all order business keys
    Loaded from: stg_dv_orders

    Business Key: ORDER_HK (hash of O_ORDERKEY)
    Natural Key: O_ORDERKEY (Order ID)
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_orders"
src_pk: "ORDER_HK"
src_nk: "O_ORDERKEY"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict['src_pk'],
                    src_nk=metadata_dict['src_nk'],
                    src_ldts=metadata_dict['src_ldts'],
                    src_source=metadata_dict['src_source'],
                    source_model=metadata_dict['source_model']) }}
