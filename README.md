# EcoBottle AR — Data Warehouse y Dashboard Comercial

## Descripción

Este trabajo práctico tiene como objetivo construir un pequeño ecosistema de datos para EcoBottle AR a partir de las tablas provistas en la carpeta `raw/`.

A partir de esos datos se construyó un modelo estrella utilizando SQL y DuckDB, compuesto por dimensiones y tablas de hechos. Luego se generaron Data Marts con la información necesaria para calcular los principales indicadores comerciales.

Finalmente, los resultados fueron utilizados como fuente para un dashboard interactivo desarrollado en Looker Studio.

Los principales indicadores analizados son:

- Ventas Totales
- Usuarios Activos
- Ticket Promedio
- NPS
- Ventas por Provincia
- Ranking Mensual por Producto

---

## Estructura del proyecto

```text
practica-imond/
│
├── raw/
│   └── Datos originales en formato CSV
│
├── sql/
│   ├── 01_dimensiones.sql
│   ├── 02_hechos.sql
│   ├── 03_consultas.sql
│   └── 04_datamarts.sql
│
├── dw/
│   ├── Dimensiones exportadas a CSV
│   ├── Hechos exportados a CSV
│   ├── Data Marts exportados a CSV
│   └── modelo_estrella.md
│
├── generator/
│   └── Archivos utilizados para generar los datos originales
│
├── run_sql.py
├── requirements.txt
└── README.md
```

El flujo general utilizado es:

```text
raw/
  ↓
SQL
  ↓
Modelo estrella
  ↓
Data Marts
  ↓
dw/
  ↓
Looker Studio
```

Los archivos de `raw/` se consideran las fuentes originales y no son modificados.

---

## Instalación y ejecución

### 1. Crear el entorno virtual

Desde la carpeta del proyecto:

```bash
python -m venv .venv
```

En Windows:

```powershell
.\.venv\Scripts\Activate.ps1
```

En Mac/Linux:

```bash
source .venv/bin/activate
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Explorar los datos originales

Para abrir DuckDB con las tablas de `raw/`:

```bash
python run_sql.py --explorar
```

Esto permite consultar las tablas originales antes de ejecutar las transformaciones.

Por ejemplo:

```sql
SELECT *
FROM raw.sales_order
LIMIT 10;
```

### 4. Construir el Data Warehouse

```bash
python run_sql.py
```

Este comando:

1. Crea nuevamente `warehouse.duckdb`.
2. Ejecuta los archivos de `sql/` en orden.
3. Construye las dimensiones y hechos.
4. Ejecuta las consultas de los Data Marts.
5. Exporta los resultados en formato CSV dentro de `dw/`.
6. Genera el archivo `dw/modelo_estrella.md`.

### 5. Abrir el Data Warehouse en DuckDB

```bash
python run_sql.py --ui
```

Esto permite revisar visualmente las tablas y ejecutar consultas sobre el modelo construido.

---

# Modelo estrella

El modelo fue diseñado separando dimensiones descriptivas de tablas de hechos.

## Dimensiones

### `dim_date`

Dimensión utilizada para realizar análisis temporales.

| Campo | Descripción |
|---|---|
| `date_key` | Clave de la fecha en formato YYYYMMDD |
| `fecha` | Fecha |
| `anio` | Año |
| `mes` | Número de mes |
| `nombre_mes` | Nombre del mes |
| `dia` | Día del mes |
| `nombre_dia` | Nombre del día |

---

### `dim_product`

Contiene la información de los productos.

| Campo | Descripción |
|---|---|
| `product_key` | Clave subrogada del producto |
| `product_id` | Identificador original |
| `sku` | Código del producto |
| `name` | Nombre |
| `category` | Categoría |
| `family` | Familia |
| `list_price` | Precio de lista |

La jerarquía de categorías se desnormaliza dentro de esta dimensión.

---

### `dim_customer`

Información de clientes.

| Campo | Descripción |
|---|---|
| `customer_key` | Clave subrogada |
| `customer_id` | Identificador original |
| `email` | Correo electrónico |
| `first_name` | Nombre |
| `last_name` | Apellido |
| `status` | Estado del cliente |

Se utiliza la clave `-1` para representar clientes desconocidos o sesiones anónimas cuando corresponde.

---

### `dim_channel`

Canales comerciales.

| Campo | Descripción |
|---|---|
| `channel_key` | Clave subrogada |
| `channel_id` | Identificador original |
| `code` | Código del canal |
| `name` | Nombre |

Los principales canales son `ONLINE` y `OFFLINE`.

---

### `dim_address`

Información geográfica utilizada principalmente para analizar ventas por provincia.

| Campo | Descripción |
|---|---|
| `address_key` | Clave subrogada |
| `address_id` | Identificador original |
| `city` | Ciudad |
| `province_name` | Provincia |
| `postal_code` | Código postal |
| `country_code` | País |

---

### `dim_store`

Información sobre los locales físicos.

| Campo | Descripción |
|---|---|
| `store_key` | Clave subrogada |
| `store_id` | Identificador original |
| `name` | Nombre de la tienda |
| `address_id` | Dirección asociada |

---

# Tablas de hechos

## `fact_sales_order`

**Grano:** una fila representa un pedido realizado por un cliente, en un canal y una fecha determinada.

Contiene información proveniente principalmente de:

- `sales_order`
- `payment`
- `shipment`

Campos principales:

| Campo | Descripción |
|---|---|
| `order_id` | Identificador del pedido |
| `date_key` | Fecha del pedido |
| `customer_key` | Cliente |
| `channel_key` | Canal |
| `shipping_address_key` | Dirección de envío |
| `total_amount` | Importe total |
| `is_sale` | Indica si el pedido cuenta como venta |

Se consideran ventas los pedidos con estado `PAID` o `FULFILLED`.

---

## `fact_sales_order_item`

**Grano:** una fila representa un producto dentro de un pedido.

Campos principales:

| Campo | Descripción |
|---|---|
| `order_item_id` | Identificador del ítem |
| `order_id` | Pedido |
| `product_key` | Producto |
| `date_key` | Fecha |
| `channel_key` | Canal |
| `quantity` | Cantidad |
| `line_total` | Importe de la línea |
| `is_sale` | Indica si corresponde a una venta |

Esta tabla se utiliza principalmente para analizar las ventas por producto.

---

## `fact_web_session`

**Grano:** una fila representa una sesión de navegación web.

Campos principales:

| Campo | Descripción |
|---|---|
| `session_id` | Identificador de sesión |
| `customer_key` | Cliente, si inició sesión |
| `date_key` | Fecha |
| `source` | Origen de la visita |
| `device` | Dispositivo |

Es la fuente utilizada para calcular usuarios activos.

---

## `fact_nps_response`

**Grano:** una fila representa una respuesta a una encuesta NPS.

Campos principales:

| Campo | Descripción |
|---|---|
| `nps_id` | Identificador de respuesta |
| `customer_key` | Cliente |
| `channel_key` | Canal |
| `date_key` | Fecha |
| `score` | Puntaje de 0 a 10 |
| `is_promoter` | Indica si el puntaje es 9 o 10 |
| `is_detractor` | Indica si el puntaje se encuentra entre 0 y 6 |

---

# Data Marts

Los Data Marts se generan a partir del modelo estrella. Ninguno consume directamente las tablas de `raw/`.

## `mart_ventas.csv`

Contiene una fila por pedido válido como venta.

Se utiliza para:

- Ventas Totales
- Ticket Promedio
- Evolución temporal de ventas
- Análisis por canal
- Análisis por provincia

---

## `mart_usuarios_activos.csv`

Contiene la cantidad de usuarios activos por fecha.

Para usuarios identificados se utiliza `customer_key`. Para usuarios anónimos se utiliza `session_id`.

Se utiliza para:

- Tarjeta de Usuarios Activos
- Evolución temporal de Usuarios Activos

---

## `mart_nps.csv`

Contiene el NPS agregado por mes y canal.

Se utiliza para:

- Tarjeta de NPS
- Tendencia mensual de NPS
- Comparación por canal

---

## `mart_ranking_producto.csv`

Contiene las ventas mensuales agrupadas por producto.

Se utiliza para construir el Ranking Mensual por Producto.

---

## `mart_ventas_detalle.csv`

Contiene información de ventas con mayor nivel de detalle.

Incluye:

- Fecha
- Canal
- Provincia
- Producto
- Categoría
- Unidades vendidas
- Importe vendido

Se utiliza principalmente para los gráficos y filtros interactivos del dashboard.

---

# Definición de KPIs

## Ventas Totales

Se consideran únicamente pedidos válidos como venta.

```sql
SUM(total_amount)
```

con pedidos cuyo estado sea `PAID` o `FULFILLED`.

---

## Ticket Promedio

Representa el importe promedio de los pedidos considerados ventas.

```sql
SUM(total_amount) / COUNT(*)
```

---

## Usuarios Activos

Para sesiones identificadas se utiliza el cliente.

Para sesiones anónimas se utiliza el identificador de sesión.

La lógica utilizada es:

```sql
COUNT(
    DISTINCT CASE
        WHEN customer_key <> -1
            THEN 'cliente_' || CAST(customer_key AS VARCHAR)
        ELSE
            'anonimo_' || CAST(session_id AS VARCHAR)
    END
)
```

---

## NPS

Los puntajes se clasifican de la siguiente manera:

- Promotores: 9 y 10
- Pasivos: 7 y 8
- Detractores: 0 a 6

El cálculo utilizado es:

```text
NPS = % Promotores - % Detractores
```

El Data Mart utilizado para la tendencia se encuentra agregado por mes y canal.

---

## Ventas por Provincia

Las ventas se relacionan con la dirección de envío y posteriormente con la provincia.

```sql
SUM(total_amount)
GROUP BY provincia
```

---

## Ranking mensual por Producto

Se utilizan los ítems de pedido y se agrupan las ventas por producto y mes.

```sql
SUM(line_total)
GROUP BY periodo, producto
```

---

# Supuestos

Para el desarrollo del modelo se utilizaron los siguientes supuestos:

- Los archivos de `raw/` representan los datos originales y no se modifican.
- Los montos se encuentran expresados en pesos argentinos.
- Se consideran ventas los pedidos con estado `PAID` o `FULFILLED`.
- Los pedidos `CREATED`, `CANCELLED` y `REFUNDED` no se consideran ventas.
- Las ventas por provincia se asignan utilizando la dirección de envío del pedido.
- En sesiones web, cuando no existe un cliente identificado, el usuario activo se representa mediante `session_id`.
- Las claves utilizadas por las tablas de hechos son claves subrogadas de las dimensiones.
- Se utiliza la clave `-1` para representar valores desconocidos cuando corresponde.
- Los Data Marts consumen únicamente información del modelo estrella y no acceden directamente a `raw/`.
- Para mostrar la tendencia de NPS se utiliza una agregación mensual por canal.
- Los Data Marts contienen únicamente consultas `SELECT`. La exportación a CSV se realiza mediante `run_sql.py`.

---

# Dashboard

El dashboard fue desarrollado utilizando Looker Studio y se encuentra dividido en dos páginas.

## Página 1 — Exploración de ventas

Permite analizar las ventas utilizando los siguientes filtros:

- Fecha
- Provincia
- Canal
- Producto
- Categoría

Incluye:

- Ventas por Provincia
- Ventas por Producto

---

## Página 2 — KPIs y tendencias

Incluye:

- Ventas Totales
- Ticket Promedio
- Usuarios Activos
- NPS
- Evolución de Ventas
- Ranking mensual por Producto
- Evolución de Usuarios Activos
- Tendencia de NPS

El objetivo de esta página es mostrar los principales indicadores comerciales y su evolución en el tiempo.

---

# Consultas de control

Algunas consultas utilizadas para revisar el modelo son:

### Ventas Totales

```sql
SELECT
    SUM(total_amount) AS ventas_totales
FROM fact_sales_order
WHERE is_sale = TRUE;
```

### Cantidad de pedidos

```sql
SELECT
    COUNT(*) AS cantidad_pedidos
FROM fact_sales_order
WHERE is_sale = TRUE;
```

### Ticket Promedio

```sql
SELECT
    SUM(total_amount) / COUNT(*) AS ticket_promedio
FROM fact_sales_order
WHERE is_sale = TRUE;
```

### Ventas por Provincia

```sql
SELECT
    a.province_name AS provincia,
    SUM(f.total_amount) AS ventas_totales
FROM fact_sales_order AS f
JOIN dim_address AS a
    ON a.address_key = f.shipping_address_key
WHERE f.is_sale = TRUE
GROUP BY a.province_name
ORDER BY ventas_totales DESC;
```

### Ranking de productos

```sql
SELECT
    d.anio,
    d.mes,
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
    p.name
ORDER BY
    d.anio,
    d.mes,
    ventas_producto DESC;
```

---

# Herramientas utilizadas

- Python
- DuckDB
- SQL
- Visual Studio Code
- Git
- GitHub
- Google Sheets
- Looker Studio

---

# Resultado

El proyecto permite transformar los datos originales de EcoBottle AR en un modelo analítico que puede ser reconstruido completamente ejecutando:

```bash
python run_sql.py
```

Los archivos resultantes se generan dentro de `dw/` y son utilizados posteriormente como fuente del dashboard comercial.