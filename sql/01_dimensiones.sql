-- =====================================================================
-- 01_dimensiones.sql — Tablas de DIMENSIONES del modelo estrella
-- =====================================================================
-- Para cada dimensión:
--   1. CREATE TABLE con sus columnas, tipos y PRIMARY KEY.
--   2. INSERT INTO ... SELECT para cargarla desde las tablas de origen.
--
-- Las tablas de origen (los CSV de raw/) están en el esquema raw:
--     FROM raw.product
-- Para ver qué columnas y tipos tiene una:  DESCRIBE raw.product;
-- Para explorarlas antes de escribir nada:  python run_sql.py --explorar
-- =====================================================================


-- ---------------------------------------------------------------------
-- EJEMPLO RESUELTO: dimensión producto
-- ---------------------------------------------------------------------
-- En raw/ la categoría está en otra tabla y tiene jerarquía
-- (Bottles -> Classic / Sport). En la dimensión la "aplanamos":
-- cada producto queda en una sola fila con su categoría y su familia.
--
-- product_key es la clave SUBROGADA: un número propio del data warehouse.
-- product_id es la clave NATURAL: el ID que viene del sistema de origen.
-- Las tablas de hechos usan product_key; product_id sirve para encontrarla.

CREATE TABLE dim_product (
    product_key INTEGER PRIMARY KEY,
    product_id  INTEGER NOT NULL,
    sku         VARCHAR NOT NULL,
    name        VARCHAR NOT NULL,
    category    VARCHAR,
    family      VARCHAR,
    list_price  DECIMAL(12, 2)
);

INSERT INTO dim_product
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,
    p.product_id,
    p.sku,
    p.name,
    c.name AS category,
    f.name AS family,
    p.list_price
FROM raw.product AS p
LEFT JOIN raw.product_category AS c ON c.category_id = p.category_id
LEFT JOIN raw.product_category AS f ON f.category_id = c.parent_id;


-- ---------------------------------------------------------------------
-- DIMENSIÓN FECHA
-- ---------------------------------------------------------------------

CREATE TABLE dim_date (
    date_key    INTEGER PRIMARY KEY,
    fecha       DATE NOT NULL,
    anio        INTEGER NOT NULL,
    mes         INTEGER NOT NULL,
    nombre_mes  VARCHAR NOT NULL,
    dia         INTEGER NOT NULL,
    nombre_dia  VARCHAR NOT NULL
);

INSERT INTO dim_date
SELECT
    CAST(strftime(fecha, '%Y%m%d') AS INTEGER) AS date_key,
    fecha,
    year(fecha) AS anio,
    month(fecha) AS mes,
    monthname(fecha) AS nombre_mes,
    day(fecha) AS dia,
    dayname(fecha) AS nombre_dia
FROM (
    SELECT CAST(range AS DATE) AS fecha
    FROM range(
        DATE '2024-01-01',
        DATE '2025-10-01',
        INTERVAL 1 DAY
    )
);


CREATE TABLE dim_channel (
    channel_key INTEGER PRIMARY KEY,
    channel_id INTEGER NOT NULL,
    code VARCHAR NOT NULL,
    name VARCHAR NOT NULL
);

INSERT INTO dim_channel
SELECT
    ROW_NUMBER() OVER (ORDER BY channel_id) AS channel_key,
    channel_id,
    code,
    name
FROM raw.channel;


CREATE TABLE dim_customer (
    customer_key INTEGER PRIMARY KEY,
    customer_id INTEGER,
    email VARCHAR,
    first_name VARCHAR,
    last_name VARCHAR,
    phone VARCHAR,
    status CHAR(1),
    created_at TIMESTAMP
);

INSERT INTO dim_customer
SELECT
    -1,
    NULL,
    NULL,
    'Desconocido',
    'Desconocido',
    NULL,
    NULL,
    NULL

UNION ALL

SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id),
    customer_id,
    email,
    first_name,
    last_name,
    phone,
    status,
    created_at
FROM raw.customer;


CREATE TABLE dim_address (
    address_key INTEGER PRIMARY KEY,
    address_id INTEGER,
    line1 VARCHAR,
    line2 VARCHAR,
    city VARCHAR,
    province_id INTEGER,
    province_name VARCHAR,
    province_code VARCHAR,
    postal_code VARCHAR,
    country_code CHAR(2)
);

INSERT INTO dim_address
SELECT
    -1,
    NULL,
    NULL,
    NULL,
    'Desconocido',
    NULL,
    'Desconocido',
    NULL,
    NULL,
    'AR'

UNION ALL

SELECT
    ROW_NUMBER() OVER (ORDER BY a.address_id),
    a.address_id,
    a.line1,
    a.line2,
    a.city,
    a.province_id,
    p.name,
    p.code,
    a.postal_code,
    a.country_code
FROM raw.address AS a
LEFT JOIN raw.province AS p
    ON p.province_id = a.province_id;


CREATE TABLE dim_store (
    store_key INTEGER PRIMARY KEY,
    store_id INTEGER,
    name VARCHAR,
    address_id INTEGER
);

INSERT INTO dim_store
SELECT
    -1,
    NULL,
    'Sin tienda',
    NULL

UNION ALL

SELECT
    ROW_NUMBER() OVER (ORDER BY store_id),
    store_id,
    name,
    address_id
FROM raw.store;