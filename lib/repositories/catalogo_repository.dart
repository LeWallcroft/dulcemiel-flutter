import '../models/producto.dart';
import '../network/api_service.dart';

class CatalogoRepository {
  const CatalogoRepository(this._apiService);

  final ApiService _apiService;

  Future<List<Producto>> cargarProductos() async {
    final registros = await _apiService.consultarProductos();
    return registros.map(Producto.fromJson).toList(growable: false);
  }
}
