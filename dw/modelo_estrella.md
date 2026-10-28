# Modelo estrella

Generado por `run_sql.py` a partir de las tablas de `warehouse.duckdb`.

```mermaid
erDiagram
    dim_address ||--o{ fact_sales_order : "shipping_address_key"
    dim_channel ||--o{ fact_nps_response : "channel_key"
    dim_channel ||--o{ fact_sales_order : "channel_key"
    dim_channel ||--o{ fact_sales_order_item : "channel_key"
    dim_customer ||--o{ fact_nps_response : "customer_key"
    dim_customer ||--o{ fact_sales_order : "customer_key"
    dim_customer ||--o{ fact_sales_order_item : "customer_key"
    dim_customer ||--o{ fact_web_session : "customer_key"
    dim_date ||--o{ fact_nps_response : "date_key"
    dim_date ||--o{ fact_sales_order : "date_key"
    dim_date ||--o{ fact_sales_order_item : "date_key"
    dim_date ||--o{ fact_web_session : "date_key"
    dim_product ||--o{ fact_sales_order_item : "product_key"
    dim_store ||--o{ fact_sales_order : "store_key"
    dim_address {
        INTEGER address_key PK
        INTEGER address_id
        VARCHAR line1
        VARCHAR line2
        VARCHAR city
        INTEGER province_id
        VARCHAR province_name
        VARCHAR province_code
        VARCHAR postal_code
        VARCHAR country_code
    }
    dim_channel {
        INTEGER channel_key PK
        INTEGER channel_id
        VARCHAR code
        VARCHAR name
    }
    dim_customer {
        INTEGER customer_key PK
        INTEGER customer_id
        VARCHAR email
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR phone
        VARCHAR status
        TIMESTAMP created_at
    }
    dim_date {
        INTEGER date_key PK
        DATE fecha
        INTEGER anio
        INTEGER mes
        VARCHAR nombre_mes
        INTEGER dia
        VARCHAR nombre_dia
    }
    dim_product {
        INTEGER product_key PK
        INTEGER product_id
        VARCHAR sku
        VARCHAR name
        VARCHAR category
        VARCHAR family
        DECIMAL list_price
    }
    dim_store {
        INTEGER store_key PK
        INTEGER store_id
        VARCHAR name
        INTEGER address_id
    }
    fact_nps_response {
        BIGINT nps_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        TIMESTAMP responded_at
        SMALLINT score
        BOOLEAN is_promoter
        BOOLEAN is_detractor
    }
    fact_sales_order {
        BIGINT order_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER shipping_address_key FK
        TIMESTAMP order_date
        VARCHAR status
        BOOLEAN is_sale
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_fee
        DECIMAL total_amount
        VARCHAR payment_method
        VARCHAR payment_status
        TIMESTAMP paid_at
        VARCHAR shipment_status
        TIMESTAMP shipped_at
        TIMESTAMP delivered_at
    }
    fact_sales_order_item {
        BIGINT order_item_id PK
        BIGINT order_id
        INTEGER product_key FK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        BOOLEAN is_sale
        INTEGER quantity
        DECIMAL unit_price
        DECIMAL discount_amount
        DECIMAL line_total
    }
    fact_web_session {
        BIGINT session_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        TIMESTAMP started_at
        TIMESTAMP ended_at
        VARCHAR source
        VARCHAR device
    }
```
