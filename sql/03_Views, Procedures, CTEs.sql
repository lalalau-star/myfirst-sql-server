-- Views

/*
	View virtual table with a cross join between the Products table
	and the Sales table.
	The aim was to visualize the best-selling product and its quantity
*/
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



/*
	This view aims to spot the days with more sales and 
	the top 1 product with the most sales.
	It was a complex view to create, due to use of subqueries
	& the derived tables to achieve the desired aggregation and ranking.
*/
CREATE OR ALTER VIEW vw_topDS AS
SELECT
	vpd.Fecha,
	vpd.No_Ventas,
	vpd.MontoTotal,
	rp.TopProducto,
	rp.Cant_Vendida
FROM (
	--agrupamiento por fecha
	SELECT
		CAST(v.Fecha AS DATE) AS Fecha,
		COUNT(v.ID_Venta) AS No_Ventas,
		SUM(v.Total) AS MontoTotal
	FROM Ventas v
	GROUP BY CAST(v.Fecha AS DATE)
) AS vpd
INNER JOIN (
	-- calcular qué producto se vendió más
	SELECT
		CAST(v.Fecha AS DATE) AS Fecha,
		p.Nombre AS TopProducto,
		SUM(dv.Cantidad) AS Cant_Vendida,
		ROW_NUMBER() OVER (PARTITION BY CAST(v.Fecha AS DATE) ORDER BY SUM(dv.Cantidad) DESC) AS Ranking
	FROM Ventas v
	INNER JOIN DetallesVentas dv ON v.ID_Venta = dv.ID_Venta
	INNER JOIN Productos p ON dv.ID_Producto = p.ID_Producto
	GROUP BY CAST(v.Fecha AS DATE), p.Nombre
) AS rp ON vpd.Fecha = rp.Fecha
WHERE rp.Ranking = 1;
GO

-- Query to execute the last view created
SELECT *
FROM vw_topDS
ORDER BY No_ventas DESC;



-- Procedures

/*
	Stored Procedure: sp_RegistroVentaCompleta
	Description: 
	Automates the complete sales entry process.
	Previously, manual entries into Sales & 
	Detailed Sales table caused inconsistencies
	& errors in Sales per Client view.

	This procedure receives a client ID &
	a JSON payload containing multiple products,
	executing the following core tasks safely inside a transaction:
		1. Validation: Checks if requested products exist
			(Throws error 50000 if not found) & verifies
			sufficient stock levels (Throws error 50001 if stock is exceeded).
		2. Folio Generation: Generates an automatic formatted
			ticket folio (Year-Sequence).
		3. Persistence: Inserts data into Sales & Detailed Sales.
		4. Inventory Control: Automatically updates product stock levels.
*/
CREATE OR ALTER PROCEDURE dbo.sp_RegistroVentaCompleta
	@ID_Cliente INT,
	@ProductosJSON NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;

	BEGIN TRY
		DECLARE @Year INT = YEAR(GETDATE());
		DECLARE @SigNum INT;
		DECLARE @Folio VARCHAR(20);
		DECLARE @ID_Venta_int INT;
		DECLARE @TotalVenta DECIMAL(10,2);

		CREATE TABLE #ItemsVenta (
			ID_Producto INT,
			Cantidad INT,
			PrecioVigente DECIMAL(10,2),
			Stock INT
		);

		INSERT INTO #ItemsVenta (ID_Producto, Cantidad, PrecioVigente, Stock)
		SELECT 
			j.ID_Producto,
			j.Cantidad,
			p.Precio,
			p.Stock
		FROM OPENJSON(@ProductosJSON) WITH (
			ID_Producto INT '$.ID_Producto',
			Cantidad INT '$.Cantidad'			
		) j
		INNER JOIN Productos p WITH (UPDLOCK) ON j.ID_Producto = p.ID_Producto;

		IF (SELECT COUNT (*) FROM OPENJSON(@ProductosJSON)) <> (SELECT COUNT(*) FROM #ItemsVenta)
		BEGIN
			DECLARE @ID_Invalido INT;
			SELECT TOP 1 @ID_Invalido =	j.ID_Producto
			FROM OPENJSON(@ProductosJSON) WITH (ID_Producto INT '$.ID_Producto') j
			LEFT JOIN Productos p ON j.ID_Producto = p.ID_Producto
			WHERE p.ID_Producto IS NULL;

			DECLARE @ErrorNoExiste VARCHAR(150) = CONCAT('El producto con ID [', @ID_Invalido, '] no existe en el catálogo.');
			THROW 50000, @ErrorNoExiste, 1;
		END

		IF EXISTS (SELECT 1 FROM #ItemsVenta WHERE Stock < Cantidad)
		BEGIN 
			DECLARE @ID_Agotado INT, @StockDisp INT, @CantReq INT;
			
			SELECT TOP 1 @ID_Agotado = ID_Producto, @StockDisp = Stock, @CantReq = Cantidad
			FROM #ItemsVenta
			WHERE Stock < Cantidad;

			DECLARE @ErrorStock VARCHAR(150) = CONCAT('Stock insuficiente del producto con ID [', @StockDisp, ']. Disponible: ', @StockDisp, 'Solicitado', @CantReq);
			THROW 50001, @ErrorStock, 1;
		END

		SELECT @SigNum = NEXT VALUE FOR dbo.SecuenciaFolioVentas;
		SET @Folio = CONCAT(@Year, '-', RIGHT(CONCAT('0000', @SigNum), 4));

		SELECT @TotalVenta = SUM(Cantidad * PrecioVigente) FROM #ItemsVenta;

		INSERT INTO Ventas (ID_Cliente, Fecha, Total)
		VALUES (@ID_Cliente, GETDATE(), @TotalVenta);

		SET @ID_Venta_int = SCOPE_IDENTITY();

		INSERT INTO DetallesVentas (ID_Venta, ID_Producto, Cantidad, Precio)
		SELECT @ID_Venta_int, ID_Producto, Cantidad, PrecioVigente
		FROM #ItemsVenta;

		UPDATE p
		SET p.Stock = p.Stock - iv.Cantidad
		FROM Productos p
		INNER JOIN #ItemsVenta iv ON p.ID_Producto = iv.ID_Producto;

		COMMIT TRANSACTION;

		SELECT @Folio AS FolioGen;
		SELECT 'Venta realizada con éxito' AS Mensaje, @ID_Venta_int AS ID_Venta;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH;
END;
GO


-- Execution of the procedure RegistroVentaCompleta
EXEC dbo.sp_RegistroVentaCompleta
	@ID_Cliente = 3,
	@ProductosJSON = '[
		{"ID_Producto": 5, "Cantidad": 1},
		{"ID_Producto": 1, "Cantidad": 1},
		{"ID_Producto": 23, "Cantidad": 1},
		{"ID_Producto": 15, "Cantidad": 1}
	]'
GO



/*
	Thhis procedure manages the restocking of one or
	more products by extracting data directly
	from a JSON input to update table inventory levels,
	allowing the execution of multiple atomic operations
	safely wthin a transaction.
*/
CREATE OR ALTER PROCEDURE dbo.sp_ReabastecerStock
	@ReabJSON NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;

	BEGIN TRY

		-- Tabla temporal para recibir datos JSON
		CREATE TABLE #ItemsReab (
			ID_Producto INT,
			CantSum INT
		);

		INSERT INTO #ItemsReab (ID_Producto, CantSum)
		SELECT 
			j.ID_Producto,
			j.CantSum
		FROM OPENJSON(@ReabJSON) WITH (
		ID_Producto INT '$.ID_Producto',
			CantSum INT '$.Cant'
		) j;
		
		-- Validar que el producto existe en el catálogo
		IF EXISTS (
			SELECT 1
			FROM #ItemsReab ir
			LEFT JOIN Productos p ON ir.ID_Producto = p.ID_Producto
			WHERE p.ID_Producto IS NULL
		)
		BEGIN
			DECLARE @ID_Inv INT;

			-- Se captura el primer ID que no exista para reportarlo
			SELECT TOP 1 @ID_Inv = ir.ID_Producto
			FROM #ItemsReab ir
			LEFT JOIN Productos p ON ir.ID_Producto = p.ID_Producto
			WHERE p.ID_Producto IS NULL;

			DECLARE @ErrorMsg VARCHAR(150) = CONCAT('El producto con ID [', @ID_Inv,'] no existe en el catálogo.');
			THROW 50000, @ErrorMsg, 1;
		END

		-- Si todos los productos del ejecutable existen, actualiza el stock
		UPDATE p
		SET p.Stock = p.Stock + ir.CantSum
		FROM Productos p
		INNER JOIN #ItemsReab ir ON p.ID_Producto = ir.ID_Producto;

		COMMIT TRANSACTION;
		SELECT 'Stock actualizado exitosamente para todos los productos de la lista.' AS Mensaje;

	END TRY
	BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH;
END;
GO


-- Execution of the procedure to restock products
EXEC dbo.sp_ReabastecerStock
	@ReabJSON = '[
		{"ID_Producto": 2, "Cant": 1},
		{"ID_Producto": 4, "Cant": 4}
	]';
GO


-- Common Table Expresions (CTE)

/*
*/
CREATE TABLE Categorías (
	ID INT,
	Nombre NVARCHAR(100),
	ID_Padre INT NULL -- Ref a la categoría padre
);
GO


INSERT INTO Categorías(ID, Nombre, ID_Padre) VALUES
(1, 'Electrónica y Audio', NULL),
(2, 'Cómputo y Accesorios', NULL),
(3, 'Hogar e Iluminación', NULL),
(4, 'Energía y Carga', NULL),
(5, 'Otros / Varios', NULL),
-- Subcategorías (dependientes de las principales)
(6, 'Audífonos', 1),
(7, 'Cámaras y Video', 1),
(8, 'Proyectores', 1),
(9, 'Periféricos (Mouse y Teclados)', 2),
(10, 'Protección y Fundas', 2),
(11, 'Cables y Adaptadores', 2),
(12, 'Monitores y Consolas', 2),
(13, 'Soportes y Bases', 2),
(14, 'Iluminación', 3),
(15, 'Mochilas', 3),
(16, 'Pilas y Baterías', 4),
(17, 'Cargadores y Multiconectores', 4),
(18, 'Extensiones', 4),
(19, 'Smart Home / Foco inteligente', 3);
GO

/*
	Creation of a recursive CTE to assign hierarchical
	levels to product categories based on
	their parent-child relationship
*/
WITH CatJerarquica AS (
	-- PARTE 1. ANCLA. SELECCIONA LAS CATEGORÍAS RAÍZ SIN CATEGORÍA PADRE
	SELECT ID, Nombre, ID_Padre, 1 AS Nivel
	FROM Categorías
	WHERE ID_Padre IS NULL

	UNION ALL

	--PARTE 2. RECURSIVIDAD. SLÑECCIONA LAS SUBCATEGORIAS DE LAS CATEGORIAS ACTUALES
	SELECT c.ID, c.Nombre, c.ID_Padre, cj.Nivel + 1
	FROM Categorías c
	JOIN CatJerarquica cj ON c.ID_Padre = cj.ID
)
--parte 3. final. muestra todas las categorías con sus niveles
SELECT ID, Nombre, ID_Padre, Nivel
FROM CatJerarquica
ORDER BY Nivel, ID;
GO