import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/coordenada.dart';
import '../models/ui_state.dart';
import '../repositories/ubicacion_repository.dart';

class UbicacionViewModel extends ChangeNotifier {
  UbicacionViewModel(this._repository);
  final UbicacionRepository _repository;
  UiState<Coordenada> state = UiState.initial();
  LocationIssue? issue;

  void seleccionar(Coordenada value) {
    state = UiState.success(value);
    issue = null;
    notifyListeners();
  }

  Future<void> usarUbicacionActual() async {
    state = UiState.loading(previous: state.data);
    issue = null;
    notifyListeners();
    try {
      state = UiState.success(await _repository.obtenerActual());
    } on LocationException catch (error) {
      issue = error.issue;
      state = UiState.error(_mensaje(error.issue), previous: state.data);
    } catch (_) {
      state = UiState.error(
        'No se pudo obtener la ubicación. Puedes marcarla manualmente en el mapa.',
      );
    }
    notifyListeners();
  }

  Future<void> abrirConfiguracionPermisos() async {
    await Geolocator.openAppSettings();
  }

  Future<void> abrirConfiguracionUbicacion() async {
    await Geolocator.openLocationSettings();
  }

  String _mensaje(LocationIssue issue) => switch (issue) {
    LocationIssue.serviceDisabled =>
      'Activa los servicios de ubicación o marca el punto manualmente.',
    LocationIssue.denied =>
      'Se denegó el permiso. Puedes marcar la dirección manualmente.',
    LocationIssue.deniedForever => 'El permiso está bloqueado. Actívalo en Ajustes o selecciona el punto manualmente.',
  };
}
