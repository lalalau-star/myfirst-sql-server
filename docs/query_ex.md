# SQL Query Examples

This document showcases selected SQL queries developed for the Point of Sale (POS) database project using Microsoft SQL Server.

The examples demonstrate data retrieval, table relationships, aggregation, and inventory analysis.

## 1. Retrieve Sales with Customer Information

**Business question:** Which customers need an incentive to buy more?

**SQL concepts:** `INNER JOIN`, column selection, `ORDER BY`.

```sql
SELECT
	c.ID_Cliente,
	c.Nombre,
	c.Email,
	CAST(AVG(v.Total) AS DECIMAL (10, 2)) AS TicketPromedio
FROM Clientes c
INNER JOIN Ventas v 
	ON c.ID_Cliente = v.ID_Cliente
GROUP BY
	c.ID_Cliente,
	c.Nombre,
	c.Email
ORDER BY TicketPromedio ASC;
GO
```

**Expected output:** Scalar query order by average ticket price per client in ascending order. ![Ex.1: Retrieve Sales with Customer Info](https://github.com/lalalau-star/myfirst-sql-server/blob/main/docs/query_ex_imgs/Ex1_%20RetrieveSalesWCustomerInfo.png)

**Business value:** Connects transaction records with customer information, making sales activity easier to review.

## 2. Identify Best-Selling Products

**Business question:** Which products have the highest sales volume?

**SQL concepts:** `INNER JOIN`, `SUM`, `GROUP BY`, `ORDER BY`.

```sql
CREATE OR ALTER VIEW VentasProducto AS 
	SELECT
		p.ID_Producto,
		p.Nombre AS Nom_Producto,
		SUM(dv.Cantidad) AS CantVendida
	FROM Productos p
	INNER JOIN DetallesVentas dv
		ON p.ID_Producto = dv.ID_Producto
	GROUP BY p.ID_Producto, p.Nombre;
GO

-- Query to execute the last view created
SELECT *
FROM VentasProducto
ORDER BY CantVendida DESC;
```

**Expected output:** View virtual table with a cross join between the Products table & the Sales table. ![Ex.2: Best-Selling Products](https://github.com/lalalau-star/myfirst-sql-server/blob/main/docs/query_ex_imgs/Ex2_Best-SellingProducts.png)

**Business value:** Helps identify products with higher sales volume and supports inventory planning.

## 3. Target Premium Products for Marketing

**Business question:** Which high-priced products may require sponsorship?

**SQL concepts:** `WHERE`, comparison operators, `ORDER BY`.

```sql
SELECT
	p.Nombre,
	p.Precio,
	(SELECT ISNULL(SUM(dv.Cantidad), 0)
	FROM DetallesVentas dv
	WHERE dv.ID_Producto = p.ID_Producto) AS CantidadVendida
FROM Productos p
WHERE p.Precio > (SELECT AVG(Precio) FROM Productos);
GO
```

**Expected output:** Products with prices above the average and their sales quantity ![Ex.3: Target Premium Products](https://github.com/lalalau-star/myfirst-sql-server/blob/main/docs/query_ex_imgs/Ex3_TargetPremiumProducts.png)

**Business value:** Maximized profit margins, freed-up capital (moving slow-turnover stock), enhanced brand positioning and Prestige, attracting high-value customers (LTV) & psychological anchoring and upselling.

## 4. Database Automation. Complete Sales Transaction

**Business question:** How can we automate the sales entry process to prevent inconsistencies and manage inventory atomically?

**SQL concepts:** Stored Procedures, Transactions (BEGIN TRANSACTION, COMMIT, ROLLBACK), Error Handling (TRY, CATCH, THROW), JSON Processing (OPENJSON), Temporary Tables, Sequences.

 [Ex.4: DA_Complete Sales Transaction](https://github.com/lalalau-star/myfirst-sql-server/blob/main/docs/query_ex_imgs/Ex.4%3A%20DA_CompleteSalesTransaction.md)
 
**Expected output:** Generated transaction folio, confirmation message, and sale ID. 

**Business value:** Eliminates manual data entry errors, ensures real-time inventory synchronization, enforces strict business validations (stock/existence), and generates automated sequential folios safely within transactions.

## 5. Database Automation. Product Restocking via JSON

**Business question:** How can we efficiently manage and update inventory levels for multiple products in bulk?

**SQL concepts:** Stored Procedures, Transactions, JSON Processing (OPENJSON), Temporary Tables, Error Handling (TRY, CATCH, THROW)

[Ex.5: DA_Product Restock](https://github.com/lalalau-star/myfirst-sql-server/blob/main/docs/query_ex_imgs/Ex.5%3A%20DA_ProductRestock.md)

**Expected output:** Confirmation message indicating successful stock update.

**Business value:** Streamlines bulk inventory replenishment, guarantees atomicity and safety during stock updates, and prevents errors by validating product existence before modifying records.

---

## Notes

This project was developed for educational purposes.
