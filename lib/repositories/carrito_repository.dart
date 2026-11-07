import '../models/linea_carrito.dart';
import '../network/api_service.dart';

class CarritoRepository {
  const CarritoRepository(this._api);
  final ApiService _api;

  Future<({List<LineaCarrito> lineas, double total})> cargar() async {
    final body = await _api.consultarCarrito();
    final raw = body['data'];
    if (raw is! List) {
      throw const ApiException('El servidor devolvió un carrito inválido.');
    }
    final lineas = raw
        .whereType<Map<String, dynamic>>()
        .map(LineaCarrito.fromJson)
        .toList(growable: false);
    final totalValue = body['total'];
    return (
      lineas: lineas,
      total:
          double.tryParse('$totalValue') ??
          lineas.fold<double>(
            0,
            (sum, line) => sum + line.producto.precio * line.cantidad,
          ),
    );
  }

  Future<void> agregar(
    int productId, {
    int cantidad = 1,
    int? opcionEnvaseId,
  }) => _api.agregarAlCarrito(
    productId,
    cantidad: cantidad,
    opcionEnvaseId: opcionEnvaseId,
  );
  Future<void> actualizar(int cartId, int quantity) =>
      _api.actualizarCarrito(cartId, quantity);
  Future<void> eliminar(int cartId) => _api.eliminarDelCarrito(cartId);
  Future<void> vaciar() => _api.vaciarCarrito();
  Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> entrega) =>
      _api.crearPedido(entrega);

  Future<void> enviarBoletaEnvase({
    required int pedidoId,
    required Map<String, String> fields,
    required String imagePath,
  }) => _api.enviarBoletaEnvase(
    pedidoId: pedidoId,
    fields: fields,
    imagePath: imagePath,
  );
}
