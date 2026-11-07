# Servidor local Dulce Miel

Esta carpeta es una copia de `Desarrollo/dulcemiel-web/backend`, el backend Spring Boot usado por el sistema web. La copia permite integrar y ejecutar el servidor junto con la app Android. El origen no se modifica.

## Firebase Authentication

La app Android autentica al usuario con Firebase Auth y guarda su perfil en Firestore. Después envía el Firebase ID token a `POST /api/auth/firebase/exchange`. Este servidor verifica el token con Firebase Admin, asocia el UID al usuario SQL y devuelve el JWT de Dulce Miel que usa la app en las operaciones comerciales.

El perfil Firestore no lo escribe este servidor. Se aplican las reglas `firestore.rules` de la raíz del proyecto móvil; el backend solo valida identidad y consulta SQL.

## Configuración local

1. Copia `.env.example` a `.env` y configura el servidor/base de datos local, el usuario SQL y una clave JWT privada. Para el contenedor `sql_servidor`, usa `127.0.0.1:1433`, `DulceMielBD` y autenticación SQL.
2. Configura `FIREBASE_PROJECT_ID=dulcemiel-f65a1`.
3. Para Firebase Admin, configura `FIREBASE_CREDENTIALS_FILE` con la ruta absoluta a una credencial de servicio del proyecto Firebase. Si se deja vacía, el servidor usa Google Application Default Credentials. Mantén el JSON fuera de Git y de la app Android.
4. Configura `B2_S3_ENDPOINT`, `B2_REGION`, `B2_BUCKET`, `B2_KEY_ID` y `B2_APPLICATION_KEY` con los datos de tu bucket B2. Crea el bucket como público (lectura pública para las imágenes de tienda) y crea una Application Key limitada a ese bucket con permisos para leer, subir y eliminar archivos. La escritura seguirá pasando por el backend autenticado.
5. `B2_PUBLIC_BASE_URL` es opcional; úsala solo si tienes un dominio propio o CDN delante del bucket. Si queda vacía, la API forma los enlaces públicos con el endpoint regional de B2.
6. Mantén las claves de Backblaze solo en el `.env` del servidor; nunca las agregues a Flutter ni a Firebase.
7. Asegura que la instancia SQL Server esté iniciada y que `MSSQL_JDBC_URL` corresponda a esa instancia.

No se copió el `.env` del backend de origen. El archivo `.env.example` sirve como plantilla y `.env` está ignorado por Git.

## Migración SQL local

Conéctate a `DulceMielBD` en la instancia local y ejecuta una vez `database/migrations/V20261103_01__firebase_uid_usuarios.sql` desde SSMS o `sqlcmd`. La migración agrega la columna nullable `firebase_uid` y un índice único filtrado; preserva las filas y tablas existentes, y se puede volver a ejecutar.

Para las imágenes, ejecuta `database/migrations/V20261107_01__backblaze_storage_image_keys.sql` conectado a la base configurada en `MSSQL_JDBC_URL`. Añade claves de objeto para productos, carrusel y logo, conserva cualquier URL o imagen binaria existente y permite que nuevas cargas usen B2. El backend mantiene la autorización de administrador y la app continúa recibiendo `imagen_url` en las respuestas.

No ejecutes `database/schema.sql` sobre una base existente: elimina y recrea tablas. `database/azure-schema.sql` es un inicializador para una base vacía, no una migración.

## Ejecutar

Haz doble clic en `Iniciar servidor Dulce Miel.cmd` desde la raíz del proyecto. La ventana permanece abierta con el estado del arranque. El lanzador comprueba Docker y SQL, inicia Spring Boot, luego el frontend Angular del sistema original (`Proyecto Final - Dulce Miel/Desarrollo/dulcemiel-web/frontend`) y abre `http://localhost:4200`. Los logs quedan en `servidor/logs/servidor.log` y `servidor/logs/frontend.log`. El API responde en `http://localhost:5000/api/health`. Para detener el backend, ejecuta `servidor/scripts/Stop-DulceMielServer.ps1`.

El servidor escucha en el puerto `5000`. La variante Android `debug` apunta por defecto a `http://10.0.2.2:5000/api/` (la PC vista desde el emulador), mientras `release` conserva Azure. Se puede sobrescribir con `-PdulcemielApiBaseUrl=...`. Para validar desde Windows, usa `http://127.0.0.1:5000/api/health`.

El servidor puede iniciar sin credenciales de Firebase Admin, pero `POST /api/auth/firebase/exchange` sí requiere una credencial de servicio Firebase o Application Default Credentials. Si no están configuradas, el intercambio de token fallará al invocar Firebase Admin. Las operaciones de imágenes requieren además la configuración B2 y la Application Key.
