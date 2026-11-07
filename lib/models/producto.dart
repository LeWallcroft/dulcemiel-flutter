class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    this.imagenUrl,
    this.opcionesEnvase = const [],
    this.informacionOds12 = '',
    this.metaOds12,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final String? imagenUrl;
  final List<OpcionEnvase> opcionesEnvase;
  final String informacionOds12;
  final String? metaOds12;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      categoria: json['categoria']?.toString() ?? '',
      imagenUrl: json['imagen_url']?.toString(),
      opcionesEnvase: (json['opciones_envase'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OpcionEnvase.fromJson)
          .toList(growable: false),
      informacionOds12: json['informacion_ods12']?.toString() ?? '',
      metaOds12: json['meta_ods12']?.toString(),
    );
  }
}

class OpcionEnvase {
  const OpcionEnvase({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.costoExtra,
    this.id,
  });

  final int? id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final double costoExtra;
  bool get usaFrascoCliente => codigo == 'frasco_cliente';

  factory OpcionEnvase.fromJson(Map<String, dynamic> json) => OpcionEnvase(
    id: (json['id'] as num?)?.toInt(),
    codigo: json['codigo']?.toString() ?? 'convencional',
    nombre: json['nombre']?.toString() ?? 'Envase convencional',
    descripcion: json['descripcion']?.toString() ?? '',
    costoExtra: double.tryParse('${json['costo_extra']}') ?? 0,
  );
}
