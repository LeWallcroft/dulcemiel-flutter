import 'dart:convert';

import '../local/local_cache_database.dart';
import '../models/contenido_tienda.dart';
import '../network/api_service.dart';

class ContenidoTiendaSnapshot {
  const ContenidoTiendaSnapshot({
    required this.contenido,
    required this.desdeCache,
  });

  final ContenidoTienda contenido;
  final bool desdeCache;
}

class ContenidoTiendaRepository {
  ContenidoTiendaRepository(this._api, {JsonCacheStore? cache})
    : _cache = cache ?? LocalCacheDatabase.instance;

  final ApiService _api;
  final JsonCacheStore _cache;
  static const _cacheKey = 'contenido_tienda_publico_v1';

  Future<ContenidoTiendaSnapshot> cargar() async {
    try {
      final response = await _api.consultarSitioPublico();
      try {
        await _cache.write(_cacheKey, jsonEncode(response));
      } catch (_) {
        // La información de red sigue siendo utilizable aunque SQLite falle.
      }
      return ContenidoTiendaSnapshot(
        contenido: ContenidoTienda.fromJson(response),
        desdeCache: false,
      );
    } catch (error) {
      try {
        final encoded = await _cache.read(_cacheKey);
        if (encoded != null) {
          final decoded = jsonDecode(encoded);
          if (decoded is Map<String, dynamic>) {
            return ContenidoTiendaSnapshot(
              contenido: ContenidoTienda.fromJson(decoded),
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
}
