import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({http.Client? client, required this.baseUrl, this.tokenProvider})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Future<String?> Function()? tokenProvider;

  Future<Map<String, dynamic>> consultarCarrito() =>
      _authenticated('GET', 'carrito');

  Future<void> agregarAlCarrito(
    int productoId, {
    int cantidad = 1,
    int? opcionEnvaseId,
  }) async {
    await _authenticated(
      'POST',
      'carrito/agregar',
      body: {
        'producto_id': productoId,
        'cantidad': cantidad,
        'opcion_envase_id': ?opcionEnvaseId,
      },
    );
  }

  Future<void> actualizarCarrito(int carritoId, int cantidad) async {
    if (cantidad <= 0) {
      await eliminarDelCarrito(carritoId);
      return;
    }
    await _authenticated(
      'PUT',
      'carrito/actualizar',
      body: {'carrito_id': carritoId, 'cantidad': cantidad},
    );
  }

  Future<void> eliminarDelCarrito(int carritoId) async {
    await _authenticated('DELETE', 'carrito/$carritoId');
  }

  Future<void> vaciarCarrito() async => _authenticated('DELETE', 'carrito');

  Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> entrega) =>
      _authenticated('POST', 'pedidos', body: entrega);

  Future<List<Map<String, dynamic>>> consultarPedidos() async {
    final body = await _authenticated('GET', 'pedidos');
    final data = body['data'];
    if (data is! List) {
      throw const ApiException('El servidor devolvió un historial inválido.');
    }
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> consultarDetallePedido(int id) =>
      _authenticated('GET', 'pedidos/$id');

  Future<Map<String, dynamic>> consultarPerfil() =>
      _authenticated('GET', 'auth/perfil');

  Future<Map<String, dynamic>> consultarDashboard() =>
      _authenticated('GET', 'dashboard/resumen');

  Future<List<Map<String, dynamic>>>
  consultarProductosAdministrativos() async => _listData(
    await _authenticated('GET', 'productos/admin/todos'),
    'productos',
  );

  Future<List<Map<String, dynamic>>> consultarPedidosAdministrativos() async =>
      _listData(await _authenticated('GET', 'pedidos/admin/todos'), 'pedidos');

  Future<List<Map<String, dynamic>>>
  consultarPromocionesAdministrativas() async =>
      _listData(await _authenticated('GET', 'promociones'), 'promociones');

  Future<List<Map<String, dynamic>>> consultarUsuariosAdministrativos() async =>
      _listData(await _authenticated('GET', 'auth/usuarios'), 'usuarios');

  Future<Map<String, dynamic>> _multipart(
    String method,
    String path,
    Map<String, String> fields, {
    String? imagePath,
    String fileField = 'imagen',
  }) async {
    final token = await tokenProvider?.call();
    if (token == null || token.isEmpty) {
      throw const ApiException('Inicia sesión para continuar.');
    }
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(fileField, imagePath),
      );
    }
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return _decodeAuthenticated(response);
  }

  Future<void> guardarProductoAdministrativo({
    int? id,
    required Map<String, String> campos,
    String? imagePath,
  }) async {
    await _multipart(
      id == null ? 'POST' : 'PUT',
      id == null ? 'productos' : 'productos/$id',
      campos,
      imagePath: imagePath,
    );
  }

  Future<void> eliminarProductoAdministrativo(int id) async =>
      _authenticated('DELETE', 'productos/$id');

  Future<void> actualizarEstadoPedidoAdministrativo(
    int id,
    String estado,
  ) async => _authenticated('PUT', 'pedidos/$id', body: {'estado': estado});

  Future<void> enviarBoletaEnvase({
    required int pedidoId,
    required Map<String, String> fields,
    required String imagePath,
  }) async => _multipart(
    'PUT',
    'pedidos/$pedidoId/envase',
    fields,
    imagePath: imagePath,
    fileField: 'boleta',
  );

  Future<void> registrarEnvioPedidoAdministrativo({
    required int pedidoId,
    required Map<String, String> fields,
    required String imagePath,
  }) async => _multipart(
    'PUT',
    'pedidos/$pedidoId/envio',
    fields,
    imagePath: imagePath,
    fileField: 'boleta',
  );

  Future<void> guardarPromocionAdministrativa({
    int? id,
    required Map<String, dynamic> body,
  }) async => _authenticated(
    id == null ? 'POST' : 'PUT',
    id == null ? 'promociones' : 'promociones/$id',
    body: body,
  );

  Future<void> eliminarPromocionAdministrativa(int id) async =>
      _authenticated('DELETE', 'promociones/$id');

  Future<void> crearEmpleadoAdministrativo(Map<String, dynamic> body) async =>
      _authenticated('POST', 'auth/empleados', body: body);

  Future<void> actualizarUsuarioAdministrativo(
    int id,
    Map<String, dynamic> body,
  ) async => _authenticated('PUT', 'auth/usuarios/$id', body: body);

  Future<Map<String, dynamic>> consultarSitioPublico() async {
    final response = await _get('sitio/inicio');
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw const ApiException('No se pudo cargar el contenido de la tienda.');
    }
    return body;
  }

  Future<void> guardarConfiguracionSitio(
    Map<String, String> fields, {
    String? logoPath,
  }) async => _multipart(
    'PUT',
    'sitio/configuracion',
    fields,
    imagePath: logoPath,
    fileField: 'logo',
  );

  Future<void> guardarCarrusel({
    int? id,
    required Map<String, String> fields,
    String? imagePath,
  }) async => _multipart(
    id == null ? 'POST' : 'PUT',
    id == null ? 'sitio/carrusel' : 'sitio/carrusel/$id',
    fields,
    imagePath: imagePath,
  );

  Future<void> eliminarCarrusel(int id) async =>
      _authenticated('DELETE', 'sitio/carrusel/$id');

  List<Map<String, dynamic>> _listData(
    Map<String, dynamic> body,
    String label,
  ) {
    final data = body['data'];
    if (data is! List) {
      throw ApiException('El servidor devolvió una lista de $label inválida.');
    }
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> _authenticated(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await tokenProvider?.call();
    if (token == null || token.isEmpty) {
      throw const ApiException('Inicia sesión para continuar.');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$baseUrl$path');
    final response = await switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => _client.put(uri, headers: headers, body: jsonEncode(body)),
      'DELETE' => _client.delete(uri, headers: headers),
      _ => throw StateError('Método HTTP no soportado'),
    }.timeout(const Duration(seconds: 20));
    return _decodeAuthenticated(response);
  }

  Map<String, dynamic> _decodeAuthenticated(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = <String, dynamic>{};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw ApiException(
        message ?? 'El servidor respondió ${response.statusCode}.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }
    if (decoded['success'] == false) {
      throw ApiException(
        decoded['message']?.toString() ?? 'No se pudo completar la operación.',
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> consultarSalud() async {
    final response = await _get('health');
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> consultarProductos() async {
    final response = await _get('productos');
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const ApiException(
        'El catálogo devolvió una respuesta inesperada.',
      );
    }
    if (body['success'] != true) {
      throw ApiException(
        body['message']?.toString() ?? 'No se pudo cargar el catálogo.',
      );
    }
    final items = body['data'];
    if (items is! List) {
      throw const ApiException('El servidor devolvió un catálogo inválido.');
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<Map<String, dynamic>> intercambiarTokenFirebase({
    required String idToken,
    String? nombre,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${baseUrl}auth/firebase/exchange'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken, 'nombre': nombre}),
        )
        .timeout(const Duration(seconds: 20));
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }
    if (body is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        body['message']?.toString() ??
            'No se pudo iniciar sesión con Dulce Miel.',
      );
    }
    return body;
  }

  Future<http.Response> _get(String path) async {
    final response = await _client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) message = body['message']?.toString();
      } on FormatException {
        // Use the status fallback when the server response is not JSON.
      }
      throw ApiException(
        message ?? 'El servidor respondió ${response.statusCode}.',
      );
    }
    return response;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
