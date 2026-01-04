{{ config(
    materialized='incremental',
    unique_key=['CUSTOMER_HK', 'LOAD_DATE'],
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{#-
    Raw Data Vault Satellite: SAT_CUSTOMER

    Contains descriptive attributes for customers with full history
    Parent Hub: HUB_CUSTOMER
    Loaded from: stg_dv_customers

    Tracks changes via: CUSTOMER_HASHDIFF
    Payload: Customer name, address, phone, account balance, market segment, comment
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_customers"
src_pk: "CUSTOMER_HK"
src_hashdiff:
    source_column: "CUSTOMER_HASHDIFF"
    alias: "HASHDIFF"
src_payload:
    - "CUSTOMER_NAME"
    - "CUSTOMER_ADDRESS"
    - "NATION_KEY"
    - "CUSTOMER_PHONE"
    - "ACCOUNT_BALANCE"
    - "MARKET_SEGMENT"
    - "CUSTOMER_COMMENT"
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
