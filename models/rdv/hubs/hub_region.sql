{{ config(
    materialized='incremental',
    unique_key='REGION_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{#-
    Raw Data Vault Hub: HUB_REGION

    Pattern: Hub (Unique business keys only)
    Grain: One row per unique region
    Source: TPC-H REGION table via stg_dv_regions
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_regions"
src_pk: "REGION_HK"
src_nk: "REGION_KEY"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict['src_pk'],
                    src_nk=metadata_dict['src_nk'],
                    src_ldts=metadata_dict['src_ldts'],
                    src_source=metadata_dict['src_source'],
                    source_model=metadata_dict['source_model']) }}
