// Pruebas del cliente REST (ApiService) con un servidor simulado (MockClient).
import 'dart:convert';

import 'package:dulce_miel_flutter/network/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiService _api(MockClientHandler handler, {String? token = 'jwt-prueba'}) =>
    ApiService(
      baseUrl: 'https://example.test/api/',
      client: MockClient(handler),
      tokenProvider: () async => token,
    );

void main() {
  group('ApiService', () {
    test('PU-13 las rutas protegidas envían el token JWT como Bearer', () async {
      http.Request? recibida;
      final api = _api((request) async {
        recibida = request;
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      await api.consultarCarrito();

      expect(recibida!.url.toString(), 'https://example.test/api/carrito');
      expect(recibida!.headers['Authorization'], 'Bearer jwt-prueba');
    });

    test('PU-14 sin sesión no se llama al servidor y se pide iniciar sesión', () async {
      var llamadas = 0;
      final api = _api((request) async {
        llamadas++;
        return http.Response('{}', 200);
      }, token: null);

      await expectLater(
        api.consultarCarrito(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Inicia sesión para continuar.')),
      );
      expect(llamadas, 0);
    });

    test('PU-15 un error HTTP muestra el mensaje del servidor', () async {
      final api = _api((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'Stock insuficiente'}), 400));
      await expectLater(
        api.agregarAlCarrito(3, cantidad: 99),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Stock insuficiente')),
      );
    });

    test('PU-16 success=false con HTTP 200 también se trata como error', () async {
      final api = _api((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'Pedido inválido'}), 200));
      await expectLater(api.crearPedido({}), throwsA(isA<ApiException>()));
    });

    test('PU-17 una respuesta que no es JSON usa el código de estado', () async {
      final api = _api((request) async => http.Response('<html>Error</html>', 500));
      await expectLater(
        api.consultarPedidos(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('500'))),
      );
    });

    test('PU-18 actualizar con cantidad 0 elimina la línea del carrito', () async {
      final metodos = <String>[];
      final api = _api((request) async {
        metodos.add('${request.method} ${request.url.path}');
        return http.Response(jsonEncode({'success': true}), 200);
      });

      await api.actualizarCarrito(9, 0);

      expect(metodos, ['DELETE /api/carrito/9']);
    });

    test('PU-19 agregar al carrito envía producto, cantidad y envase en JSON', () async {
      Map<String, dynamic>? cuerpo;
      final api = _api((request) async {
        cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'success': true}), 200);
      });

      await api.agregarAlCarrito(3, cantidad: 2, opcionEnvaseId: 1);

      expect(cuerpo, {'producto_id': 3, 'cantidad': 2, 'opcion_envase_id': 1});
    });
  });
}
