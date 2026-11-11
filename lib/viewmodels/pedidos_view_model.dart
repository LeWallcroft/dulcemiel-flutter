import 'package:flutter/foundation.dart';

import '../models/pedido.dart';
import '../models/ui_state.dart';
import '../network/api_service.dart';
import '../repositories/pedidos_repository.dart';

class PedidosViewModel extends ChangeNotifier {
  PedidosViewModel(this._repository);
  final PedidosRepository _repository;
  UiState<List<Pedido>> state = UiState.initial();
  UiState<DetallePedido> detailState = UiState.initial();
  UiState<String> actionState = UiState.initial();
  List<Pedido> get pedidos => state.data ?? const [];
  DetallePedido? get detalle => detailState.data;
  bool get cargando => state.isLoading || detailState.isLoading;
  String? get error => actionState.hasError
      ? actionState.message
      : detailState.hasError
      ? detailState.message
      : state.hasError
      ? state.message
      : null;

  Future<void> cargar() async {
    if (state.isLoading) return;
    state = UiState.loading(previous: state.data);
    notifyListeners();
    try {
      final result = await _repository.cargarPedidos();
      state = result.isEmpty ? UiState.empty(result) : UiState.success(result);
    } catch (e) {
      state = UiState.error(
        e is ApiException ? e.message : 'No se pudo cargar tu historial.',
        previous: state.data,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int id) async {
    detailState = UiState.loading(previous: detailState.data);
    notifyListeners();
    try {
      detailState = UiState.success(await _repository.cargarDetalle(id));
    } catch (e) {
      detailState = UiState.error(
        e is ApiException
            ? e.message
            : 'No se pudo cargar el detalle del pedido.',
        previous: detailState.data,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> enviarBoletaEnvase({
    required int pedidoId,
    required Map<String, String> fields,
    required String imagePath,
  }) async {
    actionState = UiState.loading(previous: actionState.data);
    notifyListeners();
    try {
      await _repository.enviarBoletaEnvase(
        pedidoId: pedidoId,
        fields: fields,
        imagePath: imagePath,
      );
      final updated = await _repository.cargarDetalle(pedidoId);
      detailState = UiState.success(updated);
      actionState = UiState.success('Comprobante guardado.');
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'No se pudo guardar la boleta del frasco.';
      actionState = UiState.error(message);
    } finally {
      notifyListeners();
    }
  }
}
