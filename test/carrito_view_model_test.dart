// Pruebas del flujo del carrito: ViewModel + Repository + API simulada.
import 'dart:convert';

import 'package:dulce_miel_flutter/models/ui_state.dart';
import 'package:dulce_miel_flutter/network/api_service.dart';
import 'package:dulce_miel_flutter/repositories/carrito_repository.dart';
import 'package:dulce_miel_flutter/viewmodels/carrito_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _linea({int id = 1, int cantidad = 2, int stock = 5}) => {
      'id': id,
      'cantidad': cantidad,
      'producto_id': 3,
      'nombre': 'Miel de eucalipto',
      'precio': 25.0,
      'stock': stock,
      'costo_envase_unitario': 0,
    };

CarritoViewModel _vm(MockClientHandler handler) => CarritoViewModel(
      CarritoRepository(ApiService(
        baseUrl: 'https://example.test/api/',
        client: MockClient(handler),
        tokenProvider: () async => 'jwt-prueba',
      )),
    );

void main() {
  group('CarritoViewModel', () {
    test('PF-01 cargar el carrito muestra líneas, total y cantidad de unidades', () async {
      final vm = _vm((request) async => http.Response(
            jsonEncode({'success': true, 'data': [_linea(), _linea(id: 2, cantidad: 1)], 'total': 75}),
            200,
          ));

      await vm.cargar();

      expect(vm.state.status, UiStatus.success);
      expect(vm.lineas, hasLength(2));
      expect(vm.total, 75.0);
      expect(vm.cantidadTotal, 3);
      vm.dispose();
    });

    test('PF-02 si el servidor no envía total se calcula con precio x cantidad', () async {
      final vm = _vm((request) async => http.Response(
            jsonEncode({'success': true, 'data': [_linea(cantidad: 3)]}), 200));
      await vm.cargar();
      expect(vm.total, 75.0);
      vm.dispose();
    });

    test('PF-03 un carrito sin productos queda en estado vacío', () async {
      final vm = _vm((request) async =>
          http.Response(jsonEncode({'success': true, 'data': []}), 200));
      await vm.cargar();
      expect(vm.state.status, UiStatus.empty);
      expect(vm.lineas, isEmpty);
      vm.dispose();
    });

    test('PF-04 no permite pedir más unidades que el stock y no llama al servidor', () async {
      var actualizaciones = 0;
      final vm = _vm((request) async {
        if (request.method == 'PUT') actualizaciones++;
        return http.Response(jsonEncode({'success': true, 'data': [_linea(stock: 2)]}), 200);
      });
      await vm.cargar();

      await vm.cambiarCantidad(vm.lineas.first, 5);

      expect(vm.error, 'No hay suficiente stock disponible.');
      expect(actualizaciones, 0);
      vm.dispose();
    });

    test('PF-05 agregar un producto recarga el carrito y confirma la acción', () async {
      final llamadas = <String>[];
      final vm = _vm((request) async {
        llamadas.add(request.method);
        return http.Response(jsonEncode({'success': true, 'data': [_linea()]}), 200);
      });

      await vm.agregar(3);

      expect(llamadas, ['POST', 'GET']);
      expect(vm.mensaje, 'Producto agregado al carrito.');
      vm.dispose();
    });

    test('PF-06 un error del servidor se muestra al usuario sin perder datos', () async {
      var falla = false;
      final vm = _vm((request) async => falla
          ? http.Response(jsonEncode({'message': 'Servidor no disponible'}), 503)
          : http.Response(jsonEncode({'success': true, 'data': [_linea()]}), 200));
      await vm.cargar();
      falla = true;

      await vm.cargar();

      expect(vm.state.hasError, isTrue);
      expect(vm.error, 'Servidor no disponible');
      expect(vm.lineas, hasLength(1));
      vm.dispose();
    });

    test('PF-07 confirmar pedido devuelve el pedido creado y vacía la vista', () async {
      final vm = _vm((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({
            'success': true,
            'message': 'Pedido creado exitosamente.',
            'pedido': {'id': 15, 'numero_pedido': 'DM-0015'},
          }), 201);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final pedido = await vm.confirmarPedido({'direccion_entrega': 'Av. Lima 123'});

      expect(pedido?['id'], 15);
      expect(vm.mensaje, 'Pedido creado exitosamente.');
      expect(vm.state.status, UiStatus.empty);
      vm.dispose();
    });

    test('PF-08 notifica a la interfaz al iniciar y al terminar la carga', () async {
      final vm = _vm((request) async =>
          http.Response(jsonEncode({'success': true, 'data': []}), 200));
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      await vm.cargar();

      expect(notificaciones, 2);
      vm.dispose();
    });
  });
}
