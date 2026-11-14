# Dulce Miel 1.0.0: preparación para publicación en Google Play

## 1. Datos técnicos del paquete
| Dato | Valor |
|---|---|
| Nombre de la app | Dulce Miel |
| ID de aplicación (package) | com.dulcemiel.app.flutter |
| Versión | 1.0.0 (versionCode 1) |
| Formato | Android App Bundle (.aab), firmado |
| Ruta del .aab | build/app/outputs/bundle/release/app-release.aab |
| SDK objetivo (targetSdk) | flutter.targetSdkVersion (Android 16, API 36) |
| Keystore | android/dulcemiel-release.jks (PKCS12, RSA 2048, alias `dulcemiel`, válido hasta 2054) |
| Huella SHA-256 del certificado | FA:EE:B8:C7:45:08:67:67:BB:35:5B:A0:8A:B8:82:49:CF:15:B0:07:A1:D4:12:73:83:A6:DF:91:69:D4:99:97 |

> El keystore y `android/key.properties` están excluidos de Git (.gitignore). Si se pierden, no se pueden publicar actualizaciones con la misma firma (salvo con la firma de apps de Play).

## 2. Ficha de tienda (Play Console → Presencia en tienda → Ficha principal)

**Nombre (máx. 30):** Dulce Miel

**Descripción breve (máx. 80):** Miel pura y productos apícolas de nuestra colmena, directo a tu mesa.

**Descripción completa (máx. 4000):**
Dulce Miel es la tienda oficial de nuestra colmena. Compra miel pura, propóleo, polen, panal y kits de regalo de forma sencilla y segura desde tu celular.

Qué puedes hacer:
• Explorar el catálogo por categorías: Miel, Derivados, Especiales y Kits.
• Buscar productos y ver precio, stock disponible y descripción.
• Agregar productos al carrito y elegir el tipo de envase.
• Reutilizar tu propio frasco de vidrio y obtener un descuento (consumo responsable, ODS 12).
• Indicar tu ubicación de entrega en el mapa.
• Revisar el estado de tus pedidos.
• Enviar sugerencias para mejorar la tienda.
• Seguir viendo el catálogo aunque no tengas conexión (caché local).

Dulce Miel promueve la producción y el consumo responsables: menos envases desechables y productos apícolas trabajados con cuidado local.

**Categoría:** Compras · **Etiquetas:** comida, tienda, productos naturales
**Correo de contacto:** (correo del equipo)
**Política de privacidad:** (URL pública obligatoria por usar cámara, ubicación y cuenta de usuario)
**Clasificación de contenido:** Apto para todo público (IARC)

**Recursos gráficos:**
| Recurso | Requisito de Play | Archivo |
|---|---|---|
| Ícono | 512×512 PNG | icono_play_store_512.png |
| Gráfico de funciones | 1024×500 | grafico_funciones_1024x500.png |
| Capturas de teléfono | mínimo 2 (de 320 a 3840 px) | capturas_app/01_inicio … 06_pedidos |

## 3. Permisos declarados (AndroidManifest.xml)
| Permiso | Tipo | Para qué se usa | Cuándo se pide |
|---|---|---|---|
| INTERNET | Normal | Consultar catálogo, carrito y pedidos en el servidor; Firebase | Automático |
| CAMERA | Peligroso (en ejecución) | Fotografiar productos en el módulo de Administración | Solo al tocar "Tomar foto" |
| ACCESS_COARSE_LOCATION | Peligroso (en ejecución) | Ubicación aproximada para la dirección de entrega | Al abrir el mapa de entrega |
| ACCESS_FINE_LOCATION | Peligroso (en ejecución) | Ubicación precisa del punto de entrega | Al abrir el mapa de entrega |

`android.hardware.camera` se declara con `required="false"`, así que la app se instala también en equipos sin cámara.

**Formulario de seguridad de datos (Data safety):** se recopilan correo y nombre (cuenta), ubicación aproximada y precisa (entrega) y fotos solo para administradores. Los datos se envían cifrados al servidor y no se comparten con terceros con fines publicitarios.

## 4. Notas de versión (máx. 500): versión 1.0.0
<es-419>
Primera versión de Dulce Miel:
• Catálogo de miel y productos apícolas con categorías y búsqueda.
• Carrito con elección de envase y descuento por frasco reutilizable (ODS 12).
• Pedidos con ubicación de entrega en el mapa.
• Inicio de sesión con cuenta Dulce Miel.
• Buzón de sugerencias.
• Catálogo disponible sin conexión.
</es-419>

## 5. Lista de verificación previa al envío
- [x] Versión 1.0.0 (versionCode 1) en pubspec.yaml
- [x] Firma release con keystore propio (ya no con la clave de debug)
- [x] App Bundle (.aab) generado
- [x] targetSdk ≥ 36 (requisito vigente de Google Play)
- [x] Ícono propio (reemplaza el logo de Flutter por defecto)
- [x] Ficha, gráfico de funciones y capturas
- [x] Permisos justificados
- [ ] Antes de producción: API_BASE_URL con HTTPS (la versión release bloquea HTTP sin cifrar)
- [ ] Antes de producción: publicar la política de privacidad
