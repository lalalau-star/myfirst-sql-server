```sql
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
```
