import 'package:flutter/foundation.dart';

import '../models/pedido.dart';
import '../network/api_service.dart';
import '../repositories/pedidos_repository.dart';

class PedidosViewModel extends ChangeNotifier {
  PedidosViewModel(this._repository);
  final PedidosRepository _repository;
  List<Pedido> pedidos = const [];
  DetallePedido? detalle;
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    if (cargando) return;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      pedidos = await _repository.cargarPedidos();
    } catch (e) {
      error = e is ApiException ? e.message : 'No se pudo cargar tu historial.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int id) async {
    cargando = true;
    detalle = null;
    error = null;
    notifyListeners();
    try {
      detalle = await _repository.cargarDetalle(id);
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No se pudo cargar el detalle del pedido.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> enviarBoletaEnvase({
    required int pedidoId,
    required Map<String, String> fields,
    required String imagePath,
  }) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      await _repository.enviarBoletaEnvase(
        pedidoId: pedidoId,
        fields: fields,
        imagePath: imagePath,
      );
      detalle = await _repository.cargarDetalle(pedidoId);
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No se pudo guardar la boleta del frasco.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
