```sql
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
```
