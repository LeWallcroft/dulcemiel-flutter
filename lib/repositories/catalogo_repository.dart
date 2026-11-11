import 'dart:convert';

import '../local/local_cache_database.dart';
import '../models/producto.dart';
import '../network/api_service.dart';

class CatalogoSnapshot {
  const CatalogoSnapshot({required this.productos, required this.desdeCache});

  final List<Producto> productos;
  final bool desdeCache;
}

class CatalogoRepository {
  CatalogoRepository(this._apiService, {JsonCacheStore? cache})
    : _cache = cache ?? LocalCacheDatabase.instance;

  final ApiService _apiService;
  final JsonCacheStore _cache;
  static const _cacheKey = 'catalogo_publico_v1';

  Future<CatalogoSnapshot> cargarProductos() async {
    try {
      final registros = await _apiService.consultarProductos();
      try {
        await _cache.write(_cacheKey, jsonEncode(registros));
      } catch (_) {
        // Un fallo de caché no debe ocultar una respuesta válida del servidor.
      }
      return CatalogoSnapshot(
        productos: _parsear(registros),
        desdeCache: false,
      );
    } catch (error) {
      try {
        final encoded = await _cache.read(_cacheKey);
        if (encoded != null) {
          final decoded = jsonDecode(encoded);
          if (decoded is List) {
            return CatalogoSnapshot(
              productos: _parsear(
                decoded.whereType<Map<String, dynamic>>().toList(),
              ),
              desdeCache: true,
            );
          }
        }
      } catch (_) {
        // Si el caché falta o está corrupto, se conserva el error original.
      }
      rethrow;
    }
  }

  List<Producto> _parsear(List<Map<String, dynamic>> registros) =>
      registros.map(Producto.fromJson).toList(growable: false);
}
