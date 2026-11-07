class SesionUsuario {
  const SesionUsuario({
    required this.tokenApi,
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final String tokenApi;
  final int id;
  final String nombre;
  final String email;
  final String rol;

  factory SesionUsuario.fromJson(Map<String, dynamic> json) {
    return SesionUsuario(
      tokenApi: json['tokenApi'] as String,
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'usuario',
    );
  }

  Map<String, dynamic> toJson() => {
    'tokenApi': tokenApi,
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
  };

  factory SesionUsuario.fromApi({
    required String token,
    required Map<String, dynamic> usuario,
  }) => SesionUsuario(
    tokenApi: token,
    id: (usuario['id'] as num).toInt(),
    nombre: usuario['nombre']?.toString() ?? '',
    email: usuario['email']?.toString() ?? '',
    rol: usuario['rol']?.toString() ?? 'usuario',
  );
}
