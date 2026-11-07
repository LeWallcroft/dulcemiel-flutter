# Dulce Miel Flutter

Migración Flutter de Dulce Miel para Android. Mantiene la organización MVVM existente:

```text
screens -> viewmodels -> repositories -> network (API REST)
                                  `----> firebase (Auth / Firestore)
```

Las pantallas conservan su presentación en `screens`, el estado y las acciones en `viewmodels`, el acceso a datos en `repositories` y las comunicaciones en `network` o `firebase`. Firebase permanece dentro de `lib/firebase`; las imágenes del catálogo se almacenan en Backblaze B2 a través del servidor.

## Ejecutar la app

Desde esta carpeta, con Flutter instalado y un emulador Android iniciado:

```powershell
flutter pub get
flutter run
```

La URL de desarrollo para Android Emulator es `http://10.0.2.2:5000/api/`. Para cambiarla:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/
```

La configuración Firebase de Android es local y no se versiona. Para configurarla en un clon, instala Firebase CLI y FlutterFire CLI, inicia sesión con `firebase login`, y ejecuta desde esta raíz:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=dulcemiel-f65a1 --platforms=android
```

Después coloca el archivo Android de Firebase como `android/app/google-services.json`. Ambos archivos se mantienen locales y excluidos del repositorio.

## Ejecutar el servidor incluido

El backend Spring Boot está en `servidor/`. Desde la raíz del proyecto, ejecuta `Iniciar servidor Dulce Miel.bat`. Requiere Docker con el contenedor SQL Server `sql_servidor`, Java y conexión de base de datos configurada.

La primera ejecución crea `servidor/.env` desde `.env.example`; completa allí SQL Server, Firebase Admin y Backblaze. El archivo `.env` y la credencial JSON Firebase son configuración local y están excluidos de Git. Antes de arrancar el servidor con los cambios ODS 12, aplica en SQL Server la migración aditiva `servidor/database/migrations/V20261108_01__ods12_envases_y_envios.sql`; conserva los datos actuales y no ejecutes `schema.sql` sobre una base que ya contiene información.

El BAT inicia únicamente el backend. Para detenerlo usa `servidor/scripts/Stop-DulceMielServer.ps1`.

## Seguridad de archivos

Las fotos públicas de productos, logo y carrusel usan el bucket público actual de Backblaze. Las boletas de envío pueden contener datos personales; el plan actual las subirá al bucket público temporalmente según la decisión del proyecto, por lo que se debe migrar ese flujo a almacenamiento privado antes de manejar datos reales de clientes de forma permanente.

## Estado y arquitectura

La app implementa inicio, catálogo, detalle de producto, carrito, pedidos, acceso, administración y una sección educativa ODS 12. Los envases permiten empaque convencional, compra de frasco de vidrio o recarga en frasco del cliente. Este último flujo captura agencia, guía, costo y boleta del envío de entrada; administración confirma su recepción. Al despachar, administración registra agencia, guía, costo y boleta para el cliente. Estas acciones representan aportes limitados a las metas 12.5 y 12.8 y no una certificación ni el cumplimiento integral del ODS.
