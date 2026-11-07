import 'package:flutter/material.dart';

class Ods12Screen extends StatelessWidget {
  const Ods12Screen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consumo responsable · ODS 12')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: const Color(0xFF79560A),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.eco_outlined, size: 42, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Producción y consumo responsables',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dulce Miel promueve decisiones de compra informadas y la reutilización de frascos cuando el producto lo permite.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _MetaCard(
          numero: '12.5',
          titulo: 'Reducir residuos mediante reutilización',
          texto: 'Algunos productos permiten enviar un frasco de vidrio propio para recargarlo. La tienda confirma su recepción antes de preparar el pedido.',
          icono: Icons.recycling_outlined,
        ),
        const SizedBox(height: 12),
        const _MetaCard(
          numero: '12.8',
          titulo: 'Información para elegir responsablemente',
          texto: 'Las fichas de producto pueden incluir orientación breve sobre envases y consumo responsable. Revisa la descripción y las opciones disponibles antes de comprar.',
          icono: Icons.menu_book_outlined,
        ),
        const SizedBox(height: 14),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'La reutilización requiere que el frasco sea recibido y utilizado nuevamente. Esta iniciativa contribuye a metas seleccionadas del ODS 12; no representa una certificación ni el cumplimiento integral del objetivo.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Referencia: Naciones Unidas, Objetivo de Desarrollo Sostenible 12 · sdgs.un.org/goals/goal12',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.numero,
    required this.titulo,
    required this.texto,
    required this.icono,
  });

  final String numero;
  final String titulo;
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Icon(icono)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meta $numero',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(texto, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
