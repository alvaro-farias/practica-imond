-- =====================================================================
-- 02_hechos.sql — Tablas de HECHOS del modelo estrella
-- =====================================================================


CREATE TABLE fact_sales_order (
    order_id BIGINT PRIMARY KEY,

    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    store_key INTEGER NOT NULL REFERENCES dim_store(store_key),
    shipping_address_key INTEGER NOT NULL REFERENCES dim_address(address_key),

    order_date TIMESTAMP NOT NULL,
    status VARCHAR NOT NULL,
    is_sale BOOLEAN NOT NULL,

    subtotal DECIMAL(12, 2),
    tax_amount DECIMAL(12, 2),
    shipping_fee DECIMAL(12, 2),
    total_amount DECIMAL(12, 2),

    payment_method VARCHAR,
    payment_status VARCHAR,
    paid_at TIMESTAMP,

    shipment_status VARCHAR,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP
);

INSERT INTO fact_sales_order
SELECT
    o.order_id,

    d.date_key,
    COALESCE(c.customer_key, -1),
    ch.channel_key,
    COALESCE(st.store_key, -1),
    COALESCE(a.address_key, -1),

    o.order_date,
    o.status,
    o.status IN ('PAID', 'FULFILLED') AS is_sale,

    o.subtotal,
    o.tax_amount,
    o.shipping_fee,
    o.total_amount,

    p.method,
    p.status,
    p.paid_at,

    sh.status,
    sh.shipped_at,
    sh.delivered_at

FROM raw.sales_order AS o

JOIN dim_date AS d
    ON d.fecha = CAST(o.order_date AS DATE)

LEFT JOIN dim_customer AS c
    ON c.customer_id = o.customer_id

JOIN dim_channel AS ch
    ON ch.channel_id = o.channel_id

LEFT JOIN dim_store AS st
    ON st.store_id = o.store_id

LEFT JOIN dim_address AS a
    ON a.address_id = o.shipping_address_id

LEFT JOIN raw.payment AS p
    ON p.order_id = o.order_id

LEFT JOIN raw.shipment AS sh
    ON sh.order_id = o.order_id;



CREATE TABLE fact_sales_order_item (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,

    product_key INTEGER NOT NULL REFERENCES dim_product(product_key),
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),

    is_sale BOOLEAN NOT NULL,

    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12, 2),
    discount_amount DECIMAL(12, 2),
    line_total DECIMAL(12, 2)
);

INSERT INTO fact_sales_order_item
SELECT
    i.order_item_id,
    i.order_id,

    p.product_key,
    d.date_key,
    COALESCE(c.customer_key, -1),
    ch.channel_key,

    o.status IN ('PAID', 'FULFILLED') AS is_sale,

    i.quantity,
    i.unit_price,
    i.discount_amount,
    i.line_total

FROM raw.sales_order_item AS i

JOIN raw.sales_order AS o
    ON o.order_id = i.order_id

JOIN dim_product AS p
    ON p.product_id = i.product_id

JOIN dim_date AS d
    ON d.fecha = CAST(o.order_date AS DATE)

LEFT JOIN dim_customer AS c
    ON c.customer_id = o.customer_id

JOIN dim_channel AS ch
    ON ch.channel_id = o.channel_id;



CREATE TABLE fact_web_session (
    session_id BIGINT PRIMARY KEY,

    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),

    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    source VARCHAR,
    device VARCHAR
);

INSERT INTO fact_web_session
SELECT
    w.session_id,

    d.date_key,
    COALESCE(c.customer_key, -1),

    w.started_at,
    w.ended_at,
    w.source,
    w.device

FROM raw.web_session AS w

JOIN dim_date AS d
    ON d.fecha = CAST(w.started_at AS DATE)

LEFT JOIN dim_customer AS c
    ON c.customer_id = w.customer_id;



CREATE TABLE fact_nps_response (
    nps_id BIGINT PRIMARY KEY,

    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),

    responded_at TIMESTAMP NOT NULL,
    score SMALLINT NOT NULL,

    is_promoter BOOLEAN NOT NULL,
    is_detractor BOOLEAN NOT NULL
);

INSERT INTO fact_nps_response
SELECT
    n.nps_id,

    d.date_key,
    COALESCE(c.customer_key, -1),
    ch.channel_key,

    n.responded_at,
    n.score,

    n.score >= 9 AS is_promoter,
    n.score <= 6 AS is_detractor

FROM raw.nps_response AS n

JOIN dim_date AS d
    ON d.fecha = CAST(n.responded_at AS DATE)

LEFT JOIN dim_customer AS c
    ON c.customer_id = n.customer_id

JOIN dim_channel AS ch
    ON ch.channel_id = n.channel_id;