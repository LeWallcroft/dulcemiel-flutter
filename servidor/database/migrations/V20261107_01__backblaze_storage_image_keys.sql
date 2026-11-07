-- Migracion aditiva: Backblaze B2 almacena archivos; SQL conserva las rutas de objetos.
-- Compatible con bases existentes y segura de volver a ejecutar.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.configuracion_sitio', N'U') IS NULL
    THROW 51100, 'No existe dbo.configuracion_sitio.', 1;
IF OBJECT_ID(N'dbo.productos', N'U') IS NULL
    THROW 51101, 'No existe dbo.productos.', 1;
IF OBJECT_ID(N'dbo.carrusel_inicio', N'U') IS NULL
    THROW 51102, 'No existe dbo.carrusel_inicio.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.configuracion_sitio', N'logo_url') IS NULL
        ALTER TABLE dbo.configuracion_sitio ADD logo_url NVARCHAR(2048) NULL;
    IF COL_LENGTH(N'dbo.configuracion_sitio', N'logo_storage_key') IS NULL
        ALTER TABLE dbo.configuracion_sitio ADD logo_storage_key NVARCHAR(512) NULL;
    IF COL_LENGTH(N'dbo.productos', N'imagen_url') IS NULL
        ALTER TABLE dbo.productos ADD imagen_url NVARCHAR(2048) NULL;
    IF COL_LENGTH(N'dbo.productos', N'imagen_storage_key') IS NULL
        ALTER TABLE dbo.productos ADD imagen_storage_key NVARCHAR(512) NULL;
    IF COL_LENGTH(N'dbo.carrusel_inicio', N'imagen_url') IS NULL
        ALTER TABLE dbo.carrusel_inicio ADD imagen_url NVARCHAR(2048) NULL;
    IF COL_LENGTH(N'dbo.carrusel_inicio', N'imagen_storage_key') IS NULL
        ALTER TABLE dbo.carrusel_inicio ADD imagen_storage_key NVARCHAR(512) NULL;

    -- Los datos binarios históricos permanecen disponibles como respaldo.
    ALTER TABLE dbo.carrusel_inicio ALTER COLUMN imagen_data VARBINARY(MAX) NULL;
    ALTER TABLE dbo.carrusel_inicio ALTER COLUMN imagen_mime NVARCHAR(80) NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT DB_NAME() AS base_de_datos,
       COL_LENGTH(N'dbo.productos', N'imagen_storage_key') AS producto_storage_key,
       COL_LENGTH(N'dbo.carrusel_inicio', N'imagen_storage_key') AS carrusel_storage_key,
       COL_LENGTH(N'dbo.configuracion_sitio', N'logo_storage_key') AS logo_storage_key;
