{{ config(
    materialized='incremental',
    unique_key='NATION_REGION_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: "stg_dv_nations"
src_pk: "NATION_REGION_HK"
src_fk:
    - "NATION_HK"
    - "REGION_HK"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.link(src_pk=metadata_dict['src_pk'],
                     src_fk=metadata_dict['src_fk'],
                     src_ldts=metadata_dict['src_ldts'],
                     src_source=metadata_dict['src_source'],
                     source_model=metadata_dict['source_model']) }}
