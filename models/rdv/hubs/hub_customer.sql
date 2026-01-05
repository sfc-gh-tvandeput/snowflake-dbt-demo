{{ config(
    materialized='incremental',
    unique_key='CUSTOMER_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{#-
    Raw Data Vault Hub: HUB_CUSTOMER

    Contains unique list of all customer business keys
    Loaded from: stg_dv_customers

    Business Key: CUSTOMER_HK (hash of CUSTOMER_KEY)
    Natural Key: CUSTOMER_KEY (Customer ID)
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_customers"
src_pk: "CUSTOMER_HK"
src_nk: "CUSTOMER_KEY"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict['src_pk'],
                    src_nk=metadata_dict['src_nk'],
                    src_ldts=metadata_dict['src_ldts'],
                    src_source=metadata_dict['src_source'],
                    source_model=metadata_dict['source_model']) }}
