/* Coordenadas opcionales elegidas en el mapa para pedidos existentes y nuevos. */
IF COL_LENGTH(N'dbo.pedidos', N'direccion_entrega_lat') IS NULL
  ALTER TABLE dbo.pedidos ADD direccion_entrega_lat DECIMAL(10,7) NULL;
IF COL_LENGTH(N'dbo.pedidos', N'direccion_entrega_lng') IS NULL
  ALTER TABLE dbo.pedidos ADD direccion_entrega_lng DECIMAL(10,7) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_pedidos_ubicacion_entrega')
BEGIN
  ALTER TABLE dbo.pedidos ADD CONSTRAINT CK_pedidos_ubicacion_entrega CHECK (
    (direccion_entrega_lat IS NULL AND direccion_entrega_lng IS NULL)
    OR (direccion_entrega_lat IS NOT NULL AND direccion_entrega_lng IS NOT NULL
        AND direccion_entrega_lat BETWEEN -90 AND 90 AND direccion_entrega_lng BETWEEN -180 AND 180)
  );
END;
GO
