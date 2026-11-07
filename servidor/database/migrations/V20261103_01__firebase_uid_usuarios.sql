-- Migracion aditiva para asociar cuentas Firebase Auth con usuarios de Dulce Miel.
-- Ejecutar conectado a DulceMielBD. No elimina ni recrea tablas o filas.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'DulceMielBD'
    THROW 51000, 'Conectate a DulceMielBD antes de ejecutar esta migracion.', 1;

IF OBJECT_ID(N'dbo.usuarios', N'U') IS NULL
    THROW 51001, 'No existe dbo.usuarios en DulceMielBD.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.usuarios', N'firebase_uid') IS NULL
        ALTER TABLE dbo.usuarios ADD firebase_uid NVARCHAR(128) NULL;

    -- Ejecutar las referencias a la columna en un lote separado: SQL Server
    -- compila el lote antes de aplicar el ALTER TABLE anterior.
    EXEC sys.sp_executesql N'
        IF EXISTS (
            SELECT firebase_uid
            FROM dbo.usuarios
            WHERE firebase_uid IS NOT NULL
            GROUP BY firebase_uid
            HAVING COUNT_BIG(*) > 1
        )
            THROW 51002, N''Hay firebase_uid duplicados; no se creo el indice unico.'', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM sys.indexes
            WHERE name = N''UX_usuarios_firebase_uid''
              AND object_id = OBJECT_ID(N''dbo.usuarios'')
        )
            CREATE UNIQUE INDEX UX_usuarios_firebase_uid
                ON dbo.usuarios(firebase_uid)
                WHERE firebase_uid IS NOT NULL;
    ';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT DB_NAME() AS base_de_datos,
       COL_LENGTH(N'dbo.usuarios', N'firebase_uid') AS columna_firebase_uid,
       CASE WHEN EXISTS (
           SELECT 1 FROM sys.indexes
           WHERE name = N'UX_usuarios_firebase_uid'
             AND object_id = OBJECT_ID(N'dbo.usuarios')
       ) THEN 1 ELSE 0 END AS indice_creado;
