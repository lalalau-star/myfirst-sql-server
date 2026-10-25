# SQL Query Examples

This document showcases selected SQL queries developed for the Point of Sale (POS) database project using Microsoft SQL Server.

The examples demonstrate data retrieval, table relationships, aggregation, and inventory analysis.

## 1. Retrieve Sales with Customer Information

**Business question:** Which customers made each sale, and when did the transactions occur?

**SQL concepts:** `INNER JOIN`, column selection, `ORDER BY`.

```sql
SELECT
    v.ID_Venta,
    c.Nombre AS CustomerName,
    v.Fecha AS SaleDate,
    v.Total
FROM dbo.Ventas AS v
INNER JOIN dbo.Clientes AS c
    ON v.ID_Cliente = c.ID_Cliente
ORDER BY v.Fecha DESC;
```

**Expected output:** A result set containing the sale ID, customer name, transaction date, and sale total for each matching record.

**Business value:** Connects transaction records with customer information, making sales activity easier to review.

## 2. Identify Best-Selling Products

**Business question:** Which products have the highest sales volume?

**SQL concepts:** `INNER JOIN`, `SUM`, `GROUP BY`, `ORDER BY`.

```sql
SELECT TOP 10
    p.ID_Producto,
    p.Nombre AS ProductName,
    SUM(dv.Cantidad) AS UnitsSold
FROM dbo.DetallesVentas AS dv
INNER JOIN dbo.Productos AS p
    ON dv.ID_Producto = p.ID_Producto
GROUP BY
    p.ID_Producto,
    p.Nombre
ORDER BY UnitsSold DESC;
```

**Expected output:** Up to 10 products ranked by total units sold.

**Business value:** Helps identify products with higher sales volume and supports inventory planning.

## 3. Identify Products with Low Stock

**Business question:** Which products may require inventory replenishment?

**SQL concepts:** `WHERE`, comparison operators, `ORDER BY`.

```sql
SELECT
    ID_Producto,
    Nombre AS ProductName,
    Stock
FROM dbo.Productos
WHERE Stock <= 10
ORDER BY Stock ASC;
```

**Expected output:** Products with 10 or fewer units in stock, provided the threshold is appropriate for the business.

**Business value:** Helps monitor inventory levels and identify products that may need replenishment.

*Note: The threshold of 10 units is illustrative and can be adjusted to the business requirements.*

## 4. Calculate Sales Revenue by Month

**Business question:** How does recorded sales revenue vary by month?

**SQL concepts:** `SUM`, `GROUP BY`, date functions.

```sql
SELECT
    YEAR(Fecha) AS SaleYear,
    MONTH(Fecha) AS SaleMonth,
    SUM(Total) AS TotalRevenue
FROM dbo.Ventas
GROUP BY
    YEAR(Fecha),
    MONTH(Fecha)
ORDER BY
    SaleYear,
    SaleMonth;
```

**Expected output:** One row per year and month represented in the sales table, with the sum of the recorded sale totals.

**Business value:** Provides a basic monthly sales summary that can support trend analysis.

## 5. Database Automation

This project also applies SQL Server database objects such as views, stored procedures, and triggers.

Add a representative example here once the corresponding object has been verified in the project scripts.

**SQL concepts:** Views, stored procedures, and triggers.

**Business value:** Supports query reuse and the implementation of database operations or automated rules, depending on the object's actual behavior.

---

## Notes

- All examples should be executed against the project database.
- Query results depend on the records available in the database.
- Inventory thresholds and business interpretations should be adapted to the actual requirements.
