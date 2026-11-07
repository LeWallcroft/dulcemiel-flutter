class PerfilUsuario {
  const PerfilUsuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.estado,
    this.fechaCreacion,
  });
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? estado;
  final String? fechaCreacion;

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) => PerfilUsuario(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    rol: json['rol']?.toString() ?? 'usuario',
    estado: json['estado']?.toString(),
    fechaCreacion: json['fecha_creacion']?.toString(),
  );
}
