# Dulce Miel Flutter

Aplicación móvil Android de la tienda Dulce Miel. Este README describe la arquitectura que existe en el código, los límites de cada integración y los pasos para ejecutar la app y el servidor local. La app usa Flutter y Dart; el backend continúa como Spring Boot con SQL Server.

## Alcance y decisiones técnicas

- La interfaz está construida con Flutter y Material 3. La lógica de presentación usa ViewModels basados en `ChangeNotifier` y un tipo compartido `UiState<T>`.
- El servidor expone una API REST. La app consume HTTP con `package:http` y operaciones asíncronas `Future`/`async`/`await`. Retrofit y Kotlin Coroutines pertenecen a la implementación Android nativa y no son dependencias de esta migración Flutter.
- Firebase Authentication identifica a los usuarios. Cloud Firestore guarda el perfil de usuario y las sugerencias. Los archivos se guardan en Backblaze B2 mediante el servidor; Firebase Storage no se usa porque no está dentro del alcance de facturación del proyecto.
- SQLite (`sqflite`) conserva respuestas públicas del catálogo y del contenido de tienda para mostrarlas sin conexión. No persiste pedidos, carrito, credenciales ni una operación de compra sin conexión.
- Google Maps y `geolocator` permiten elegir coordenadas de entrega y solicitar la posición del dispositivo. Google Maps puede dejar el área del mapa vacía cuando el proyecto de Google Cloud no autoriza Maps SDK for Android. La pantalla, el pin manual y el tratamiento de permisos están implementados; la disponibilidad visual de los mosaicos depende de esa autorización.

## Arquitectura MVVM

```text
Flutter UI (screens + widgets)
          │ acciones del usuario / escucha de cambios
          ▼
ViewModels (ChangeNotifier + UiState<T>)
          │ reglas de presentación y coordinación
          ▼
Repositories (casos de uso y adaptación de datos)
      ┌───┼────────┬──────────┐
      ▼   ▼        ▼          ▼
   API REST  Firebase   SQLite cache  Geolocator
      │          │        │             │
      └──────────┴────────┴─────────────┘
              servicios externos
```

`main.dart` es el punto de composición: inicializa Firebase, crea el almacenamiento seguro de sesión, el cliente HTTP, los administradores/repositorios compartidos y la app. Una `Screen` presenta estado y traduce interacciones en llamadas al ViewModel. El ViewModel publica cambios con `notifyListeners()` y no construye peticiones SQL/HTTP directamente. El Repository oculta si los datos vienen de la API, Firebase, SQLite o los servicios de ubicación. `ApiService` concentra HTTP, serialización de respuestas y autorización.

`UiState<T>` distingue `initial`, `loading`, `success`, `empty` y `error`. El estado puede conservar `data` anterior durante una recarga o un error, de modo que la interfaz puede mantener el contenido mientras presenta el aviso correspondiente. Algunos flujos de formulario conservan además un estado de acción separado del estado de pantalla para no bloquear datos por un guardado.

## Estructura de Flutter

```text
lib/
├── main.dart                         # inicialización e inyección de dependencias
├── app.dart                          # MaterialApp y navegación raíz
├── app_theme.dart                    # paleta y tema Material 3
├── firebase/                         # adaptadores de Firebase usados por repositorios
├── local/                            # cache SQLite
├── models/                           # modelos y estado común de UI
├── network/                          # API REST, autenticación HTTP y ApiException
├── repositories/                     # acceso a datos por funcionalidad
├── screens/                          # pantallas, formularios y navegación
│   └── widgets/                      # componentes visuales compartidos
└── viewmodels/                       # estado y acciones de las pantallas
```

### Arranque, tema y Firebase

| Clase o archivo | Responsabilidad y funciones |
| --- | --- |
| `main.dart` | Inicializa bindings y Firebase con `DefaultFirebaseOptions.currentPlatform`; lee `API_BASE_URL` con valor por defecto para Android Emulator; crea `SesionRepository`, configura `ApiService` para leer el JWT de la sesión y construye las dependencias Firebase/API/repositorios. Finalmente ejecuta `DulceMielApp`. |
| `DulceMielApp` (`app.dart`) | Construye `MaterialApp`, aplica el tema global y muestra `InicioScreen` como punto de entrada. Pasa las dependencias necesarias a las pantallas. |
| `DulceMielColors` y `DulceMielTheme` (`app_theme.dart`) | Centralizan colores, superficies, bordes, tipografía y componentes del tema Material 3 para mantener consistencia visual. |
| `FirebaseAuthManager` | `iniciarSesion` y `registrar` invocan Firebase Auth; `enviarRestablecimiento` inicia recuperación de contraseña; `obtenerIdToken` solicita el token Firebase para el servidor; `cerrarSesion` cierra la sesión Firebase; `obtenerUidAnonimo` habilita la identidad anónima usada al enviar sugerencias. |
| `PerfilFirestoreRepository` | `asegurarPerfil` crea o actualiza `usuarios/{uid}` con datos básicos del usuario autenticado. |
| `FirestoreRepository` | `crearSugerencia` escribe la sugerencia con categoría, mensaje, fecha e identificador del usuario en Firestore. |

`firebase_options.dart` y `android/app/google-services.json` son configuración generada para el proyecto Firebase y se mantienen fuera del repositorio. La CLI `flutterfire configure` los genera en cada entorno con acceso al proyecto. El archivo de opciones configura los SDK cliente por plataforma; no sustituye reglas de Firestore ni una credencial Admin. El servidor usa la credencial de Firebase Admin desde su entorno local para verificar los ID tokens.

### Modelos y estado de interfaz

| Modelo | Qué representa |
| --- | --- |
| `Producto` y `OpcionEnvase` | Producto del catálogo y sus opciones de empaque. Incluye precio, stock, categoría, estado, imagen y opciones como frasco convencional, frasco de vidrio o frasco del cliente. |
| `LineaCarrito` | Línea de carrito con producto, cantidad y opción de envase seleccionada. |
| `Pedido`, `LineaPedido` y `DetallePedido` | Resumen del pedido, renglones comprados y detalle cargado desde la API. El pedido puede llevar coordenadas opcionales y datos de envío de envases. |
| `ContenidoTienda`, `CarruselTienda` y `PromocionTienda` | Texto, imágenes, banners y promociones configurados para la portada. |
| `SesionUsuario` | JWT propio del backend, identificador/rol y datos de sesión necesarios para autorizar la API. |
| `PerfilUsuario` | Datos del perfil devueltos por el backend. |
| `Coordenada` | Latitud y longitud; `esValida` verifica que ambos valores estén dentro de los rangos geográficos válidos. |
| `UiStatus` y `UiState<T>` | Estados uniforme inicial, carga, éxito, vacío y error, más datos/mensaje opcionales. Los constructores `initial`, `loading`, `success`, `empty`, `error` y getters de estado simplifican el renderizado. |

Los modelos con JSON exponen `fromJson` (y cuando aplica `toJson`) para convertir respuestas o solicitudes de la API. Las pantallas no deben recrear el parseo de sus entidades.

### Red, repositorios y persistencia

#### `ApiService` (`network/api_service.dart`)

El cliente central construye URLs a partir de `API_BASE_URL`, usa `http`, codifica/decodifica JSON y propaga errores como `ApiException`. Las operaciones autenticadas adjuntan `Authorization: Bearer <JWT>` mediante el proveedor de sesión. Los errores HTTP, respuestas inválidas y fallos de conexión se convierten en errores que los ViewModels pueden mostrar.

| Grupo de métodos | Funciones principales |
| --- | --- |
| Conectividad y catálogo | `consultarSalud` consulta la disponibilidad del API; `consultarProductos` obtiene el catálogo público. |
| Sesión/perfil | `intercambiarTokenFirebase` envía el ID token Firebase a `/auth/firebase/exchange`; `consultarPerfil` lee el perfil de API. |
| Carrito | `consultarCarrito`, `agregarAlCarrito`, `actualizarCarrito`, `eliminarDelCarrito` y `vaciarCarrito` implementan lectura y CRUD del carrito en servidor. |
| Pedidos | `crearPedido`, `consultarPedidos` y `consultarDetallePedido` crean pedido y consultan historial/detalle. |
| Administración | Consulta dashboard, productos, pedidos, promociones y usuarios; guarda/elimina productos, promociones, usuarios, estado de pedidos, configuración del sitio y banners. |
| Imágenes y envíos | `_multipart` construye peticiones multipart con archivos. `guardarProductoAdministrativo`, `guardarCarrusel`, `guardarConfiguracionSitio`, `enviarBoletaEnvase` y `registrarEnvioPedidoAdministrativo` cargan imagen junto con campos de negocio. |
| Errores y transporte | `_get`, `_authenticated`, `_decodeAuthenticated` y `_listData` aplican transporte, token, lectura de respuestas y validación de listas. `ApiException` expone el mensaje legible de una operación fallida. |

#### Repositorios

| Clase | Flujo que coordina |
| --- | --- |
| `AutenticacionRepository` | Coordina Firebase Auth, la escritura del perfil Firestore, intercambio del ID token por JWT del servidor, persistencia segura, restauración, consulta de perfil, restablecimiento y cierre de sesión. `mensajeErrorAutenticacion` adapta errores Firebase a mensajes para la UI. |
| `SesionRepository` | `leer`, `guardar` y `borrar` acceden a `FlutterSecureStorage`. La sesión JWT se conserva de forma segura y el cliente HTTP la solicita en cada llamada protegida. |
| `CatalogoRepository` | `cargarProductos` consulta API, parsea productos y guarda JSON en SQLite. Si falla la red, recupera la última copia, marcando `CatalogoSnapshot.desdeCache`; si no hay copia útil, vuelve a propagar el fallo. |
| `ContenidoTiendaRepository` | `cargar` hace el mismo patrón de red/caché para el contenido público de portada y retorna `ContenidoTiendaSnapshot`. |
| `CarritoRepository` | Convierte respuesta del carrito a `LineaCarrito`, determina el total y expone agregar, cambiar cantidad, eliminar, vaciar, confirmar pedido y enviar boleta del envase. |
| `PedidosRepository` | Convierte historial/detalle a modelos y carga la boleta asociada a un pedido. |
| `AdministracionRepository` | Agrupa consultas del panel y acciones para productos, pedidos/envíos, promociones, usuarios, tienda y carrusel. Delega HTTP y archivos a `ApiService`. |
| `PerfilRepository` | Obtiene el perfil comercial desde `AutenticacionRepository` y lo adapta a `PerfilUsuario`. |
| `SugerenciasRepository` | Valida mensaje de 10 a 1000 caracteres y categoría (`producto`, `servicio`, `app`, `otro`), obtiene UID anónimo y persiste en Firestore. |
| `UbicacionRepository` | Revisa servicio y permisos con `geolocator`; solicita permiso al usuario cuando corresponde, detecta denegación temporal/permanente y obtiene ubicación actual con precisión media y tiempo límite. Devuelve `Coordenada` o `LocationException`. |

#### SQLite y caché offline

`JsonCacheStore` define `read(key)` y `write(key, value)` para poder sustituir SQLite por un doble en pruebas. `LocalCacheDatabase` es un singleton que abre `dulce_miel_cache.db`, crea `cache_json` y hace lecturas/escrituras atómicas por clave. Las claves actuales son `catalogo_publico_v1` y `contenido_tienda_publico_v1`.

La caché conserva JSON de datos públicos; sus URLs de imágenes siguen en Backblaze y requieren red para descargar la imagen. El stock puede estar desactualizado. Sesión usa almacenamiento seguro separado. Carrito, checkout y pedidos requieren API disponible y no se consideran transacciones offline.

### ViewModels

Todos extienden `ChangeNotifier`, exponen `UiState<T>` y notifican a la UI tras iniciar/finalizar una operación. Las pantallas pueden mostrar carga, éxito, lista vacía y error de manera explícita.

| ViewModel | Estado y funciones |
| --- | --- |
| `InicioViewModel` | `verificarApi` consulta salud del servidor y publica respuesta o error de conexión. |
| `CatalogoViewModel` | `cargar` obtiene catálogo desde API o caché; distingue lista vacía y expone si la fuente es caché. |
| `ContenidoTiendaViewModel` | `cargar` obtiene texto/promociones/carrusel y su indicador `desdeCache`. |
| `AccesoViewModel` | `restaurar`, `iniciarSesion`, `registrar`, `restablecerContrasena` y `cerrarSesion`; separa el estado de sesión del estado de acción del formulario. `_ejecutar` encapsula el ciclo carga/éxito/error de autenticación. |
| `CarritoViewModel` | `cargar`, `agregar`, `cambiarCantidad`, `eliminar`, `vaciar` y `confirmarPedido`; mantiene líneas, total y cantidad total; `limpiarLocal` limpia estado al cerrar sesión; `_operar` centraliza acciones del carrito y sus avisos. |
| `PedidosViewModel` | `cargar`, `cargarDetalle` y `enviarBoletaEnvase`; mantiene estados independientes para lista, detalle y envío. Tras subir la boleta vuelve a cargar el detalle. |
| `PerfilViewModel` | `cargar` consulta el perfil y convierte fallos a estado de error. |
| `AdministracionViewModel` | `cargarTodo` solicita resumen/productos/pedidos/promociones/usuarios/sitio; `guardarProducto`, `eliminarProducto`, `actualizarPedido`, `registrarEnvioPedido`, `guardarPromocion`, `eliminarPromocion`, `crearEmpleado`, `actualizarUsuario`, `guardarSitio`, `guardarSlide` y `eliminarSlide` ejecutan mutaciones, refrescan datos y publican resultado mediante `_mutar`; `limpiarAviso` borra feedback anterior. |
| `BuzonSugerenciasViewModel` | `enviar` expone validación, proceso de autenticación anónima, confirmación y errores específicos de Firebase/Firestore. |
| `UbicacionViewModel` | `seleccionar` guarda coordenada manual; `usarUbicacionActual` actualiza `UiState` según resultado/permisos; `abrirConfiguracionPermisos` y `abrirConfiguracionUbicacion` llevan a Ajustes del sistema; `_mensaje` traduce cada motivo a instrucciones claras. |

### Pantallas y widgets

`screens` construye vistas, captura texto/selecciones, navega y observa ViewModels. No aloja acceso directo al SQL Server ni reglas de negocio de servidor.

| Pantalla | Flujo presentado |
| --- | --- |
| `InicioScreen` | Portada de tienda, estado de API/caché, carrusel horizontal, promociones, categorías y productos; navega a catálogo, detalle, carrito, pedidos, cuenta y acceso administrativo según rol. |
| `CatalogoScreen` | Lista y búsqueda/filtro de productos, detalle, selección de envase/cantidad y acción de añadir al carrito. |
| `AccesoScreen` | Inicio de sesión, registro y recuperación de contraseña. |
| `CarritoScreen` | Carrito y checkout; captura contacto/dirección y opción de coordenada; explica el envío del envase cuando aplica y permite adjuntar comprobante. |
| `MapaUbicacionScreen` | Presenta mapa Google, selección manual/arrastrable, botón de ubicación actual y confirmación de punto. El mapa se renderiza cuando SDK/key/billing son aceptados por Google. |
| `PedidosScreen` | Historial, detalle, comprobante del envase y consulta del punto de entrega. |
| `PerfilScreen` | Datos de cuenta, sesión y navegación a autenticación/cierre de sesión. |
| `AdministracionScreen` | Pestañas de resumen, productos, pedidos, promociones, usuarios y contenido; formularios de edición y carga de imágenes. |
| `BuzonSugerenciasScreen` | Categoría, mensaje, validación y confirmación del envío a Firestore. |
| `Ods12Screen` | Explica opciones de recipiente y consumo responsable en la compra. |
| `PageIntro`, `FeedbackPanel`, `StatusBadge` (`screens/widgets/ui_components.dart`) | Componentes visuales reutilizables para encabezados, mensajes de carga/error/vacío y etiquetas de estado. |

Las pantallas mantienen controladores de formularios, selección local de pestañas y navegación; el estado de datos remotos y sus mutaciones vive en ViewModels. `image_picker` permite seleccionar/capturar imágenes desde Android, y el backend valida y envía los archivos al bucket B2.

## Flujo de datos por funcionalidad

### Autenticación y sesión

1. `AccesoScreen` recoge email/contraseña y llama `AccesoViewModel`.
2. `AutenticacionRepository` autentica o registra con `FirebaseAuthManager`.
3. `PerfilFirestoreRepository` asegura el documento de usuario.
4. El repositorio obtiene el ID token Firebase y `ApiService.intercambiarTokenFirebase` lo envía al backend.
5. El backend valida el token con Firebase Admin, asocia el UID a SQL Server y devuelve su JWT.
6. `SesionRepository` persiste el JWT con `FlutterSecureStorage`. Las llamadas REST protegidas lo envían como Bearer. Al cerrar sesión se eliminan ambas sesiones.

### Catálogo, carrito y compra

1. La portada y el catálogo leen API y actualizan caché pública. Sin conexión muestran la última instantánea si existe.
2. La selección de envase viaja con cada línea del carrito; el servidor calcula cantidades/precios y valida existencias.
3. Checkout envía contacto, dirección, distrito, referencia/notas, opción de envase y coordenadas opcionales.
4. El backend persiste cabecera/detalle del pedido en SQL Server. El cliente siempre asume los gastos de entrega y recojo según el flujo comercial.
5. Si se eligió reutilizar un frasco propio, el cliente registra agencia/código y adjunta imagen de la boleta. Administración puede registrar el envío de vuelta con su comprobante.
6. El API devuelve el pedido; `PedidosViewModel` carga historial y detalle.

### Administración e imágenes

Las acciones administrativas requieren JWT/rol válido. `ApiService` envía campos y, cuando corresponde, imagen multipart. El servidor valida rol, tipo/tamaño/contenido, sube a B2 y persiste metadatos/URL en SQL Server. La app pública consume URL de la imagen. Los comprobantes de envío están temporalmente en bucket público y deben pasar a almacenamiento privado/URLs firmadas antes de producción.

### Ubicación

El usuario puede omitir coordenadas o seleccionar un punto en mapa; el permiso GPS solo se solicita al pulsar “Mi ubicación”. Denegación, bloqueo permanente o servicios apagados dejan disponible la captura manual. Las coordenadas se envían juntas y el servidor comprueba sus rangos. No se implementan Places, geocodificación ni rutas; el cliente mantiene el texto de dirección escrito por el comprador.

## Backend incluido

`servidor/` contiene el API Spring Boot y scripts para ejecutarlo junto con SQL Server local.

| Paquete / clase | Función |
| --- | --- |
| `BackendJavaApplication` | Arranca la aplicación Spring Boot. |
| `config/DotenvInitializer` | Carga variables locales desde `.env` en el arranque. |
| `config/SecurityConfig` | Configura seguridad web, codificador de contraseñas y CORS. |
| `model/AuthUser` | Identidad autenticada con `canAdmin` e `isOwnerAdmin` para separar privilegios administrativos. |
| `service/FirebaseIdentityService` | Verifica ID tokens, resuelve UID/cuenta SQL y crea/elimina identidades Firebase cuando el flujo lo requiere. |
| `service/JwtService` | `generateToken` crea JWT de API; `parse` valida autorización y carga usuario/rol. |
| `service/AuthSupport` | `user`, `admin` y `ownerAdmin` protegen endpoints por rol. |
| `service/BackblazeB2ImageStorageService` | `upload` valida/sube archivos al bucket compatible con S3; `publicUrl` calcula URL; `delete` retira objeto. |
| `service/ImageUrlService` | Prepara URLs/versiones de imágenes para producto, carrusel y sitio. |
| `service/ResponseService` | `body`, `ok`, `created` y `error` unifican estructura HTTP de respuestas. |
| `controller/HealthController` | `GET /api/health` para comprobar disponibilidad. |
| `controller/AuthController` | Intercambio Firebase/JWT, registro/login compatibles, perfil, listado y mantenimiento de usuarios/empleados. |
| `controller/ProductosController` | `GET /api/productos`, `GET /{id}`, `GET /admin/todos`, `POST`, `PUT /{id}`, `DELETE /{id}`; guarda imágenes y opciones de envase. |
| `controller/CarritoController` | Consulta/agrega/actualiza/elimina/vacía carrito autenticado. |
| `controller/PedidosController` | Crea pedidos, lista usuario/admin, trae detalle, cambia estado, recibe boleta de frasco y registra envío administrativo. |
| `controller/PromocionesController` | Consulta y CRUD administrativo de promociones. |
| `controller/SitioController` | `GET /inicio`, edición de contenido y CRUD de carrusel. |
| `controller/DashboardController` | Resumen administrativo. |
| `controller/ImagenesController` | Sirve recursos de imagen existentes mediante rutas API. |

El servidor usa JDBC/SQL Server y controladores REST. Las migraciones de `servidor/database/migrations/` agregan UID Firebase, metadatos B2, envases/envíos ODS 12 y coordenadas de entrega. `schema.sql` recrea un esquema vacío; no se debe ejecutar sobre una base que ya contiene datos. `azure-schema.sql` es un inicializador de base vacía.

## Requisitos y configuración local

- Flutter SDK compatible con `pubspec.yaml` (Dart `^3.13.7`) y Android SDK.
- Android Studio con un emulador configurado o un dispositivo físico Android.
- Java instalado para Spring Boot, Docker Desktop y el contenedor SQL Server `sql_servidor`.
- Acceso al proyecto Firebase para generar configuración cliente y credencial Admin local.
- Configuración Backblaze B2 en el backend. Google Maps requiere que el proyecto autorice el SDK Android; si se omite, la app sigue permitiendo elegir las coordenadas manualmente, pero no puede prometerse la vista de mosaicos.

### Configurar Firebase cliente

Desde la raíz Flutter, instala Firebase CLI/FlutterFire CLI, autentícate, y ejecuta la configuración para Android:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=dulcemiel-f65a1 --platforms=android
```

El comando genera `lib/firebase_options.dart` y configura `android/app/google-services.json`. Ambos son dependencias locales ignoradas por Git y cada desarrollador debe generarlas con acceso al proyecto. No copiar una cuenta de servicio Admin al cliente Android.

### Configurar Maps Android

Copiar `android/secrets.properties.example` a `android/secrets.properties` y completar `MAPS_API_KEY` localmente, o declarar esa variable de entorno antes de compilar. El archivo de secretos no se sube. La clave de Android queda dentro del binario porque el SDK la necesita; restringirla en Google Cloud a Maps SDK for Android, package `com.dulcemiel.app.flutter` y SHA-1 de firma correspondiente. El SDK puede requerir habilitación de facturación/autorización según el proyecto. No activar el servicio ni cambiar plan sin seguir las condiciones aceptadas por el docente.

### Configurar el backend

1. Desde `servidor/`, copia `.env.example` a `.env` y completa usuario/contraseña SQL, `JWT_SECRET`, `FIREBASE_PROJECT_ID`, credencial Firebase Admin (`FIREBASE_CREDENTIALS_FILE`) y claves B2 (`B2_S3_ENDPOINT`, `B2_REGION`, `B2_BUCKET`, `B2_KEY_ID`, `B2_APPLICATION_KEY`). No publiques `.env` ni las credenciales.
2. Asegura que Docker Desktop y el SQL Server estén levantados. Conecta la base de datos correcta y aplica, en orden, las migraciones versionadas necesarias que aún no existan.
3. Ejecuta `Iniciar servidor Dulce Miel.bat` desde la raíz del proyecto. La primera ejecución crea `.env` desde `.env.example` si falta y solicita completarlo.
4. El servidor compila/inicia Spring Boot en puerto 5000 y verifica salud, catálogo y contenido de portada. El batch solo inicia el backend.

Endpoints de comprobación local: `http://127.0.0.1:5000/api/health`, `http://127.0.0.1:5000/api/productos` y `http://127.0.0.1:5000/api/sitio/inicio`. Para detenerlo, usa `servidor/scripts/Stop-DulceMielServer.ps1`.

## Ejecutar la aplicación

Desde la carpeta raíz `dulcemiel-flutter`:

```powershell
flutter pub get
flutter run
```

El valor por defecto de API apunta al backend del host desde Android Emulator por `10.0.2.2`:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/
```

En teléfono físico, reemplaza esa dirección por la IPv4 LAN del PC y permite el puerto 5000 en el firewall. El emulador y el PC deben compartir conectividad.

`flutter run` ejecuta modo debug directamente desde el IDE/emulador. Para generar paquetes manuales:

```powershell
flutter build apk --debug
flutter build apk --release
```

La compilación release requiere configurar firma de publicación propia antes de distribuir la app. No enviar claves ni keystore al repositorio.

## Verificación y alcance conocido

Comandos reproducibles desde la raíz Flutter:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

La prueba `test/catalogo_flow_test.dart` verifica que el repositorio guarda una respuesta REST en una caché sustituible y que la recupera cuando el servidor falla; otra prueba verifica que el ViewModel devuelve `empty` para catálogo vacío. Estas pruebas no prueban el plugin SQLite nativo en dispositivo, todos los endpoints CRUD, Firebase real, B2 ni render del mapa.

La app y el flujo de compra se han usado manualmente durante el sprint: el catálogo y detalle, autenticación, carrito y guardado de pedidos se visualizaron en el emulador/servidor. La vista de Google Maps mostrada durante la validación quedó vacía por autorización SDK/configuración de billing; este límite de demostración fue aceptado por el docente. Antes de una entrega evaluable, adjuntar capturas actuales, salida de comandos y registro de pedido sin datos personales en el informe. No se afirma que una captura antigua pruebe el estado actual del backend.

## ODS 12

El checkout ofrece empaque convencional, compra de frasco de vidrio y uso de un frasco propio, con costo adicional solo al comprar vidrio. Si se registra envío de frasco, el comprador asume sus propios costos de envío/recojo; se piden datos de agencia y comprobante. El panel permite registrar recepción/envío y adjuntar el comprobante. El contenido educativo promueve consumo responsable. Esto contribuye de forma acotada a circularidad/reducción de envases y a educación de consumo, pero no acredita por sí solo el cumplimiento integral de ODS 12 ni mide reducción real de residuos.

## Archivos del proyecto

- `docs/Informe_Tecnico_Dulce_Miel_Rubrica.docx`: evaluación técnica trazable con la rúbrica, resultados y brechas.
- `docs/Sustentacion_Dulce_Miel.pptx`: guion visual de sustentación con arquitectura, flujos, código y límites conocidos.
- `servidor/README.md`: configuración, migraciones y ejecución del servidor local.
