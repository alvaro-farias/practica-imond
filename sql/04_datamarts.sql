SELECT
    d.fecha,
    d.anio,
    d.mes,
    d.nombre_mes,
    c.code AS canal,
    a.province_name AS provincia,
    SUM(f.total_amount) AS ventas_totales,
    COUNT(*) AS cantidad_pedidos,
    SUM(f.total_amount) / COUNT(*) AS ticket_promedio
FROM fact_sales_order AS f
JOIN dim_date AS d
    ON d.date_key = f.date_key
JOIN dim_channel AS c
    ON c.channel_key = f.channel_key
JOIN dim_address AS a
    ON a.address_key = f.shipping_address_key
WHERE f.is_sale = TRUE
GROUP BY
    d.fecha,
    d.anio,
    d.mes,
    d.nombre_mes,
    c.code,
    a.province_name
ORDER BY d.fecha;


SELECT
    d.fecha,
    d.anio,
    d.mes,
    d.nombre_mes,
    COUNT(
        DISTINCT CASE
            WHEN f.customer_key <> -1
                THEN 'cliente_' || CAST(f.customer_key AS VARCHAR)
            ELSE
                'anonimo_' || CAST(f.session_id AS VARCHAR)
        END
    ) AS usuarios_activos
FROM fact_web_session AS f
JOIN dim_date AS d
    ON d.date_key = f.date_key
GROUP BY
    d.fecha,
    d.anio,
    d.mes,
    d.nombre_mes
ORDER BY d.fecha;


SELECT
    d.fecha,
    d.anio,
    d.mes,
    d.nombre_mes,
    c.code AS canal,
    (
        100.0 * SUM(CASE WHEN f.is_promoter THEN 1 ELSE 0 END) / COUNT(*)
        -
        100.0 * SUM(CASE WHEN f.is_detractor THEN 1 ELSE 0 END) / COUNT(*)
    ) AS nps
FROM fact_nps_response AS f
JOIN dim_date AS d
    ON d.date_key = f.date_key
JOIN dim_channel AS c
    ON c.channel_key = f.channel_key
GROUP BY
    d.fecha,
    d.anio,
    d.mes,
    d.nombre_mes,
    c.code
ORDER BY d.fecha;


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