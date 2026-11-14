// Pruebas de interfaz (widget tests) de los componentes compartidos.
import 'package:dulce_miel_flutter/app_theme.dart';
import 'package:dulce_miel_flutter/screens/widgets/ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      theme: buildDulceMielTheme(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('PI-01 PageIntro muestra título, subtítulo e ícono', (tester) async {
    await tester.pumpWidget(_app(const PageIntro(
      title: 'Catálogo',
      subtitle: 'Miel artesanal',
      icon: Icons.storefront,
    )));

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Miel artesanal'), findsOneWidget);
    expect(find.byIcon(Icons.storefront), findsOneWidget);
  });

  testWidgets('PI-02 FeedbackPanel ejecuta la acción de reintentar', (tester) async {
    var reintentos = 0;
    await tester.pumpWidget(_app(FeedbackPanel(
      icon: Icons.wifi_off,
      title: 'Sin conexión',
      message: 'Revisa tu red',
      actionLabel: 'Reintentar',
      onAction: () => reintentos++,
    )));

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(reintentos, 1);
  });

  testWidgets('PI-03 FeedbackPanel bloquea el botón mientras carga', (tester) async {
    await tester.pumpWidget(_app(FeedbackPanel(
      icon: Icons.sync,
      title: 'Cargando',
      message: 'Espera',
      actionLabel: 'Reintentar',
      onAction: () {},
      loading: true,
    )));

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('PI-04 StatusBadge muestra el estado del pedido', (tester) async {
    await tester.pumpWidget(_app(const StatusBadge(label: 'Entregado')));
    expect(find.text('Entregado'), findsOneWidget);
  });

  testWidgets('PI-05 diálogo de producto agregado permite ir al carrito', (tester) async {
    bool? resultado;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          resultado = await mostrarDialogoProductoAgregado(context, nombre: 'Miel', cantidad: 2);
        },
        child: const Text('Agregar'),
      ),
    )));

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('2 unidades de Miel se agregaron al carrito.'), findsOneWidget);

    await tester.tap(find.text('Ir al carrito'));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);
  });
}
