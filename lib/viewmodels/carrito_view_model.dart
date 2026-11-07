import 'package:flutter/foundation.dart';

import '../models/linea_carrito.dart';
import '../network/api_service.dart';
import '../repositories/carrito_repository.dart';

class CarritoViewModel extends ChangeNotifier {
  CarritoViewModel(this._repository);
  final CarritoRepository _repository;
  List<LineaCarrito> lineas = const [];
  double total = 0;
  bool cargando = false;
  bool ocupado = false;
  String? error;
  String? mensaje;
  int get cantidadTotal =>
      lineas.fold<int>(0, (sum, linea) => sum + linea.cantidad);

  void limpiarLocal() {
    lineas = const [];
    total = 0;
    error = null;
    mensaje = null;
    notifyListeners();
  }

  Future<void> cargar() async {
    if (cargando) return;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final result = await _repository.cargar();
      lineas = result.lineas;
      total = result.total;
    } catch (e) {
      error = e is ApiException ? e.message : 'No se pudo cargar el carrito.';
    } finally {
      cargando = false;
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
      error = 'No hay suficiente stock disponible.';
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
    ocupado = true;
    error = null;
    mensaje = null;
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
      mensaje =
          response['message']?.toString() ?? 'Pedido creado exitosamente.';
      return pedido;
    } catch (e) {
      error = e is ApiException ? e.message : 'No se pudo registrar el pedido.';
      return null;
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }

  Future<void> _operar(Future<void> Function() action, String success) async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    mensaje = null;
    notifyListeners();
    try {
      await action();
      await cargar();
      mensaje = success;
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No se pudo actualizar el carrito.';
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }
}
