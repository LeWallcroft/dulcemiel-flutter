import 'package:geolocator/geolocator.dart';

import '../models/coordenada.dart';

enum LocationIssue { serviceDisabled, denied, deniedForever }

class LocationException implements Exception {
  const LocationException(this.issue);
  final LocationIssue issue;
}

class UbicacionRepository {
  Future<Coordenada> obtenerActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationIssue.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationIssue.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationIssue.deniedForever);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return Coordenada(latitud: position.latitude, longitud: position.longitude);
  }
}
