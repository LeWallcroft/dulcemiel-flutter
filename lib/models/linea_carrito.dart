import 'producto.dart';

class LineaCarrito {
  const LineaCarrito({
    required this.id,
    required this.producto,
    required this.cantidad,
    required this.envase,
    required this.costoEnvaseUnitario,
  });
  final int id;
  final Producto producto;
  final int cantidad;
  final OpcionEnvase envase;
  final double costoEnvaseUnitario;

  factory LineaCarrito.fromJson(Map<String, dynamic> json) => LineaCarrito(
    id: (json['id'] as num).toInt(),
    cantidad: (json['cantidad'] as num).toInt(),
    envase: OpcionEnvase.fromJson({
      'id': json['opcion_envase_id'],
      'codigo': json['envase_codigo'],
      'nombre': json['envase_nombre'],
      'descripcion': json['envase_descripcion'],
      'costo_extra': json['costo_envase_unitario'],
    }),
    costoEnvaseUnitario:
        double.tryParse('${json['costo_envase_unitario']}') ?? 0,
    producto: Producto(
      id: (json['producto_id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: '',
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 2147483647,
      categoria: '',
      imagenUrl: json['imagen_url']?.toString(),
    ),
  );
}
