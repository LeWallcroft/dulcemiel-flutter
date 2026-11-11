import 'dart:convert';

import 'package:dulce_miel_flutter/models/ui_state.dart';
import 'package:dulce_miel_flutter/network/api_service.dart';
import 'package:dulce_miel_flutter/repositories/catalogo_repository.dart';
import 'package:dulce_miel_flutter/local/local_cache_database.dart';
import 'package:dulce_miel_flutter/viewmodels/catalogo_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryCache implements JsonCacheStore {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
}

void main() {
  group('Catálogo API y caché local', () {
    test(
      'Repository guarda la respuesta REST y puede recuperarla sin red',
      () async {
        final cache = _MemoryCache();
        final api = ApiService(
          baseUrl: 'https://example.test/api/',
          client: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'success': true,
                'data': [_productoJson],
              }),
              200,
            ),
          ),
        );
        final repository = CatalogoRepository(api, cache: cache);

        final online = await repository.cargarProductos();
        expect(online.desdeCache, isFalse);
        expect(online.productos.single.nombre, 'Miel multifloral');
        expect(cache.value, isNotNull);

        final offlineApi = ApiService(
          baseUrl: 'https://example.test/api/',
          client: MockClient(
            (request) async => http.Response('sin conexión', 503),
          ),
        );
        final offline = await CatalogoRepository(
          offlineApi,
          cache: cache,
        ).cargarProductos();
        expect(offline.desdeCache, isTrue);
        expect(offline.productos.single.id, 7);
      },
    );

    test('ViewModel representa la respuesta vacía con estado empty', () async {
      final api = ApiService(
        baseUrl: 'https://example.test/api/',
        client: MockClient(
          (request) async =>
              http.Response(jsonEncode({'success': true, 'data': []}), 200),
        ),
      );
      final vm = CatalogoViewModel(
        CatalogoRepository(api, cache: _MemoryCache()),
      );

      await vm.cargar();

      expect(vm.state.status, UiStatus.empty);
      expect(vm.productos, isEmpty);
      vm.dispose();
    });
  });
}

const _productoJson = {
  'id': 7,
  'nombre': 'Miel multifloral',
  'descripcion': 'Miel de la colmena',
  'precio': 28.0,
  'stock': 4,
  'categoria': 'Miel',
};
