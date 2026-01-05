{{ config(
    materialized='incremental',
    unique_key='LINEITEM_HK',
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: "stg_dv_lineitem"
src_pk: "LINEITEM_HK"
src_hashdiff: "LINEITEM_HASHDIFF"
src_payload:
    - "QUANTITY"
    - "EXTENDED_PRICE"
    - "DISCOUNT"
    - "TAX"
    - "RETURN_FLAG"
    - "LINE_STATUS"
    - "SHIP_DATE"
    - "COMMIT_DATE"
    - "RECEIPT_DATE"
    - "SHIP_INSTRUCT"
    - "SHIP_MODE"
    - "LINE_COMMENT"
src_eff: "LOAD_DATE"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.sat(src_pk=metadata_dict['src_pk'],
                    src_hashdiff=metadata_dict['src_hashdiff'],
                    src_payload=metadata_dict['src_payload'],
                    src_eff=metadata_dict['src_eff'],
                    src_ldts=metadata_dict['src_ldts'],
                    src_source=metadata_dict['src_source'],
                    source_model=metadata_dict['source_model']) }}
