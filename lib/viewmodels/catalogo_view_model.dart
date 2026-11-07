import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../network/api_service.dart';
import '../repositories/catalogo_repository.dart';

class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel(CatalogoRepository repository) : _repository = repository;

  final CatalogoRepository _repository;
  List<Producto> _productos = const [];
  bool _cargando = false;
  bool _cargado = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  bool get cargado => _cargado;
  String? get error => _error;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _productos = await _repository.cargarProductos();
      _cargado = true;
    } on ApiException catch (exception) {
      _error = exception.message;
      _cargado = false;
    } catch (_) {
      _error = 'No se pudo cargar el catálogo. Revisa la conexión y reintenta.';
      _cargado = false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
