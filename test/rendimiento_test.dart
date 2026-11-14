// Pruebas de rendimiento: tiempo de procesamiento de datos del catálogo.
import 'dart:convert';

import 'package:dulce_miel_flutter/models/producto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PR-01 convertir 1000 productos desde JSON toma menos de 500 ms', () {
    final json = jsonEncode(List.generate(1000, (i) => {
          'id': i,
          'nombre': 'Producto $i',
          'descripcion': 'Miel artesanal número $i',
          'precio': 20 + i % 15,
          'stock': i % 30,
          'categoria': i.isEven ? 'Miel' : 'Derivados',
          'opciones_envase': [
            {'id': 1, 'codigo': 'convencional', 'costo_extra': 0},
            {'id': 2, 'codigo': 'frasco_cliente', 'costo_extra': -2},
          ],
        }));

    final reloj = Stopwatch()..start();
    final productos = (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(Producto.fromJson)
        .toList();
    reloj.stop();

    // ignore: avoid_print
    print('PR-01: 1000 productos convertidos en ${reloj.elapsedMilliseconds} ms');
    expect(productos, hasLength(1000));
    expect(reloj.elapsedMilliseconds, lessThan(500));
  });
}
