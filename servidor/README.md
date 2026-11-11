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

Para la versión actual de la app, aplica también `database/migrations/V20261107_02__ods12_envases_y_envios.sql` y `database/migrations/V20261111_01__pedido_ubicacion_entrega.sql`. La primera agrega opciones de envase, campos ODS 12 y datos de envío; la segunda agrega coordenadas opcionales para el punto de entrega. Ambas conservan los pedidos y productos existentes. El lanzador comprueba ahora tanto `/api/productos` como `/api/sitio/inicio` para detectar una base desactualizada antes de declarar listo el servidor.

No ejecutes `database/schema.sql` sobre una base existente: elimina y recrea tablas. `database/azure-schema.sql` es un inicializador para una base vacía, no una migración.

## Ejecutar

Desde la raíz del repositorio ejecuta `Iniciar servidor Dulce Miel.bat`. Si aún no existe `servidor/.env`, el lanzador lo crea a partir de `.env.example` y pide completar esa configuración antes de volver a iniciarlo. Luego comprueba Docker/SQL Server, compila el backend Spring Boot y lo inicia en el puerto `5000`. Este lanzador inicia solo el backend móvil; no inicia el frontend Angular del sistema original.

Para verificar el servidor desde Windows, abre `http://127.0.0.1:5000/api/health`, `http://127.0.0.1:5000/api/productos` y `http://127.0.0.1:5000/api/sitio/inicio`. El lanzador valida salud, catálogo y contenido de portada antes de indicar que el API está listo. Detén el proceso con `servidor/scripts/Stop-DulceMielServer.ps1`.

La app usa `http://10.0.2.2:5000/api/` por defecto cuando corre en Android Emulator. Para sobrescribirla en Flutter, usa `--dart-define=API_BASE_URL=http://<IP_DEL_PC>:5000/api/`; `10.0.2.2` no funciona desde un teléfono físico. Para un dispositivo físico, utiliza la IPv4 LAN del PC y permite el puerto 5000 en el firewall.

El servidor puede iniciar sin credenciales de Firebase Admin, pero `POST /api/auth/firebase/exchange` sí requiere una credencial de servicio Firebase o Application Default Credentials. Si no están configuradas, el intercambio de token fallará al invocar Firebase Admin. Las operaciones de imágenes requieren además la configuración B2 y la Application Key.
