import 'package:flutter/foundation.dart';

import '../models/ui_state.dart';
import '../network/api_service.dart';

class InicioViewModel extends ChangeNotifier {
  InicioViewModel(this._apiService);

  final ApiService _apiService;
  UiState<String> state = UiState.initial();

  String? get mensaje => state.message ?? state.data;

  Future<void> verificarApi() async {
    state = UiState.loading(previous: state.data);
    notifyListeners();

    try {
      final respuesta = await _apiService.consultarSalud();
      final message =
          respuesta['message']?.toString() ?? 'Servidor disponible.';
      state = respuesta['success'] == true
          ? UiState.success(message)
          : UiState.error(message, previous: state.data);
    } catch (error) {
      state = UiState.error(
        error is ApiException ? error.message : 'No se pudo conectar con el servidor. Verifica la red y vuelve a intentar.',
        previous: state.data,
      );
    }
    notifyListeners();
  }
}
