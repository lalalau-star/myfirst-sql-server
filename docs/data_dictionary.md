# Data Dictionary

## 1. Clientes (Customers)

**Purpose:** Stores detailed information for each customer.

| Column | Description |
| --- | --- |
| ID_Cliente | Unique identifier for each customer. |
| Nombre | Customer's name. |
| Dirección | Customer's physical address. |
| Teléfono | Customer's contact phone number. |
| Email | Customer's email address. |
| Ciudad | City where the customer resides. |

## 2. Ventas (Sales)

**Purpose:** Records each general sales transaction.

| Column | Description |
| --- | --- |
| ID_Venta | Unique identifier for each sale. |
| ID_Cliente | Identifies the customer associated with the sale. |
| Fecha | Date and time when the transaction took place. |
| Total | Accumulated total amount of the sale. |

## 3. Productos (Products)

**Purpose:** Stores product information, inventory levels, and category assignments.

| Column | Description |
| --- | --- |
| ID_Producto | Unique identifier for each product. |
| Nombre | Product name. |
| Descripción | Detailed description of the product. |
| Precio | Current selling price of the product. |
| Stock | Available inventory quantity. |
| ID_Categoria | Identifies the category to which the product belongs. |

## 4. DetallesVentas (Sale Details)

**Purpose:** Records the specific products, quantities, and agreed prices included in each sale.

| Column | Description |
| --- | --- |
| ID_Detalle | Unique identifier for each sale detail record. |
| ID_Venta | Identifies the sale associated with this detail. |
| ID_Producto | Identifies the product sold. |
| Cantidad | Number of units sold. |
| Precio | Unit price of the product recorded at the time of the transaction. |

## 5. Categorías (Categories)

**Purpose:** Stores product categories and subcategories to structure them hierarchically.

| Column | Description |
| --- | --- |
| ID | Unique identifier for each category. |
| Nombre | Name of the category. |
| ID_Padre | Identifies the superior category (parent) to allow multiple levels of hierarchy. |
