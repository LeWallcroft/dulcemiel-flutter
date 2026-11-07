class ContenidoTienda {
  const ContenidoTienda({
    required this.nombre,
    required this.descripcion,
    required this.mision,
    required this.vision,
    required this.logoUrl,
    required this.carrusel,
    required this.promociones,
    this.direccionEnvases,
    this.receptorEnvases,
    this.telefonoEnvases,
  });

  final String nombre;
  final String descripcion;
  final String mision;
  final String vision;
  final String? logoUrl;
  final List<CarruselTienda> carrusel;
  final List<PromocionTienda> promociones;
  final String? direccionEnvases;
  final String? receptorEnvases;
  final String? telefonoEnvases;

  factory ContenidoTienda.fromJson(Map<String, dynamic> json) {
    final config = json['configuracion'] is Map<String, dynamic>
        ? json['configuracion'] as Map<String, dynamic>
        : <String, dynamic>{};
    return ContenidoTienda(
      nombre: config['nombre_empresa']?.toString() ?? 'Dulce Miel',
      descripcion:
          config['descripcion_inicio']?.toString() ??
          'Explora nuestra selección de miel y productos apícolas.',
      mision: config['mision']?.toString() ?? '',
      vision: config['vision']?.toString() ?? '',
      logoUrl: config['logo_url']?.toString(),
      carrusel: (json['carrusel'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CarruselTienda.fromJson)
          .toList(growable: false),
      promociones: (json['promociones'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PromocionTienda.fromJson)
          .toList(growable: false),
      direccionEnvases: config['direccion_envases']?.toString(),
      receptorEnvases: config['receptor_envases']?.toString(),
      telefonoEnvases: config['telefono_envases']?.toString(),
    );
  }
}

class CarruselTienda {
  const CarruselTienda({
    required this.titulo,
    required this.descripcion,
    this.imagenUrl,
  });
  final String titulo;
  final String descripcion;
  final String? imagenUrl;

  factory CarruselTienda.fromJson(Map<String, dynamic> json) => CarruselTienda(
    titulo: json['titulo']?.toString() ?? '',
    descripcion: json['descripcion']?.toString() ?? '',
    imagenUrl: json['imagen_url']?.toString(),
  );
}

class PromocionTienda {
  const PromocionTienda({
    required this.titulo,
    required this.descripcion,
    required this.descuento,
  });
  final String titulo;
  final String descripcion;
  final String descuento;

  factory PromocionTienda.fromJson(Map<String, dynamic> json) =>
      PromocionTienda(
        titulo: json['titulo']?.toString() ?? '',
        descripcion: json['descripcion']?.toString() ?? '',
        descuento: json['descuento_porcentaje']?.toString() ?? '0',
      );
}
