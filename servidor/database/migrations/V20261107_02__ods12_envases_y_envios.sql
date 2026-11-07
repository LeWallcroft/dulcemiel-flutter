/*
   ODS 12: opciones de envase, recargas en frasco propio y comprobantes de envío.
   Migración aditiva: conserva productos, carritos, pedidos y detalles existentes.
*/
IF OBJECT_ID(N'dbo.opciones_envase_producto', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.opciones_envase_producto (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    producto_id INT NOT NULL,
    codigo NVARCHAR(24) NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(400) NOT NULL,
    costo_extra DECIMAL(10,2) NOT NULL CONSTRAINT DF_opcion_envase_costo DEFAULT 0,
    activo BIT NOT NULL CONSTRAINT DF_opcion_envase_activo DEFAULT 1,
    CONSTRAINT FK_opcion_envase_producto FOREIGN KEY (producto_id) REFERENCES dbo.productos(id) ON DELETE CASCADE,
    CONSTRAINT UQ_opcion_envase_producto_codigo UNIQUE (producto_id, codigo),
    CONSTRAINT CK_opcion_envase_codigo CHECK (codigo IN (N'convencional', N'vidrio_dulcemiel', N'frasco_cliente')),
    CONSTRAINT CK_opcion_envase_costo CHECK (costo_extra >= 0)
  );
END;
GO

IF COL_LENGTH(N'dbo.productos', N'informacion_ods12') IS NULL
  ALTER TABLE dbo.productos ADD informacion_ods12 NVARCHAR(700) NULL;
IF COL_LENGTH(N'dbo.productos', N'meta_ods12') IS NULL
  ALTER TABLE dbo.productos ADD meta_ods12 NVARCHAR(10) NULL;
IF COL_LENGTH(N'dbo.configuracion_sitio', N'direccion_envases') IS NULL
  ALTER TABLE dbo.configuracion_sitio ADD direccion_envases NVARCHAR(300) NULL;
IF COL_LENGTH(N'dbo.configuracion_sitio', N'receptor_envases') IS NULL
  ALTER TABLE dbo.configuracion_sitio ADD receptor_envases NVARCHAR(120) NULL;
IF COL_LENGTH(N'dbo.configuracion_sitio', N'telefono_envases') IS NULL
  ALTER TABLE dbo.configuracion_sitio ADD telefono_envases NVARCHAR(30) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_productos_meta_ods12')
  ALTER TABLE dbo.productos ADD CONSTRAINT CK_productos_meta_ods12 CHECK (meta_ods12 IS NULL OR meta_ods12 IN (N'12.5', N'12.8'));
GO

INSERT INTO dbo.opciones_envase_producto (producto_id, codigo, nombre, descripcion, costo_extra, activo)
SELECT p.id, N'convencional', N'Envase convencional', N'Presentación convencional del producto.', 0, 1
FROM dbo.productos p
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.opciones_envase_producto o
  WHERE o.producto_id = p.id AND o.codigo = N'convencional'
);
GO

IF COL_LENGTH(N'dbo.carrito', N'opcion_envase_id') IS NULL
  ALTER TABLE dbo.carrito ADD opcion_envase_id INT NULL;
IF COL_LENGTH(N'dbo.carrito', N'costo_envase_unitario') IS NULL
  ALTER TABLE dbo.carrito ADD costo_envase_unitario DECIMAL(10,2) NOT NULL CONSTRAINT DF_carrito_costo_envase DEFAULT 0;
GO

UPDATE c
SET c.opcion_envase_id = o.id,
    c.costo_envase_unitario = o.costo_extra
FROM dbo.carrito c
JOIN dbo.opciones_envase_producto o ON o.producto_id = c.producto_id AND o.codigo = N'convencional'
WHERE c.opcion_envase_id IS NULL;
GO

IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_carrito_usuario_producto')
  ALTER TABLE dbo.carrito DROP CONSTRAINT UQ_carrito_usuario_producto;
IF EXISTS (SELECT 1 FROM dbo.carrito WHERE opcion_envase_id IS NULL)
  THROW 51001, 'No se pudo asignar un envase convencional a todas las líneas del carrito.', 1;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.carrito') AND name = N'opcion_envase_id' AND is_nullable = 1)
  ALTER TABLE dbo.carrito ALTER COLUMN opcion_envase_id INT NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_carrito_opcion_envase')
  ALTER TABLE dbo.carrito ADD CONSTRAINT FK_carrito_opcion_envase FOREIGN KEY (opcion_envase_id) REFERENCES dbo.opciones_envase_producto(id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.carrito') AND name = N'UX_carrito_usuario_producto_envase')
  CREATE UNIQUE INDEX UX_carrito_usuario_producto_envase ON dbo.carrito(usuario_id, producto_id, opcion_envase_id);
GO

IF COL_LENGTH(N'dbo.detalles_pedido', N'envase_codigo') IS NULL
  ALTER TABLE dbo.detalles_pedido ADD envase_codigo NVARCHAR(24) NOT NULL CONSTRAINT DF_detalle_envase_codigo DEFAULT N'convencional';
IF COL_LENGTH(N'dbo.detalles_pedido', N'envase_nombre') IS NULL
  ALTER TABLE dbo.detalles_pedido ADD envase_nombre NVARCHAR(100) NOT NULL CONSTRAINT DF_detalle_envase_nombre DEFAULT N'Envase convencional';
IF COL_LENGTH(N'dbo.detalles_pedido', N'envase_descripcion') IS NULL
  ALTER TABLE dbo.detalles_pedido ADD envase_descripcion NVARCHAR(400) NOT NULL CONSTRAINT DF_detalle_envase_descripcion DEFAULT N'Presentación convencional del producto.';
IF COL_LENGTH(N'dbo.detalles_pedido', N'costo_envase_unitario') IS NULL
  ALTER TABLE dbo.detalles_pedido ADD costo_envase_unitario DECIMAL(10,2) NOT NULL CONSTRAINT DF_detalle_envase_precio DEFAULT 0;
GO

IF COL_LENGTH(N'dbo.pedidos', N'tiene_envase_cliente') IS NULL
  ALTER TABLE dbo.pedidos ADD tiene_envase_cliente BIT NOT NULL CONSTRAINT DF_pedido_envase_cliente DEFAULT 0;
IF COL_LENGTH(N'dbo.pedidos', N'cantidad_envases_cliente') IS NULL
  ALTER TABLE dbo.pedidos ADD cantidad_envases_cliente INT NOT NULL CONSTRAINT DF_pedido_cantidad_envases DEFAULT 0;
IF COL_LENGTH(N'dbo.pedidos', N'envase_envio_agencia') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_envio_agencia NVARCHAR(120) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_envio_guia') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_envio_guia NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_envio_costo') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_envio_costo DECIMAL(10,2) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_envio_boleta_key') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_envio_boleta_key NVARCHAR(512) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_recibido_fecha') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_recibido_fecha DATETIME2(0) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_destino') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_destino NVARCHAR(300) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_receptor') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_receptor NVARCHAR(120) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envase_telefono') IS NULL
  ALTER TABLE dbo.pedidos ADD envase_telefono NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envio_pedido_agencia') IS NULL
  ALTER TABLE dbo.pedidos ADD envio_pedido_agencia NVARCHAR(120) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envio_pedido_guia') IS NULL
  ALTER TABLE dbo.pedidos ADD envio_pedido_guia NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envio_pedido_costo') IS NULL
  ALTER TABLE dbo.pedidos ADD envio_pedido_costo DECIMAL(10,2) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'envio_pedido_boleta_key') IS NULL
  ALTER TABLE dbo.pedidos ADD envio_pedido_boleta_key NVARCHAR(512) NULL;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_pedidos_estado')
  ALTER TABLE dbo.pedidos DROP CONSTRAINT CK_pedidos_estado;
ALTER TABLE dbo.pedidos ADD CONSTRAINT CK_pedidos_estado CHECK (
  estado IN (N'pendiente', N'esperando_envase', N'procesando', N'enviado', N'entregado', N'cancelado')
);
GO
