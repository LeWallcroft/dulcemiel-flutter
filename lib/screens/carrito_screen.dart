import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/linea_carrito.dart';
import '../models/coordenada.dart';
import '../network/api_service.dart';
import '../repositories/autenticacion_repository.dart';
import '../repositories/carrito_repository.dart';
import '../repositories/sesion_repository.dart';
import '../viewmodels/carrito_view_model.dart';
import 'acceso_screen.dart';
import 'mapa_ubicacion_screen.dart';
import 'widgets/ui_components.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({
    super.key,
    required this.apiService,
    required this.sesionRepository,
    required this.autenticacionRepository,
    this.carritoViewModel,
  });
  final ApiService apiService;
  final SesionRepository sesionRepository;
  final AutenticacionRepository autenticacionRepository;
  final CarritoViewModel? carritoViewModel;
  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late final CarritoViewModel vm;
  late final bool _creaViewModel;
  bool comprobandoSesion = true;
  bool autenticado = false;

  @override
  void initState() {
    super.initState();
    _creaViewModel = widget.carritoViewModel == null;
    vm =
        widget.carritoViewModel ??
        CarritoViewModel(CarritoRepository(widget.apiService));
    _iniciar();
  }

  Future<void> _iniciar() async {
    final sesion = await widget.sesionRepository.leer();
    if (!mounted) return;
    setState(() {
      autenticado = sesion != null;
      comprobandoSesion = false;
    });
    if (sesion != null) vm.cargar();
  }

  @override
  void dispose() {
    if (_creaViewModel) vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi carrito')),
    body: comprobandoSesion
        ? const Center(child: CircularProgressIndicator())
        : !autenticado
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Inicia sesión para consultar tu carrito.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AccesoScreen(
                            repository: widget.autenticacionRepository,
                            apiService: widget.apiService,
                            carritoViewModel: vm,
                          ),
                        ),
                      );
                      await _iniciar();
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              ),
            ),
          )
        : AnimatedBuilder(
            animation: vm,
            builder: (context, _) {
              if (vm.cargando && vm.lineas.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.error != null && vm.lineas.isEmpty) {
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
              if (vm.lineas.isEmpty) {
                return const FeedbackPanel(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Tu carrito está vacío',
                  message:
                      'Explora el catálogo y agrega tus productos favoritos.',
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: const PageIntro(
                      title: 'Tu carrito',
                      subtitle: 'Revisa tus productos antes de continuar.',
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                  if (vm.error != null)
                    MaterialBanner(
                      content: Text(vm.error!),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.lineas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _LineaTile(
                        linea: vm.lineas[index],
                        enabled: !vm.ocupado,
                        onChange: (n) =>
                            vm.cambiarCantidad(vm.lineas[index], n),
                        onDelete: () => vm.eliminar(vm.lineas[index]),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'S/ ${vm.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: vm.ocupado
                                  ? null
                                  : () => _checkout(context),
                              child: const Text(
                                'Continuar con datos de entrega',
                              ),
                            ),
                            TextButton(
                              onPressed: vm.ocupado ? null : vm.vaciar,
                              child: const Text('Vaciar carrito'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
  );

  Future<void> _checkout(BuildContext context) async {
    final pedido = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _CheckoutScreen(
          vm: vm,
          apiService: widget.apiService,
          necesitaEnvasePropio: vm.lineas.any(
            (linea) => linea.envase.usaFrascoCliente,
          ),
        ),
      ),
    );
    if (!context.mounted || pedido == null) return;
    final numero = pedido['numero_pedido']?.toString() ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pedido['guia_envase_pendiente'] == true
              ? 'Pedido creado${numero.isEmpty ? '' : ': $numero'}. Falta adjuntar la boleta del frasco desde Mis pedidos.'
              : 'Pedido creado correctamente${numero.isEmpty ? '' : ': $numero'}',
        ),
      ),
    );
  }
}

class _LineaTile extends StatelessWidget {
  const _LineaTile({
    required this.linea,
    required this.enabled,
    required this.onChange,
    required this.onDelete,
  });
  final LineaCarrito linea;
  final bool enabled;
  final ValueChanged<int> onChange;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            linea.producto.nombre,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'S/ ${linea.producto.precio.toStringAsFixed(2)} c/u${linea.producto.stock == 2147483647 ? '' : ' · ${linea.producto.stock} disponibles'}',
          ),
          const SizedBox(height: 4),
          Text('Envase: ${linea.envase.nombre}'),
          if (linea.costoEnvaseUnitario > 0)
            Text(
              'Extra por frasco: S/ ${linea.costoEnvaseUnitario.toStringAsFixed(2)} c/u',
            ),
          if (linea.envase.usaFrascoCliente)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Debes enviar tu frasco y pagar ambos envíos.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? () => onChange(linea.cantidad - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Reducir cantidad',
              ),
              Text('${linea.cantidad}'),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? () => onChange(linea.cantidad + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Aumentar cantidad',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar producto',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CheckoutScreen extends StatefulWidget {
  const _CheckoutScreen({
    required this.vm,
    required this.apiService,
    required this.necesitaEnvasePropio,
  });
  final CarritoViewModel vm;
  final ApiService apiService;
  final bool necesitaEnvasePropio;
  @override
  State<_CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<_CheckoutScreen> {
  final form = GlobalKey<FormState>();
  final nombre = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();
  final direccion = TextEditingController();
  final distrito = TextEditingController();
  final referencia = TextEditingController();
  final notas = TextEditingController();
  final agenciaEnvase = TextEditingController();
  final guiaEnvase = TextEditingController();
  final costoEnvase = TextEditingController();
  final _picker = ImagePicker();
  XFile? boletaEnvase;
  bool cargandoDestino = false;
  String? destinoEnvases;
  String? receptorEnvases;
  String? telefonoEnvases;
  Coordenada? ubicacionEntrega;

  @override
  void initState() {
    super.initState();
    _cargarDestinoEnvases();
  }

  Future<void> _cargarDestinoEnvases() async {
    if (!widget.necesitaEnvasePropio) return;
    setState(() => cargandoDestino = true);
    try {
      final response = await widget.apiService.consultarSitioPublico();
      final config = response['configuracion'];
      if (config is Map<String, dynamic> && mounted) {
        setState(() {
          destinoEnvases = config['direccion_envases']?.toString();
          receptorEnvases = config['receptor_envases']?.toString();
          telefonoEnvases = config['telefono_envases']?.toString();
        });
      }
    } catch (_) {
      // El destino queda visible como no configurado y se solicita a administración.
    } finally {
      if (mounted) setState(() => cargandoDestino = false);
    }
  }

  @override
  void dispose() {
    nombre.dispose();
    telefono.dispose();
    email.dispose();
    direccion.dispose();
    distrito.dispose();
    referencia.dispose();
    notas.dispose();
    agenciaEnvase.dispose();
    guiaEnvase.dispose();
    costoEnvase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Datos de entrega')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageIntro(
            title: 'Datos de entrega',
            subtitle: 'Completa la información para recibir tu pedido.',
            icon: Icons.local_shipping_outlined,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _field(nombre, 'Nombre de quien recibe'),
                  _field(
                    telefono,
                    'Teléfono',
                    keyboard: TextInputType.phone,
                    validator: _validarTelefono,
                  ),
                  _field(
                    email,
                    'Correo (opcional)',
                    keyboard: TextInputType.emailAddress,
                    required: false,
                    validator: (value) {
                      final correo = value?.trim() ?? '';
                      if (correo.isEmpty) return null;
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(correo)
                          ? null
                          : 'Ingresa un correo válido.';
                    },
                  ),
                  _field(direccion, 'Dirección'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context)
                            .push<Coordenada>(
                              MaterialPageRoute(
                                builder: (_) => MapaUbicacionScreen(
                                  inicial: ubicacionEntrega,
                                ),
                              ),
                            );
                        if (result != null && mounted) {
                          setState(() => ubicacionEntrega = result);
                        }
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        ubicacionEntrega == null
                            ? 'Elegir ubicación en el mapa (opcional)'
                            : 'Ubicación seleccionada',
                      ),
                    ),
                  ),
                  if (ubicacionEntrega != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Punto: ${ubicacionEntrega!.latitud.toStringAsFixed(5)}, ${ubicacionEntrega!.longitud.toStringAsFixed(5)}',
                      ),
                    ),
                  _field(distrito, 'Distrito o ciudad'),
                  _field(
                    referencia,
                    'Referencia (opcional)',
                    required: false,
                    max: 300,
                  ),
                  _field(notas, 'Notas (opcional)', required: false),
                ],
              ),
            ),
          ),
          if (widget.necesitaEnvasePropio) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer
                  .withValues(alpha: .45),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envía tu frasco de vidrio',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Debes pagar el envío de tu frasco a Dulce Miel y el envío del pedido preparado a tu domicilio.',
                    ),
                    const SizedBox(height: 10),
                    if (cargandoDestino)
                      const LinearProgressIndicator()
                    else ...[
                      Text(
                        'Dirección: ${destinoEnvases?.trim().isNotEmpty == true ? destinoEnvases : 'Pendiente de configuración por la tienda'}',
                      ),
                      if (receptorEnvases?.trim().isNotEmpty == true)
                        Text('Recibe: $receptorEnvases'),
                      if (telefonoEnvases?.trim().isNotEmpty == true)
                        Text('Teléfono: $telefonoEnvases'),
                    ],
                    const SizedBox(height: 12),
                    _field(agenciaEnvase, 'Agencia del envío del frasco'),
                    _field(guiaEnvase, 'Número de guía del frasco'),
                    _field(
                      costoEnvase,
                      'Costo que pagaste por enviar el frasco',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.vm.ocupado ? null : _seleccionarBoleta,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text(
                        boletaEnvase == null
                            ? 'Adjuntar boleta del envío *'
                            : 'Boleta seleccionada',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'El costo del envío del pedido también lo asume el cliente; la tienda informará el importe antes del despacho.',
          ),
          if (widget.vm.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                widget.vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: widget.vm.ocupado ? null : _submit,
            child: widget.vm.ocupado
                ? const CircularProgressIndicator()
                : const Text('Confirmar pedido'),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    bool required = true,
    int? max,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLength: max,
      validator:
          validator ??
          (v) => required && (v?.trim().isEmpty ?? true)
              ? 'Este campo es obligatorio.'
              : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  String? _validarTelefono(String? value) {
    final telefono = value?.trim() ?? '';
    if (telefono.length < 6 || telefono.length > 20) {
      return 'Ingresa un teléfono válido.';
    }
    for (final character in telefono.split('')) {
      if (!RegExp(r'^[0-9+()\s-]$').hasMatch(character)) {
        return 'Ingresa un teléfono válido.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (widget.necesitaEnvasePropio) {
      if (destinoEnvases?.trim().isNotEmpty != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La tienda aún no configuró la dirección para recibir frascos.',
            ),
          ),
        );
        return;
      }
      if (agenciaEnvase.text.trim().isEmpty ||
          guiaEnvase.text.trim().isEmpty ||
          (double.tryParse(costoEnvase.text.trim().replaceAll(',', '.')) ??
                  -1) <
              0 ||
          boletaEnvase == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Completa los datos del envío y adjunta la boleta de tu frasco.',
            ),
          ),
        );
        return;
      }
    }
    final pedido = await widget.vm.confirmarPedido(
      {
        'contacto_nombre': nombre.text.trim(),
        'contacto_telefono': telefono.text.trim(),
        'contacto_email': email.text.trim(),
        'direccion_entrega': direccion.text.trim(),
        'distrito': distrito.text.trim(),
        'referencia': referencia.text.trim(),
        'notas': notas.text.trim(),
        if (ubicacionEntrega != null) ...{
          'direccion_entrega_lat': ubicacionEntrega!.latitud,
          'direccion_entrega_lng': ubicacionEntrega!.longitud,
        },
      },
      envioEnvase: widget.necesitaEnvasePropio
          ? {
              'agencia': agenciaEnvase.text.trim(),
              'guia': guiaEnvase.text.trim(),
              'costo': costoEnvase.text.trim().replaceAll(',', '.'),
            }
          : null,
      boletaEnvasePath: boletaEnvase?.path,
    );
    if (pedido != null && mounted) Navigator.of(context).pop(pedido);
    if (mounted) setState(() {});
  }

  Future<void> _seleccionarBoleta() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image != null && mounted) setState(() => boletaEnvase = image);
  }
}
