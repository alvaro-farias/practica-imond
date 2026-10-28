-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================


SELECT product_key, name, category, family, list_price
FROM dim_product
ORDER BY product_key;


-- VENTAS TOTALES

SELECT
    SUM(total_amount) AS ventas_totales
FROM fact_sales_order
WHERE is_sale = TRUE;


-- TICKET PROMEDIO

SELECT
    SUM(total_amount) / COUNT(*) AS ticket_promedio
FROM fact_sales_order
WHERE is_sale = TRUE;


-- USUARIOS ACTIVOS

SELECT
    COUNT(
        DISTINCT CASE
            WHEN customer_key <> -1
                THEN 'cliente_' || CAST(customer_key AS VARCHAR)
            ELSE
                'anonimo_' || CAST(session_id AS VARCHAR)
        END
    ) AS usuarios_activos
FROM fact_web_session;


-- NPS

SELECT
    (
        100.0 * SUM(CASE WHEN is_promoter THEN 1 ELSE 0 END) / COUNT(*)
        -
        100.0 * SUM(CASE WHEN is_detractor THEN 1 ELSE 0 END) / COUNT(*)
    ) AS nps
FROM fact_nps_response;


-- VENTAS POR PROVINCIA

SELECT
    a.province_name AS provincia,
    SUM(f.total_amount) AS ventas_totales
FROM fact_sales_order AS f
JOIN dim_address AS a
    ON a.address_key = f.shipping_address_key
WHERE f.is_sale = TRUE
GROUP BY a.province_name
ORDER BY ventas_totales DESC;


-- RANKING MENSUAL POR PRODUCTO

SELECT
    d.anio,
    d.mes,
    d.nombre_mes,
    p.name AS producto,
    SUM(f.line_total) AS ventas_producto
FROM fact_sales_order_item AS f
JOIN dim_date AS d
    ON d.date_key = f.date_key
JOIN dim_product AS p
    ON p.product_key = f.product_key
WHERE f.is_sale = TRUE
GROUP BY
    d.anio,
    d.mes,
    d.nombre_mes,
    p.name
ORDER BY
    d.anio,
    d.mes,
    ventas_producto DESC;