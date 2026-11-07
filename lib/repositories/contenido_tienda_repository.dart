import '../models/contenido_tienda.dart';
import '../network/api_service.dart';

class ContenidoTiendaRepository {
  const ContenidoTiendaRepository(this._api);
  final ApiService _api;

  Future<ContenidoTienda> cargar() async =>
      ContenidoTienda.fromJson(await _api.consultarSitioPublico());
}
