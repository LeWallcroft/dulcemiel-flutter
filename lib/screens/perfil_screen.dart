import 'package:flutter/material.dart';

import '../repositories/autenticacion_repository.dart';
import '../repositories/perfil_repository.dart';
import '../viewmodels/perfil_view_model.dart';
import 'widgets/ui_components.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key, required this.autenticacionRepository});
  final AutenticacionRepository autenticacionRepository;
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final PerfilViewModel vm;
  @override
  void initState() {
    super.initState();
    vm = PerfilViewModel(PerfilRepository(widget.autenticacionRepository))
      ..cargar();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi perfil')),
    body: AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.cargando && vm.perfil == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null && vm.perfil == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vm.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: vm.cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final perfil = vm.perfil;
        if (perfil == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageIntro(
              title: 'Tu perfil',
              subtitle: 'Información de la cuenta registrada en Dulce Miel.',
              icon: Icons.person_outline,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      child: Text(
                        perfil.nombre.isEmpty
                            ? '?'
                            : perfil.nombre.characters.first.toUpperCase(),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      perfil.nombre,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(perfil.email, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Chip(
                      label: Text(
                        perfil.rol.replaceFirst('_', ' ').toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Identificador'),
                    subtitle: Text('${perfil.id}'),
                  ),
                  if (perfil.estado != null)
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('Estado de la cuenta'),
                      subtitle: Text(perfil.estado!),
                    ),
                  if (perfil.fechaCreacion != null)
                    ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Cuenta creada'),
                      subtitle: Text(perfil.fechaCreacion!),
                    ),
                ],
              ),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: vm.cargando ? null : vm.cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar perfil'),
            ),
          ],
        );
      },
    ),
  );
}
