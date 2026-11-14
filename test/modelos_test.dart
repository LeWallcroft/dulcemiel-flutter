// Pruebas unitarias de los modelos de datos (Semana 13 - pruebas funcionales).
import 'package:dulce_miel_flutter/models/coordenada.dart';
import 'package:dulce_miel_flutter/models/linea_carrito.dart';
import 'package:dulce_miel_flutter/models/pedido.dart';
import 'package:dulce_miel_flutter/models/producto.dart';
import 'package:dulce_miel_flutter/models/sesion_usuario.dart';
import 'package:dulce_miel_flutter/models/ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Producto', () {
    test('PU-01 fromJson convierte todos los campos y las opciones de envase', () {
      final producto = Producto.fromJson({
        'id': 3,
        'nombre': 'Miel de eucalipto',
        'descripcion': 'Frasco de 500 g',
        'precio': 25,
        'stock': 12,
        'categoria': 'Miel',
        'imagen_url': 'https://cdn.test/miel.png',
        'opciones_envase': [
          {'id': 1, 'codigo': 'frasco_cliente', 'nombre': 'Mi frasco', 'costo_extra': '-2.50'},
        ],
        'informacion_ods12': 'Envase reutilizable',
      });

      expect(producto.id, 3);
      expect(producto.precio, 25.0);
      expect(producto.stock, 12);
      expect(producto.imagenUrl, 'https://cdn.test/miel.png');
      expect(producto.opcionesEnvase, hasLength(1));
      expect(producto.opcionesEnvase.first.usaFrascoCliente, isTrue);
      expect(producto.opcionesEnvase.first.costoExtra, -2.5);
      expect(producto.informacionOds12, 'Envase reutilizable');
    });

    test('PU-02 fromJson usa valores por defecto cuando faltan campos opcionales', () {
      final producto = Producto.fromJson({'id': 1, 'precio': 10.5, 'stock': 0});
      expect(producto.nombre, isEmpty);
      expect(producto.categoria, isEmpty);
      expect(producto.opcionesEnvase, isEmpty);
      expect(producto.metaOds12, isNull);
    });

    test('PU-03 OpcionEnvase asume envase convencional si no hay código', () {
      final envase = OpcionEnvase.fromJson({});
      expect(envase.codigo, 'convencional');
      expect(envase.usaFrascoCliente, isFalse);
      expect(envase.costoExtra, 0);
    });
  });

  group('LineaCarrito', () {
    test('PU-04 fromJson arma el producto y el envase de la línea', () {
      final linea = LineaCarrito.fromJson({
        'id': 9,
        'cantidad': 2,
        'producto_id': 3,
        'nombre': 'Miel de eucalipto',
        'precio': 25.0,
        'stock': 5,
        'opcion_envase_id': 1,
        'envase_codigo': 'convencional',
        'envase_nombre': 'Frasco de vidrio',
        'costo_envase_unitario': '1.50',
      });
      expect(linea.id, 9);
      expect(linea.cantidad, 2);
      expect(linea.producto.id, 3);
      expect(linea.producto.stock, 5);
      expect(linea.envase.nombre, 'Frasco de vidrio');
      expect(linea.costoEnvaseUnitario, 1.5);
    });

    test('PU-05 sin stock informado se considera disponible', () {
      final linea = LineaCarrito.fromJson({
        'id': 1, 'cantidad': 1, 'producto_id': 1, 'precio': 10,
      });
      expect(linea.producto.stock, greaterThan(1000));
    });
  });

  group('Pedido', () {
    test('PU-06 fromJson convierte totales en texto y coordenadas de entrega', () {
      final pedido = Pedido.fromJson({
        'id': 15,
        'numero_pedido': 'DM-0015',
        'total': '56.00',
        'estado': 'confirmado',
        'direccion_entrega_lat': '-12.0464',
        'direccion_entrega_lng': '-77.0428',
        'tiene_envase_cliente': true,
        'cantidad_envases_cliente': 2,
      });
      expect(pedido.numero, 'DM-0015');
      expect(pedido.total, 56.0);
      expect(pedido.estado, 'confirmado');
      expect(pedido.latitudEntrega, closeTo(-12.0464, 1e-6));
      expect(pedido.tieneEnvaseCliente, isTrue);
      expect(pedido.cantidadEnvasesCliente, 2);
    });

    test('PU-07 un pedido sin estado queda como pendiente', () {
      final pedido = Pedido.fromJson({'id': 1, 'total': null});
      expect(pedido.estado, 'pendiente');
      expect(pedido.total, 0);
      expect(pedido.latitudEntrega, isNull);
    });

    test('PU-08 LineaPedido calcula precios desde texto', () {
      final linea = LineaPedido.fromJson({
        'id': 1, 'producto_id': 3, 'nombre': 'Miel', 'cantidad': 2,
        'precio_unitario': '25.00', 'subtotal': '50.00',
      });
      expect(linea.precioUnitario, 25.0);
      expect(linea.subtotal, 50.0);
    });
  });

  group('SesionUsuario', () {
    test('PU-09 toJson y fromJson conservan la sesión (almacenamiento seguro)', () {
      const sesion = SesionUsuario(
        tokenApi: 'jwt.token', id: 4, nombre: 'Ana', email: 'ana@test.pe', rol: 'admin',
      );
      final restaurada = SesionUsuario.fromJson(sesion.toJson());
      expect(restaurada.tokenApi, 'jwt.token');
      expect(restaurada.id, 4);
      expect(restaurada.rol, 'admin');
    });

    test('PU-10 fromApi asigna rol usuario por defecto', () {
      final sesion = SesionUsuario.fromApi(
        token: 't', usuario: {'id': 2, 'nombre': 'Luis', 'email': 'l@test.pe'},
      );
      expect(sesion.rol, 'usuario');
    });
  });

  group('Coordenada y UiState', () {
    test('PU-11 Coordenada valida rangos de latitud y longitud', () {
      expect(const Coordenada(latitud: -12.04, longitud: -77.04).esValida, isTrue);
      expect(const Coordenada(latitud: 91, longitud: 0).esValida, isFalse);
      expect(const Coordenada(latitud: 0, longitud: -181).esValida, isFalse);
    });

    test('PU-12 UiState conserva los datos previos durante carga y error', () {
      final carga = UiState<List<int>>.loading(previous: const [1, 2]);
      final error = UiState<List<int>>.error('falló', previous: const [1, 2]);
      expect(carga.isLoading, isTrue);
      expect(carga.data, [1, 2]);
      expect(error.hasError, isTrue);
      expect(error.message, 'falló');
      expect(error.data, [1, 2]);
    });
  });
}
