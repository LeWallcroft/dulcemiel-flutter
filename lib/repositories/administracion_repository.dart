import '../network/api_service.dart';

class AdministracionRepository {
  const AdministracionRepository(this._api);
  final ApiService _api;

  Future<Map<String, dynamic>> cargarResumen() => _api.consultarDashboard();
  Future<List<Map<String, dynamic>>> cargarProductos() =>
      _api.consultarProductosAdministrativos();
  Future<List<Map<String, dynamic>>> cargarPedidos() =>
      _api.consultarPedidosAdministrativos();
  Future<List<Map<String, dynamic>>> cargarPromociones() =>
      _api.consultarPromocionesAdministrativas();
  Future<List<Map<String, dynamic>>> cargarUsuarios() =>
      _api.consultarUsuariosAdministrativos();
  Future<Map<String, dynamic>> cargarSitio() => _api.consultarSitioPublico();

  Future<void> guardarProducto({
    int? id,
    required Map<String, String> campos,
    String? imagePath,
  }) => _api.guardarProductoAdministrativo(
    id: id,
    campos: campos,
    imagePath: imagePath,
  );
  Future<void> eliminarProducto(int id) =>
      _api.eliminarProductoAdministrativo(id);
  Future<void> actualizarPedido(int id, String estado) =>
      _api.actualizarEstadoPedidoAdministrativo(id, estado);
  Future<void> registrarEnvioPedido({
    required int id,
    required Map<String, String> fields,
    required String imagePath,
  }) => _api.registrarEnvioPedidoAdministrativo(
    pedidoId: id,
    fields: fields,
    imagePath: imagePath,
  );
  Future<void> guardarPromocion({
    int? id,
    required Map<String, dynamic> body,
  }) => _api.guardarPromocionAdministrativa(id: id, body: body);
  Future<void> eliminarPromocion(int id) =>
      _api.eliminarPromocionAdministrativa(id);
  Future<void> crearEmpleado(Map<String, dynamic> body) =>
      _api.crearEmpleadoAdministrativo(body);
  Future<void> actualizarUsuario(int id, Map<String, dynamic> body) =>
      _api.actualizarUsuarioAdministrativo(id, body);
  Future<void> guardarSitio(Map<String, String> fields, {String? logoPath}) =>
      _api.guardarConfiguracionSitio(fields, logoPath: logoPath);
  Future<void> guardarSlide({
    int? id,
    required Map<String, String> fields,
    String? imagePath,
  }) => _api.guardarCarrusel(id: id, fields: fields, imagePath: imagePath);
  Future<void> eliminarSlide(int id) => _api.eliminarCarrusel(id);
}
