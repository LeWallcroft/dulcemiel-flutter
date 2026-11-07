import 'package:flutter/foundation.dart';

import '../models/estado_api.dart';
import '../network/api_service.dart';

class InicioViewModel extends ChangeNotifier {
  InicioViewModel(this._apiService);

  final ApiService _apiService;
  EstadoApi _estado = EstadoApi.inicial;
  String? _mensaje;

  EstadoApi get estado => _estado;
  String? get mensaje => _mensaje;

  Future<void> verificarApi() async {
    _estado = EstadoApi.cargando;
    _mensaje = null;
    notifyListeners();

    try {
      final respuesta = await _apiService.consultarSalud();
      _mensaje = respuesta['message']?.toString() ?? 'Servidor disponible.';
      _estado = respuesta['success'] == true
          ? EstadoApi.disponible
          : EstadoApi.error;
    } catch (error) {
      _mensaje = error is ApiException ? error.message : 'No se pudo conectar con el servidor. Verifica la red y vuelve a intentar.';
      _estado = EstadoApi.error;
    }
    notifyListeners();
  }
}
