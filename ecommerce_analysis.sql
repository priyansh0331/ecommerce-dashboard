-- ============================================================
-- ecommerce_analysis.sql
-- Key analytical queries for the E-Commerce Sales Dashboard
-- Run these against ecommerce_sales_clean.csv loaded into
-- any SQL engine (SQLite, MySQL, PostgreSQL, etc.)
-- ============================================================


-- ── 1. Monthly Revenue ────────────────────────────────────────────────────────
-- Total revenue and order count per month, ordered chronologically

SELECT
    month,
    month_name,
    COUNT(DISTINCT order_id)    AS total_orders,
    SUM(qty)                    AS total_units_sold,
    ROUND(SUM(amount), 2)       AS total_revenue,
    ROUND(AVG(amount), 2)       AS avg_order_value
FROM ecommerce_sales
WHERE status_simple NOT IN ('Cancelled', 'Returned')
GROUP BY month, month_name
ORDER BY month;


-- ── 2. Top 5 Best-Selling Categories ─────────────────────────────────────────

SELECT
    category,
    COUNT(DISTINCT order_id)    AS total_orders,
    SUM(qty)                    AS units_sold,
    ROUND(SUM(amount), 2)       AS revenue,
    ROUND(SUM(amount) * 100.0 /
        SUM(SUM(amount)) OVER(), 2) AS revenue_pct
FROM ecommerce_sales
WHERE status_simple NOT IN ('Cancelled', 'Returned')
GROUP BY category
ORDER BY revenue DESC
LIMIT 5;


-- ── 3. Revenue by State (Regional Performance) ───────────────────────────────

SELECT
    ship_state,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(SUM(amount), 2)       AS total_revenue
FROM ecommerce_sales
WHERE status_simple NOT IN ('Cancelled', 'Returned')
  AND ship_state IS NOT NULL
GROUP BY ship_state
ORDER BY total_revenue DESC
LIMIT 15;


-- ── 4. Order Status Breakdown ─────────────────────────────────────────────────

SELECT
    status_simple,
    COUNT(*)                    AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM ecommerce_sales
GROUP BY status_simple
ORDER BY order_count DESC;


-- ── 5. B2B vs B2C Comparison ─────────────────────────────────────────────────

SELECT
    customer_type,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(SUM(amount), 2)       AS total_revenue,
    ROUND(AVG(amount), 2)       AS avg_order_value
FROM ecommerce_sales
WHERE status_simple NOT IN ('Cancelled', 'Returned')
GROUP BY customer_type;


-- ── 6. Sales Channel Performance ─────────────────────────────────────────────

SELECT
    sales_channel,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(SUM(amount), 2)       AS total_revenue
FROM ecommerce_sales
WHERE status_simple NOT IN ('Cancelled', 'Returned')
GROUP BY sales_channel
ORDER BY total_revenue DESC;


-- ── 7. Weekly Sales Trend ─────────────────────────────────────────────────────

SELECT
    week,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(SUM(amount), 2)       AS weekly_revenue
FROM ecommerce_sales
WHERE status_simple NOT IN ('Cancelled', 'Returned')
GROUP BY week
ORDER BY week;


-- ── 8. Cancellation Rate by Category ─────────────────────────────────────────

SELECT
    category,
    COUNT(*)                                                AS total_orders,
    SUM(CASE WHEN status_simple = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(
        SUM(CASE WHEN status_simple = 'Cancelled' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                       AS cancellation_rate_pct
FROM ecommerce_sales
GROUP BY category
ORDER BY cancellation_rate_pct DESC;
