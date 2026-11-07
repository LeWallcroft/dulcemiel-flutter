import 'package:flutter/foundation.dart';

import '../network/api_service.dart';
import '../repositories/administracion_repository.dart';

class AdministracionViewModel extends ChangeNotifier {
  AdministracionViewModel(this._repository);
  final AdministracionRepository _repository;

  Map<String, dynamic> resumen = {};
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> promociones = [];
  List<Map<String, dynamic>> usuarios = [];
  Map<String, dynamic> sitio = {};
  bool cargando = false;
  bool ocupado = false;
  String? error;
  String? mensaje;

  void limpiarAviso() {
    error = null;
    mensaje = null;
    notifyListeners();
  }

  Future<void> cargarTodo() async {
    if (cargando) return;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.cargarResumen(),
        _repository.cargarProductos(),
        _repository.cargarPedidos(),
        _repository.cargarPromociones(),
        _repository.cargarUsuarios(),
        _repository.cargarSitio(),
      ]);
      resumen = values[0] as Map<String, dynamic>;
      productos = values[1] as List<Map<String, dynamic>>;
      pedidos = values[2] as List<Map<String, dynamic>>;
      promociones = values[3] as List<Map<String, dynamic>>;
      usuarios = values[4] as List<Map<String, dynamic>>;
      sitio = values[5] as Map<String, dynamic>;
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No se pudo cargar la administración.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> _mutar(
    Future<void> Function() accion, {
    String ok = 'Cambios guardados.',
  }) async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    mensaje = null;
    notifyListeners();
    try {
      await accion();
      mensaje = ok;
      await cargarTodo();
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No se pudo completar la operación.';
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }

  Future<void> guardarProducto({
    int? id,
    required Map<String, String> campos,
    String? imagePath,
  }) => _mutar(
    () => _repository.guardarProducto(
      id: id,
      campos: campos,
      imagePath: imagePath,
    ),
    ok: id == null ? 'Producto creado.' : 'Producto actualizado.',
  );
  Future<void> eliminarProducto(int id) =>
      _mutar(() => _repository.eliminarProducto(id), ok: 'Producto eliminado.');
  Future<void> actualizarPedido(int id, String estado) => _mutar(
    () => _repository.actualizarPedido(id, estado),
    ok: 'Estado del pedido actualizado.',
  );
  Future<void> registrarEnvioPedido({
    required int id,
    required Map<String, String> fields,
    required String imagePath,
  }) => _mutar(
    () => _repository.registrarEnvioPedido(
      id: id,
      fields: fields,
      imagePath: imagePath,
    ),
    ok: 'Envío registrado y pedido marcado como enviado.',
  );
  Future<void> guardarPromocion({
    int? id,
    required Map<String, dynamic> body,
  }) => _mutar(
    () => _repository.guardarPromocion(id: id, body: body),
    ok: id == null ? 'Promoción creada.' : 'Promoción actualizada.',
  );
  Future<void> eliminarPromocion(int id) => _mutar(
    () => _repository.eliminarPromocion(id),
    ok: 'Promoción eliminada.',
  );
  Future<void> crearEmpleado(Map<String, dynamic> body) => _mutar(
    () => _repository.crearEmpleado(body),
    ok: 'Acceso del empleado creado.',
  );
  Future<void> actualizarUsuario(int id, Map<String, dynamic> body) => _mutar(
    () => _repository.actualizarUsuario(id, body),
    ok: 'Usuario actualizado.',
  );
  Future<void> guardarSitio(Map<String, String> fields, {String? logoPath}) =>
      _mutar(
        () => _repository.guardarSitio(fields, logoPath: logoPath),
        ok: 'Contenido de la tienda actualizado.',
      );
  Future<void> guardarSlide({
    int? id,
    required Map<String, String> fields,
    String? imagePath,
  }) => _mutar(
    () =>
        _repository.guardarSlide(id: id, fields: fields, imagePath: imagePath),
    ok: 'Carrusel actualizado.',
  );
  Future<void> eliminarSlide(int id) => _mutar(
    () => _repository.eliminarSlide(id),
    ok: 'Imagen del carrusel eliminada.',
  );
}
