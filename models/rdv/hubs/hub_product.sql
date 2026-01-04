{{ config(
    materialized='incremental',
    unique_key='PART_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{#-
    Raw Data Vault Hub: HUB_PRODUCT

    Contains unique list of all product/part business keys
    Loaded from: stg_dv_lineitem

    Business Key: PART_HK (hash of L_PARTKEY)
    Natural Key: L_PARTKEY (Part/Product ID)

    Note: In TPC-H, parts are products
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_lineitem"
src_pk: "PART_HK"
src_nk: "L_PARTKEY"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict['src_pk'],
                    src_nk=metadata_dict['src_nk'],
                    src_ldts=metadata_dict['src_ldts'],
                    src_source=metadata_dict['src_source'],
                    source_model=metadata_dict['source_model']) }}
