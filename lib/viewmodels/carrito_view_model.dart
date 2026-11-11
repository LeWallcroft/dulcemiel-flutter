import 'package:flutter/foundation.dart';

import '../models/linea_carrito.dart';
import '../models/ui_state.dart';
import '../network/api_service.dart';
import '../repositories/carrito_repository.dart';

class CarritoViewModel extends ChangeNotifier {
  CarritoViewModel(this._repository);
  final CarritoRepository _repository;
  UiState<({List<LineaCarrito> lineas, double total})> state =
      UiState.initial();
  UiState<String> actionState = UiState.initial();
  List<LineaCarrito> get lineas => state.data?.lineas ?? const [];
  double get total => state.data?.total ?? 0;
  bool get cargando => state.isLoading;
  bool get ocupado => actionState.isLoading;
  String? get error => actionState.hasError
      ? actionState.message
      : state.hasError
      ? state.message
      : null;
  String? get mensaje => actionState.isSuccess ? actionState.data : null;
  int get cantidadTotal =>
      lineas.fold<int>(0, (sum, linea) => sum + linea.cantidad);

  void limpiarLocal() {
    state = UiState.empty((lineas: const [], total: 0));
    actionState = UiState.initial();
    notifyListeners();
  }

  Future<void> cargar() async {
    if (cargando) return;
    state = UiState.loading(previous: state.data);
    notifyListeners();
    try {
      final result = await _repository.cargar();
      state = result.lineas.isEmpty
          ? UiState.empty(result)
          : UiState.success(result);
    } catch (e) {
      state = UiState.error(
        e is ApiException ? e.message : 'No se pudo cargar el carrito.',
        previous: state.data,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> agregar(
    int productId, {
    int cantidad = 1,
    int? opcionEnvaseId,
  }) => _operar(
    () => _repository.agregar(
      productId,
      cantidad: cantidad,
      opcionEnvaseId: opcionEnvaseId,
    ),
    'Producto agregado al carrito.',
  );
  Future<void> cambiarCantidad(LineaCarrito linea, int cantidad) async {
    if (cantidad > linea.producto.stock) {
      actionState = UiState.error('No hay suficiente stock disponible.');
      notifyListeners();
      return;
    }
    await _operar(
      () => _repository.actualizar(linea.id, cantidad),
      'Carrito actualizado.',
    );
  }

  Future<void> eliminar(LineaCarrito linea) =>
      _operar(() => _repository.eliminar(linea.id), 'Producto eliminado.');
  Future<void> vaciar() => _operar(_repository.vaciar, 'Carrito vaciado.');

  Future<Map<String, dynamic>?> confirmarPedido(
    Map<String, dynamic> entrega, {
    Map<String, String>? envioEnvase,
    String? boletaEnvasePath,
  }) async {
    if (ocupado) return null;
    actionState = UiState.loading(previous: actionState.data);
    notifyListeners();
    try {
      final response = await _repository.crearPedido(entrega);
      final pedido = response['pedido'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              response['pedido'] as Map<String, dynamic>,
            )
          : <String, dynamic>{};
      if (envioEnvase != null &&
          boletaEnvasePath != null &&
          pedido['id'] is num) {
        try {
          await _repository.enviarBoletaEnvase(
            pedidoId: (pedido['id'] as num).toInt(),
            fields: envioEnvase,
            imagePath: boletaEnvasePath,
          );
        } catch (error) {
          pedido['guia_envase_pendiente'] = true;
          pedido['mensaje_guia_pendiente'] = error is ApiException
              ? error.message
              : 'Pedido creado; falta guardar la boleta del frasco. Puedes adjuntarla desde el detalle del pedido.';
        }
      }
      await cargar();
      actionState = UiState.success(
        response['message']?.toString() ?? 'Pedido creado exitosamente.',
      );
      return pedido;
    } catch (e) {
      actionState = UiState.error(
        e is ApiException ? e.message : 'No se pudo registrar el pedido.',
      );
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _operar(Future<void> Function() action, String success) async {
    if (ocupado) return;
    actionState = UiState.loading(previous: actionState.data);
    notifyListeners();
    try {
      await action();
      await cargar();
      actionState = UiState.success(success);
    } catch (e) {
      actionState = UiState.error(
        e is ApiException ? e.message : 'No se pudo actualizar el carrito.',
      );
    } finally {
      notifyListeners();
    }
  }
}
