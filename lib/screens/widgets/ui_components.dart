import 'package:flutter/material.dart';

import '../../app_theme.dart';

class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });
  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8AE),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: DulceMielColors.mielProfunda),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1CE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(icon, size: 32, color: DulceMielColors.miel),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : onAction,
                      child: loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color = DulceMielColors.hoja,
  });
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .22)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
}

Future<bool?> mostrarDialogoProductoAgregado(
  BuildContext context, {
  required String nombre,
  required int cantidad,
}) => showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    scrollable: true,
    icon: const CircleAvatar(
      radius: 28,
      child: Icon(Icons.shopping_cart_checkout_outlined),
    ),
    title: const Text('Agregado al carrito'),
    content: Text(
      cantidad == 1
          ? '$nombre se agregó al carrito.'
          : '$cantidad unidades de $nombre se agregaron al carrito.',
      textAlign: TextAlign.center,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: const Text('Seguir comprando'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        icon: const Icon(Icons.shopping_bag_outlined),
        label: const Text('Ir al carrito'),
      ),
    ],
  ),
);
