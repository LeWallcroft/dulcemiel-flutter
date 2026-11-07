import 'package:flutter/material.dart';

import '../repositories/autenticacion_repository.dart';
import '../network/api_service.dart';
import '../viewmodels/carrito_view_model.dart';
import '../viewmodels/acceso_view_model.dart';
import 'administracion_screen.dart';
import 'perfil_screen.dart';
import 'widgets/ui_components.dart';

class AccesoScreen extends StatefulWidget {
  const AccesoScreen({
    super.key,
    required this.repository,
    required this.apiService,
    this.carritoViewModel,
  });

  final AutenticacionRepository repository;
  final ApiService apiService;
  final CarritoViewModel? carritoViewModel;

  @override
  State<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends State<AccesoScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AccesoViewModel _viewModel;
  bool _modoRegistro = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AccesoViewModel(widget.repository)..restaurar();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta Dulce Miel')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PageIntro(
              title: _viewModel.sesion != null
                  ? 'Tu cuenta Dulce Miel'
                  : _modoRegistro
                  ? 'Crea tu cuenta'
                  : 'Bienvenido de nuevo',
              subtitle: _viewModel.sesion != null
                  ? 'Tu cuenta está conectada y lista para comprar.'
                  : 'Inicia sesión para sincronizar el carrito y tus pedidos.',
              icon: Icons.person_outline,
            ),
            if (_viewModel.sesion case final sesion?) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(sesion.nombre),
                  subtitle: Text('${sesion.email}\nRol: ${sesion.rol}'),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 8),
              if (['admin', 'empleado'].contains(sesion.rol.toLowerCase())) ...[
                FilledButton.tonalIcon(
                  onPressed: _viewModel.ocupado
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdministracionScreen(
                              apiService: widget.apiService,
                              rol: sesion.rol,
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Abrir panel de administración'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _viewModel.ocupado
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PerfilScreen(
                            autenticacionRepository: widget.repository,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Ver perfil desde el servidor'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _viewModel.ocupado
                    ? null
                    : () async {
                        await _viewModel.cerrarSesion();
                        if (_viewModel.sesion == null) {
                          widget.carritoViewModel?.limpiarLocal();
                        }
                      },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
              if (_viewModel.error case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_viewModel.mensaje case final mensaje?) ...[
                const SizedBox(height: 12),
                Text(mensaje, textAlign: TextAlign.center),
              ],
            ] else ...[
              if (_viewModel.error case final error?) ...[
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (_modoRegistro) ...[
                TextField(
                  controller: _nombreController,
                  enabled: !_viewModel.ocupado,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _emailController,
                enabled: !_viewModel.ocupado,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                enabled: !_viewModel.ocupado,
                obscureText: true,
                autofillHints: _modoRegistro
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _enviar(),
              ),
              if (_viewModel.mensaje case final mensaje?) ...[
                const SizedBox(height: 12),
                Text(mensaje, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _viewModel.ocupado ? null : _enviar,
                child: _viewModel.ocupado
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_modoRegistro ? 'Registrarme' : 'Ingresar'),
              ),
              if (!_modoRegistro)
                TextButton(
                  onPressed: _viewModel.ocupado
                      ? null
                      : () => _viewModel.restablecerContrasena(
                          _emailController.text,
                        ),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              TextButton(
                onPressed: _viewModel.ocupado
                    ? null
                    : () => setState(() => _modoRegistro = !_modoRegistro),
                child: Text(
                  _modoRegistro ? 'Ya tengo una cuenta' : 'Crear una cuenta',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _enviar() {
    if (_modoRegistro) {
      _viewModel.registrar(
        _nombreController.text,
        _emailController.text,
        _passwordController.text,
      );
    } else {
      _viewModel.iniciarSesion(_emailController.text, _passwordController.text);
    }
  }
}
