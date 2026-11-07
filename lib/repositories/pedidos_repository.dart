import '../models/pedido.dart';
import '../network/api_service.dart';

class PedidosRepository {
  const PedidosRepository(this._api);
  final ApiService _api;

  Future<List<Pedido>> cargarPedidos() async => (await _api.consultarPedidos())
      .map(Pedido.fromJson)
      .toList(growable: false);

  Future<DetallePedido> cargarDetalle(int id) async {
    final json = await _api.consultarDetallePedido(id);
    final pedido = json['pedido'];
    final detalles = json['detalles'];
    if (pedido is! Map<String, dynamic> || detalles is! List) {
      throw const ApiException(
        'El servidor devolvió un detalle de pedido inválido.',
      );
    }
    return DetallePedido(
      pedido: Pedido.fromJson(pedido),
      lineas: detalles
          .whereType<Map<String, dynamic>>()
          .map(LineaPedido.fromJson)
          .toList(growable: false),
    );
  }

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
