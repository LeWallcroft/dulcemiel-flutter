class Coordenada {
  const Coordenada({required this.latitud, required this.longitud});

  final double latitud;
  final double longitud;

  bool get esValida =>
      latitud >= -90 && latitud <= 90 && longitud >= -180 && longitud <= 180;
}
