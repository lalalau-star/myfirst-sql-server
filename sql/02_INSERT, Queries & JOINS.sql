-- Instances for the Products table:
INSERT INTO Productos (Nombre, Descripción, Precio, Stock) VALUES
	('Audífonos', 'Bluetooth 4ta gen', 2300.00, 20),
	('Cámara', 'Hasta 68mpx y aprueba de agua por 15mts', 18000.00, 5),
	('Proyector digital', 'Proyector portátil', 5000.00, 8),
	('Pen Stylus', 'Gen 8, carga rápida', 2000.00, 15),
	('Funda para móvil rosa','Compatible con xx y ***', 250.00, 10),
	('Mica gorilla glass','Compatible con **', 180.00, 6),
	('Mouse Ergonómico','Wireless de pila recargable', 651.50, 7),
	('Teclado', 'Wireless, dos baterías AA', 850.00, 15),
	('Adaptador USB', 'USB-A a USB-C', 126.30, 11),
	('Lámpara', 'De escritorio y luz LED fría', 650.00, 20),
	('Cable HDMI', '2 mts',874.90, 2);
GO

-- Instances for the Clients table:
INSERT INTO Clientes (Nombre, Dirección, Teléfono, Email, Ciudad) VALUES
	('Wakis', 'Cañadas del Real 10', '4443039303', 'wakis.bella@sample.com', 'SLP'),
	('Chiki', 'Cañadas del Real 10', '4449879080', 'chikens@sample.com', 'SLP'),
	('Chini', 'Cañadas del Real 10', '4442428584', 'McQuina@sample.com', 'SLP'),
	('Cloch', 'C.35 119', '9967969258', 'cloemia@sample.com', 'Cd.del Carmen'),
	('Makita', 'C.35 119', '9995255865', 'makitagoof@sample.com', 'Mérida'),
	('Alvarito', 'Cañadas del Real 10', '4444845962', 'papaitoalvarito@sample.com', 'SLP'),
	('Maki', 'Amatista 669', '4445426985', 'makiaveloso@sample.com', 'SLP'),
	('Sarah Lee', 'Av. Cahpultepec 1250', '4448536718', 'sarahleeturtle@sample.com', 'SLP'),
	('Lee', 'Amatista 669', '4446142690', 'leecuackcuak@sample.com', 'SLP'),
	('Ga', 'Amatista 669', '4440236034', 'GadiegaGa@dample.com', 'SLP'),
	('Jazzi-San', 'C.35 119 int.9', '9998150509', 'jazzi_san@samble.com', 'Mérida'),
	('Maxi', 'C.35 119 int.9', '9990995879', 'maximiliano_de_MID@samble.com', 'Mérida'),
	('Zelda', 'C.35 119 int.9', '9999754525', 'z_miau@samble.com', 'Mérida'),
	('Minuet', 'C.35 119 int.9', '9994893208', 'minuelta@samble.com', 'Mérida');
GO

-- Instances for the Sales table:
INSERT INTO Ventas (ID_Cliente, Fecha, Total) VALUES
	(22, '2026-10-08', 2300.00),
	(25, '2026-10-01', 2250.00),
	(18, '2026-10-05', 650.00),
	(1, '2026-10-18', 2000.00),
	(27, '2026-10-10', 1501.50),
	(1, '2026-10-02', 5000.00),
	(26, '2026-10-13', 874.90),
	(19, '2026-10-11', 976.30),
	(23, '2026-10-01', 1800.00),
	(24, '2026-10-01', 2300.00),
	(27, '2026-10-03', 2900.00),
	(22, '2026-10-05', 2000.00),
	(21, '2026-10-04', 650.00),
	(20, '2026-10-06', 650.00),
	(18, '2026-10-12', 5000.00),
	(19, '2026-10-10', 1800.00);
GO

-- Instances for the Detailed Sales table:
INSERT INTO DetallesVentas(ID_Venta, ID_Producto, Cantidad, Precio) VALUES
	(3, 1, 1, 2300.00),
	(4, 4, 1, 2000.00),
	(4, 5, 1, 250.00),
	(18, 2, 1, 18000.00),
	(6, 4, 1, 2000.00),
	(7, 8,1, 651.50),
	(7, 7, 1, 850.00),
	(8, 3, 1, 5000.00),
	(9, 11, 1, 874.90),
	(10, 10, 1, 126.30),
	(10, 9, 1, 650.00),
	(11, 5, 2, 250.00),
	(11, 10, 2, 1300.00),
	(12, 1, 1, 2300.00),
	(13, 5, 1, 2000.00),
	(13, 4, 1, 250.00),
	(13, 10, 1, 650.00),
	(14, 5, 1, 2000.00),
	(15, 10, 1, 650.00),
	(16, 10, 1, 650.00),
	(17, 2, 1, 5000.00),
	(5, 11, 2, 874.90),
	(5, 9, 1, 126.30);
GO


-- Queries & JOINS


/*
	Escalar query order by average ticket price
	per client in ascending order.
	This may be helpful to find which customers 
	need an incentive to buy more
*/
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

/*
	Search query to find products with 
	a price above the average & the quantity that has been sold.
*/
SELECT
	p.Nombre,
	p.Precio,
	(SELECT ISNULL(SUM(dv.Cantidad), 0)
	FROM DetallesVentas dv
	WHERE dv.ID_Producto = p.ID_Producto) AS CantidadVendida
FROM Productos p
WHERE p.Precio > (SELECT AVG(Precio) FROM Productos);
GO