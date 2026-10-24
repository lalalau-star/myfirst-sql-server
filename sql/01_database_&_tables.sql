-- Database creation, tables & views

CREATE DATABASE PROY_POS;

/*
	In the next 4 code blocks, I created the Products Table, 
	Clients Table, Sales Table, & a Detailed Sales Table. 
	In those tables, I specified the primary key identities &
	foreign keys, as well as the tables' variables restrictions.
*/

--Products table
CREATE TABLE Productos ( 
	ID_Producto INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Nombre VARCHAR(50) NOT NULL,
	Descripción VARCHAR(100),
	Precio DECIMAL(10,2) NOT NULL,
	Stock INT NOT NULL
 );

 GO

 -- Clients table
 CREATE TABLE Clientes (
	ID_Cliente INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Nombre VARCHAR(50) NOT NULL,
	Dirección VARCHAR(50) NOT NULL,
	Teléfono VARCHAR(10) NOT NULL,
	Email VARCHAR(50),
 );

 GO

 --Sales table
 CREATE TABLE Ventad (
	ID_Venta INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	ID_Cliente INT NOT NULL,
	Fecha DATETIME NOT NULL,
	Total DECIMAL(10,2) NOT NULL,
	FOREIGN KEY (ID_Cliente) REFERENCES Clientes(ID_Cliente)
 );

 GO

 --Detailed Sales table
CREATE TABLE DetallesVentas (
	ID_Detalle INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	ID_Venta INT NOT NULL,
	ID_Producto INT NOT NULL,
	Cantidad INT NOT NULL,
	Precio DECIMAL(10,2) NOT NULL,
 );
GO

/*
	I had a misspelling in the table name,
	so I executed a table rename.
*/
EXEC sp_rename Ventad, Ventas;
GO

/*
	In the next 2 code blocks, foreign keys were added to the 
	Detailed Sales table to link the ID_Product & ID_Sales columns
	with its primary key on the Products table.
*/
ALTER TABLE DetallesVentas
ADD CONSTRAINT FK_DetalleProducto
FOREIGN KEY (ID_Producto) REFERENCES Productos (ID_Producto);
GO


ALTER TABLE DetallesVentas
ADD CONSTRAINT FK_DetalleVenta
FOREIGN KEY (ID_Venta) REFERENCES Ventas (ID_Venta);
GO 

/*
	Clients table was altered to add a new column
	called City with its restrictions.
*/
ALTER TABLE Clientes
ADD Ciudad VARCHAR (50);
GO

/*
	A view was created using the JOIN clause to rescue
	sales per client and order by product while 
	maintaining the historic cost of the ticket.
*/

CREATE OR ALTER VIEW VistaVentasXCliente
AS
SELECT
	c.Nombre AS NombreCliente,
	p.Nombre AS NombreProducto,
	SUM (d.Cantidad) AS TotalCantidad,
	SUM(d.Precio * d.Cantidad) AS TotalVentas
FROM 
	Ventas v
	INNER JOIN Clientes c ON v.ID_Cliente = c.ID_Cliente
	INNER JOIN DetallesVentas d ON d.ID_Venta = v.ID_Venta
	INNER JOIN Productos p ON d.ID_Producto = p.ID_Producto
GROUP BY
	c.Nombre,
	p.Nombre;
GO

SELECT * FROM VistaVentasXCliente;