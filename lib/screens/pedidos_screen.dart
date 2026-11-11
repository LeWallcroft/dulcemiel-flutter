import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pedido.dart';
import '../models/coordenada.dart';
import '../network/api_service.dart';
import '../repositories/autenticacion_repository.dart';
import '../repositories/pedidos_repository.dart';
import '../repositories/sesion_repository.dart';
import '../viewmodels/pedidos_view_model.dart';
import 'acceso_screen.dart';
import 'mapa_ubicacion_screen.dart';
import 'widgets/ui_components.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({
    super.key,
    required this.apiService,
    required this.sesionRepository,
    required this.autenticacionRepository,
  });
  final ApiService apiService;
  final SesionRepository sesionRepository;
  final AutenticacionRepository autenticacionRepository;
  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  late final PedidosViewModel vm;
  bool comprobandoSesion = true;
  bool autenticado = false;

  @override
  void initState() {
    super.initState();
    vm = PedidosViewModel(PedidosRepository(widget.apiService));
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
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis pedidos')),
    body: comprobandoSesion
        ? const Center(child: CircularProgressIndicator())
        : !autenticado
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Inicia sesión para consultar tus pedidos.',
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
              if (vm.cargando && vm.pedidos.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.error != null && vm.pedidos.isEmpty) {
                return _EstadoPedidos(mensaje: vm.error!, accion: vm.cargar);
              }
              if (vm.pedidos.isEmpty) {
                return const FeedbackPanel(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aún no tienes pedidos',
                  message: 'Cuando completes una compra, podrás consultar aquí su estado y detalle.',
                );
              }
              return RefreshIndicator(
                onRefresh: vm.cargar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.pedidos.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const PageIntro(
                        title: 'Historial de compras',
                        subtitle: 'Consulta estados y detalles de tus pedidos.',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    final pedido = vm.pedidos[index - 1];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _abrirDetalle(pedido),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pedido.numero.isEmpty
                                          ? 'Pedido #${pedido.id}'
                                          : pedido.numero,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  _EstadoChip(estado: pedido.estado),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: S/ ${pedido.total.toStringAsFixed(2)}',
                              ),
                              if (pedido.fecha != null)
                                Text(
                                  'Registrado: ${pedido.fecha}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ver detalle',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
  );

  Future<void> _abrirDetalle(Pedido pedido) async {
    await vm.cargarDetalle(pedido.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _DetallePedidoScreen(vm: vm)),
    );
  }
}

class _EstadoPedidos extends StatelessWidget {
  const _EstadoPedidos({required this.mensaje, this.accion});
  final String mensaje;
  final VoidCallback? accion;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensaje, textAlign: TextAlign.center),
          if (accion != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: accion, child: const Text('Reintentar')),
          ],
        ],
      ),
    ),
  );
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});
  final String estado;
  @override
  Widget build(BuildContext context) {
    final color = switch (estado.toLowerCase()) {
      'entregado' => Colors.green,
      'cancelado' => Colors.red,
      'enviado' => Colors.blue,
      _ => Colors.brown,
    };
    return StatusBadge(label: estado, color: color);
  }
}

class _DetallePedidoScreen extends StatefulWidget {
  const _DetallePedidoScreen({required this.vm});
  final PedidosViewModel vm;

  @override
  State<_DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<_DetallePedidoScreen> {
  final agencia = TextEditingController();
  final guia = TextEditingController();
  final costo = TextEditingController();
  XFile? boleta;

  @override
  void dispose() {
    agencia.dispose();
    guia.dispose();
    costo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del pedido')),
    body: AnimatedBuilder(
      animation: widget.vm,
      builder: (context, _) {
        if (widget.vm.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.vm.error != null) {
          return _EstadoPedidos(mensaje: widget.vm.error!);
        }
        final detalle = widget.vm.detalle;
        if (detalle == null) {
          return const _EstadoPedidos(mensaje: 'No se encontró el pedido.');
        }
        final pedido = detalle.pedido;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              pedido.numero.isEmpty ? 'Pedido #${pedido.id}' : pedido.numero,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _EstadoChip(estado: pedido.estado),
            if (pedido.fecha != null) Text('Registrado: ${pedido.fecha}'),
            const SizedBox(height: 20),
            const PageIntro(
              title: 'Productos',
              subtitle: 'Detalle de tu compra.',
              icon: Icons.inventory_2_outlined,
            ),
            ...detalle.lineas.map(
              (linea) => Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  title: Text(linea.nombre),
                  subtitle: Text(
                    [
                      '${linea.cantidad} × S/ ${linea.precioUnitario.toStringAsFixed(2)}',
                      if (linea.envaseNombre != null)
                        'Envase: ${linea.envaseNombre}${linea.costoEnvaseUnitario > 0 ? ' (+ S/ ${linea.costoEnvaseUnitario.toStringAsFixed(2)} c/u)' : ''}',
                    ].join('\n'),
                  ),
                  trailing: Text('S/ ${linea.subtotal.toStringAsFixed(2)}'),
                ),
              ),
            ),
            if (pedido.tieneEnvaseCliente) ...[
              const SizedBox(height: 20),
              const PageIntro(
                title: 'Envío de tus frascos',
                subtitle: 'Tú cubres el envío de los frascos hacia Dulce Miel.',
                icon: Icons.recycling_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frascos: ${pedido.cantidadEnvasesCliente}'),
                      if (pedido.envaseEnvioAgencia != null)
                        Text('Agencia: ${pedido.envaseEnvioAgencia}'),
                      if (pedido.envaseEnvioGuia != null)
                        Text('Guía: ${pedido.envaseEnvioGuia}'),
                      if (pedido.envaseEnvioCosto != null)
                        Text(
                          'Costo pagado: S/ ${pedido.envaseEnvioCosto!.toStringAsFixed(2)}',
                        ),
                      if (pedido.envaseEnvioBoletaUrl != null)
                        TextButton.icon(
                          onPressed: () =>
                              _mostrarBoleta(pedido.envaseEnvioBoletaUrl!),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Ver boleta enviada'),
                        ),
                      if (pedido.estado == 'esperando_envase' &&
                          pedido.envaseEnvioBoletaUrl == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Destino: ${pedido.envaseDestino?.trim().isNotEmpty == true ? pedido.envaseDestino : 'Contacta con Dulce Miel para coordinar la entrega del frasco.'}',
                        ),
                        if (pedido.envaseReceptor?.trim().isNotEmpty == true)
                          Text('Recibe: ${pedido.envaseReceptor}'),
                        if (pedido.envaseTelefono?.trim().isNotEmpty == true)
                          Text('Teléfono: ${pedido.envaseTelefono}'),
                        TextFormField(
                          controller: agencia,
                          decoration: const InputDecoration(
                            labelText: 'Agencia de envío',
                          ),
                        ),
                        TextFormField(
                          controller: guia,
                          decoration: const InputDecoration(
                            labelText: 'Código o guía',
                          ),
                        ),
                        TextFormField(
                          controller: costo,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Costo pagado (S/)',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _elegirBoleta,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(boleta?.name ?? 'Adjuntar boleta'),
                        ),
                        FilledButton(
                          onPressed:
                              boleta == null ||
                                  agencia.text.trim().isEmpty ||
                                  guia.text.trim().isEmpty ||
                                  (double.tryParse(
                                            costo.text.replaceAll(',', '.'),
                                          ) ??
                                          -1) <
                                      0
                              ? null
                              : () => widget.vm.enviarBoletaEnvase(
                                  pedidoId: pedido.id,
                                  fields: {
                                    'agencia': agencia.text.trim(),
                                    'guia': guia.text.trim(),
                                    'costo': costo.text.trim().replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  },
                                  imagePath: boleta!.path,
                                ),
                          child: const Text('Guardar datos y boleta'),
                        ),
                      ],
                      if (pedido.envaseRecibidoFecha != null)
                        const Text(
                          'Dulce Miel confirmó la recepción del frasco.',
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (pedido.envioPedidoAgencia != null ||
                pedido.estado == 'enviado') ...[
              const SizedBox(height: 20),
              const PageIntro(
                title: 'Envío de tu pedido',
                subtitle: 'El costo de envío es asumido por el cliente.',
                icon: Icons.local_shipping_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pedido.envioPedidoAgencia != null)
                        Text('Agencia: ${pedido.envioPedidoAgencia}'),
                      if (pedido.envioPedidoGuia != null)
                        Text('Guía: ${pedido.envioPedidoGuia}'),
                      if (pedido.envioPedidoCosto != null)
                        Text(
                          'Costo: S/ ${pedido.envioPedidoCosto!.toStringAsFixed(2)}',
                        ),
                      if (pedido.envioPedidoBoletaUrl != null)
                        TextButton.icon(
                          onPressed: () =>
                              _mostrarBoleta(pedido.envioPedidoBoletaUrl!),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Ver boleta de envío'),
                        ),
                      if (pedido.estado == 'enviado' &&
                          pedido.envioPedidoAgencia == null)
                        const Text(
                          'El administrador registrará los datos del envío y su comprobante.',
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'S/ ${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (pedido.direccion != null || pedido.distrito != null) ...[
              const SizedBox(height: 24),
              const PageIntro(
                title: 'Entrega',
                subtitle: 'Datos registrados para este pedido.',
                icon: Icons.local_shipping_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pedido.nombreContacto?.isNotEmpty == true)
                        Text(
                          pedido.nombreContacto!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      if (pedido.telefono?.isNotEmpty == true)
                        Text(pedido.telefono!),
                      if (pedido.direccion?.isNotEmpty == true)
                        Text(pedido.direccion!),
                      if (pedido.distrito?.isNotEmpty == true)
                        Text(pedido.distrito!),
                      if (pedido.referencia?.isNotEmpty == true)
                        Text('Referencia: ${pedido.referencia}'),
                      if (pedido.latitudEntrega != null &&
                          pedido.longitudEntrega != null)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => MapaUbicacionScreen(
                                inicial: Coordenada(
                                  latitud: pedido.latitudEntrega!,
                                  longitud: pedido.longitudEntrega!,
                                ),
                                soloLectura: true,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Ver ubicación en el mapa'),
                        ),
                      if (pedido.notas?.isNotEmpty == true)
                        Text('Notas: ${pedido.notas}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  Future<void> _elegirBoleta() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file != null && mounted) setState(() => boleta = file);
  }

  void _mostrarBoleta(String url) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: InteractiveViewer(
        child: Image.network(
          url,
          errorBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No se pudo cargar la boleta.'),
          ),
        ),
      ),
    ),
  );
}
