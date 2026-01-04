{{ config(
    materialized='incremental',
    unique_key='CUSTOMER_ORDER_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{#-
    Raw Data Vault Link: LINK_ORDER_CUSTOMER

    Captures the relationship between orders and customers
    Loaded from: stg_dv_orders

    Composite Primary Key: CUSTOMER_ORDER_HK (hash of CUSTOMER_HK || ORDER_HK)
    Foreign Keys: CUSTOMER_HK, ORDER_HK
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_orders"
src_pk: "CUSTOMER_ORDER_HK"
src_fk:
    - "CUSTOMER_HK"
    - "ORDER_HK"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.link(src_pk=metadata_dict['src_pk'],
                     src_fk=metadata_dict['src_fk'],
                     src_ldts=metadata_dict['src_ldts'],
                     src_source=metadata_dict['src_source'],
                     source_model=metadata_dict['source_model']) }}
