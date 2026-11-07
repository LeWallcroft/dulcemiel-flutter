import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/administracion_repository.dart';
import '../network/api_service.dart';
import '../viewmodels/administracion_view_model.dart';
import 'widgets/ui_components.dart';

class AdministracionScreen extends StatefulWidget {
  const AdministracionScreen({
    super.key,
    required this.apiService,
    required this.rol,
  });
  final ApiService apiService;
  final String rol;

  @override
  State<AdministracionScreen> createState() => _AdministracionScreenState();
}

class _AdministracionScreenState extends State<AdministracionScreen>
    with SingleTickerProviderStateMixin {
  late final AdministracionViewModel vm;
  late final TabController tabs;
  bool get esAdmin => widget.rol.toLowerCase() == 'admin';

  Future<XFile?> _seleccionarImagen(ImageSource source) async {
    try {
      return await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );
    } on PlatformException catch (error) {
      if (mounted) {
        final message =
            error.code.contains('permission') ||
                error.code.contains('camera_access_denied')
            ? 'No se concedió permiso para usar la cámara. Puedes habilitarlo en Ajustes de la aplicación.'
            : 'No se pudo abrir la cámara o galería. Inténtalo nuevamente.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      return null;
    }
  }

  Widget _selectorImagen({
    required BuildContext editorContext,
    required XFile? imagen,
    required String etiquetaGaleria,
    required ValueChanged<XFile> alSeleccionar,
  }) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      OutlinedButton.icon(
        onPressed: () async {
          final picked = await _seleccionarImagen(ImageSource.gallery);
          if (picked != null && editorContext.mounted) alSeleccionar(picked);
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(imagen?.name ?? etiquetaGaleria),
      ),
      IconButton.filledTonal(
        tooltip: 'Tomar foto con la cámara',
        onPressed: () async {
          final picked = await _seleccionarImagen(ImageSource.camera);
          if (picked != null && editorContext.mounted) alSeleccionar(picked);
        },
        icon: const Icon(Icons.photo_camera_outlined),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    vm = AdministracionViewModel(AdministracionRepository(widget.apiService))
      ..cargarTodo();
    tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administración'),
      bottom: TabBar(
        controller: tabs,
        isScrollable: true,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
          Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
          Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Pedidos'),
          Tab(icon: Icon(Icons.campaign_outlined), text: 'Promos'),
          Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'),
          Tab(icon: Icon(Icons.web_outlined), text: 'Contenido'),
        ],
      ),
    ),
    body: AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.cargando && vm.resumen.isEmpty && vm.productos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null && vm.resumen.isEmpty && vm.productos.isEmpty) {
          return FeedbackPanel(
            icon: Icons.admin_panel_settings_outlined,
            title: 'No se pudo abrir el panel',
            message: vm.error!,
            actionLabel: 'Reintentar',
            onAction: vm.cargarTodo,
          );
        }
        return Column(
          children: [
            if (vm.error != null || vm.mensaje != null)
              MaterialBanner(
                content: Text(vm.error ?? vm.mensaje!),
                leading: Icon(
                  vm.error == null
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                ),
                actions: [
                  TextButton(
                    onPressed: vm.limpiarAviso,
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            if (vm.ocupado) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [
                  _resumen(),
                  _productos(),
                  _pedidos(),
                  _promociones(),
                  _usuarios(),
                  _sitio(),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _resumen() {
    final data = vm.resumen['resumen'] as Map<String, dynamic>? ?? {};
    final recent = (vm.resumen['recientes'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return RefreshIndicator(
      onRefresh: vm.cargarTodo,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const PageIntro(
            title: 'Resumen de la tienda',
            subtitle: 'Actividad y puntos que requieren atención.',
            icon: Icons.storefront_outlined,
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _KpiCard(
                label: 'Productos',
                value: '${data['productos'] ?? 0}',
                icon: Icons.inventory_2_outlined,
              ),
              _KpiCard(
                label: 'Pedidos',
                value: '${data['pedidos'] ?? 0}',
                icon: Icons.receipt_long_outlined,
              ),
              _KpiCard(
                label: 'Clientes',
                value: '${data['clientes'] ?? 0}',
                icon: Icons.people_outline,
              ),
              _KpiCard(
                label: 'Ventas entregadas',
                value: 'S/ ${_dinero(data['ventas'])}',
                icon: Icons.payments_outlined,
              ),
              _KpiCard(
                label: 'Pendientes',
                value: '${data['pedidos_pendientes'] ?? 0}',
                icon: Icons.pending_actions_outlined,
              ),
              _KpiCard(
                label: 'Stock bajo (≤5)',
                value: '${data['stock_bajo'] ?? 0}',
                icon: Icons.warning_amber_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Pedidos recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const FeedbackPanel(
              icon: Icons.receipt_long_outlined,
              title: 'Sin pedidos recientes',
              message: 'Los nuevos pedidos aparecerán aquí.',
            )
          else
            ...recent.map(
              (r) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.shopping_bag_outlined),
                  ),
                  title: Text(
                    r['numero_pedido']?.toString() ?? 'Pedido #${r['id']}',
                  ),
                  subtitle: Text(
                    '${r['nombre'] ?? r['email'] ?? 'Cliente'} · ${r['estado'] ?? 'pendiente'}',
                  ),
                  trailing: Text('S/ ${_dinero(r['total'])}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productos() => RefreshIndicator(
    onRefresh: vm.cargarTodo,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _encabezado(
          'Productos',
          '${vm.productos.length} registrados en el catálogo.',
          Icons.inventory_2_outlined,
          FilledButton.icon(
            onPressed: vm.ocupado ? null : () => _editarProducto(),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          ),
        ),
        if (vm.productos.isEmpty)
          const FeedbackPanel(
            icon: Icons.inventory_2_outlined,
            title: 'No hay productos',
            message: 'Agrega el primer producto al catálogo.',
          )
        else
          ...vm.productos.map(
            (p) => Card(
              child: ListTile(
                leading: _miniatura(p['imagen_url']?.toString()),
                title: Text(p['nombre']?.toString() ?? 'Producto'),
                subtitle: Text(
                  '${p['categoria'] ?? 'Sin categoría'} · Stock ${p['stock'] ?? 0} · ${p['estado'] ?? 'disponible'}\nS/ ${_dinero(p['precio'])}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editarProducto(producto: p);
                    if (v == 'delete') {
                      _confirmarEliminar(
                        'producto',
                        () => vm.eliminarProducto((p['id'] as num).toInt()),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _pedidos() => RefreshIndicator(
    onRefresh: vm.cargarTodo,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageIntro(
          title: 'Pedidos',
          subtitle: 'Actualiza el estado de preparación y entrega.',
          icon: Icons.local_shipping_outlined,
        ),
        if (vm.pedidos.isEmpty)
          const FeedbackPanel(
            icon: Icons.receipt_long_outlined,
            title: 'Sin pedidos',
            message: 'Los pedidos de clientes aparecerán aquí.',
          )
        else
          ...vm.pedidos.map((p) {
            final status = p['estado']?.toString() ?? 'pendiente';
            const estados = [
              'pendiente',
              'esperando_envase',
              'procesando',
              'enviado',
              'entregado',
              'cancelado',
            ];
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p['numero_pedido']?.toString() ??
                                'Pedido #${p['id']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          'S/ ${_dinero(p['total'])}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Text(
                      '${p['contacto_nombre'] ?? p['nombre'] ?? 'Cliente'} · ${p['contacto_telefono'] ?? p['email'] ?? ''}',
                    ),
                    if (p['direccion_entrega'] != null)
                      Text(
                        '${p['direccion_entrega']} · ${p['distrito'] ?? ''}',
                      ),
                    if (p['tiene_envase_cliente'] == true) ...[
                      Text(
                        'Frascos del cliente: ${p['cantidad_envases_cliente'] ?? 0}',
                      ),
                      if (p['envase_envio_agencia'] != null)
                        Text(
                          'Envío de frascos: ${p['envase_envio_agencia']} · guía ${p['envase_envio_guia'] ?? ''} · S/ ${_dinero(p['envase_envio_costo'])}',
                        ),
                      if (p['envase_envio_boleta_url']?.toString().isNotEmpty ==
                          true)
                        TextButton.icon(
                          onPressed: () => _verComprobante(
                            p['envase_envio_boleta_url'].toString(),
                          ),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Ver boleta del frasco'),
                        ),
                      if (p['envase_recibido_fecha'] != null)
                        const Text('Frasco recibido'),
                    ],
                    if (p['envio_pedido_agencia'] != null)
                      Text(
                        'Envío al cliente: ${p['envio_pedido_agencia']} · guía ${p['envio_pedido_guia'] ?? ''} · S/ ${_dinero(p['envio_pedido_costo'])}',
                      ),
                    if (p['envio_pedido_boleta_url']?.toString().isNotEmpty ==
                        true)
                      TextButton.icon(
                        onPressed: () => _verComprobante(
                          p['envio_pedido_boleta_url'].toString(),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Ver boleta de envío'),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: estados.contains(status) ? status : 'pendiente',
                        items: estados
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: vm.ocupado
                            ? null
                            : (v) => v == null || v == status
                                  ? null
                                  : _cambiarEstadoPedido(p, v),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ),
  );

  Future<void> _cambiarEstadoPedido(
    Map<String, dynamic> pedido,
    String estado,
  ) async {
    final id = (pedido['id'] as num).toInt();
    final actual = pedido['estado']?.toString();
    if (estado == 'enviado') {
      final agencia = TextEditingController();
      final guia = TextEditingController();
      final costo = TextEditingController();
      XFile? comprobante;
      final formKey = GlobalKey<FormState>();
      final datos = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('Registrar envío del pedido'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'El cliente asume el costo del envío. Adjunta la boleta para que pueda consultarla.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: agencia,
                      decoration: const InputDecoration(
                        labelText: 'Agencia de envío',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    TextFormField(
                      controller: guia,
                      decoration: const InputDecoration(
                        labelText: 'Código o guía',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    TextFormField(
                      controller: costo,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Costo de envío (S/)',
                      ),
                      validator: (v) =>
                          (double.tryParse((v ?? '').replaceAll(',', '.')) ??
                                  -1) <
                              0
                          ? 'Ingresa un costo válido'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _selectorImagen(
                      editorContext: dialogContext,
                      imagen: comprobante,
                      etiquetaGaleria: 'Adjuntar boleta *',
                      alSeleccionar: (image) =>
                          refresh(() => comprobante = image),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false) ||
                      comprobante == null) {
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'agencia': agencia.text.trim(),
                    'guia': guia.text.trim(),
                    'costo': costo.text.trim().replaceAll(',', '.'),
                  });
                },
                child: const Text('Registrar envío'),
              ),
            ],
          ),
        ),
      );
      if (datos == null || comprobante == null || !mounted) return;
      await vm.registrarEnvioPedido(
        id: id,
        fields: datos,
        imagePath: comprobante!.path,
      );
      return;
    }
    if (estado == 'procesando' &&
        actual == 'esperando_envase' &&
        pedido['tiene_envase_cliente'] == true) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmar recepción del frasco'),
          content: const Text(
            'Al continuar confirmas que la empresa recibió físicamente los frascos enviados por el cliente y el pedido puede pasar a preparación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmar recepción'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    await vm.actualizarPedido(id, estado);
  }

  void _verComprobante(String url) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: InteractiveViewer(
        child: Image.network(
          url,
          errorBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No se pudo cargar el comprobante.'),
          ),
        ),
      ),
    ),
  );

  Widget _promociones() => RefreshIndicator(
    onRefresh: vm.cargarTodo,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _encabezado(
          'Promociones',
          'Gestiona las campañas visibles para tus clientes.',
          Icons.campaign_outlined,
          FilledButton.icon(
            onPressed: vm.ocupado ? null : () => _editarPromocion(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva'),
          ),
        ),
        if (vm.promociones.isEmpty)
          const FeedbackPanel(
            icon: Icons.campaign_outlined,
            title: 'Sin promociones',
            message: 'Crea una campaña cuando tengas una oferta disponible.',
          )
        else
          ...vm.promociones.map(
            (p) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  child: SizedBox(
                    width: 42,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_porcentaje(p['descuento_porcentaje'])}%',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                title: Text(p['titulo']?.toString() ?? 'Promoción'),
                subtitle: Text(
                  '${p['activo'] == true ? 'Activa' : 'Inactiva'} · ${p['fecha_inicio'] ?? ''}${p['fecha_fin'] == null ? '' : ' – ${p['fecha_fin']}'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editarPromocion(promo: p);
                    if (v == 'delete') {
                      _confirmarEliminar(
                        'promoción',
                        () => vm.eliminarPromocion((p['id'] as num).toInt()),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _usuarios() => RefreshIndicator(
    onRefresh: vm.cargarTodo,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _encabezado(
          'Usuarios y equipo',
          esAdmin
              ? 'Administra cuentas y accesos del equipo.'
              : 'Consulta las cuentas registradas.',
          Icons.people_outline,
          esAdmin
              ? FilledButton.icon(
                  onPressed: vm.ocupado ? null : _crearEmpleado,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Empleado'),
                )
              : null,
        ),
        if (vm.usuarios.isEmpty)
          const FeedbackPanel(
            icon: Icons.people_outline,
            title: 'Sin usuarios',
            message: 'No hay cuentas para mostrar.',
          )
        else
          ...vm.usuarios.map(
            (u) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (u['nombre']?.toString().characters.firstOrNull ?? '?')
                        .toUpperCase(),
                  ),
                ),
                title: Text(u['nombre']?.toString() ?? ''),
                subtitle: Text(
                  '${u['email'] ?? ''}\n${u['rol'] ?? ''} · ${u['estado'] ?? ''}',
                ),
                isThreeLine: true,
                trailing: esAdmin
                    ? IconButton(
                        tooltip: 'Editar usuario',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editarUsuario(u),
                      )
                    : null,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _sitio() {
    final config = vm.sitio['configuracion'] as Map<String, dynamic>? ?? {};
    final slides = (vm.sitio['carrusel'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return RefreshIndicator(
      onRefresh: vm.cargarTodo,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _encabezado(
            'Contenido de tienda',
            'Textos de marca e imágenes de la portada.',
            Icons.web_outlined,
            FilledButton.icon(
              onPressed: vm.ocupado ? null : () => _editarSitio(config),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ),
          Card(
            child: ListTile(
              leading: _miniatura(config['logo_url']?.toString()),
              title: Text(config['nombre_empresa']?.toString() ?? 'Dulce Miel'),
              subtitle: Text(config['descripcion_inicio']?.toString() ?? ''),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Misión', style: Theme.of(context).textTheme.titleSmall),
                  Text(config['mision']?.toString() ?? '—'),
                  const SizedBox(height: 12),
                  Text('Visión', style: Theme.of(context).textTheme.titleSmall),
                  Text(config['vision']?.toString() ?? '—'),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.recycling_outlined),
              title: const Text('Recepción de frascos propios'),
              subtitle: Text(
                '${config['receptor_envases'] ?? 'Receptor sin configurar'}\n${config['direccion_envases'] ?? 'Dirección sin configurar'}\n${config['telefono_envases'] ?? ''}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 14),
          _encabezado(
            'Carrusel de inicio',
            'Banners activos que aparecen en la portada.',
            Icons.view_carousel_outlined,
            FilledButton.icon(
              onPressed: vm.ocupado ? null : () => _editarSlide(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ),
          if (slides.isEmpty)
            const FeedbackPanel(
              icon: Icons.photo_library_outlined,
              title: 'Sin imágenes',
              message: 'Agrega una imagen para mostrarla en el inicio.',
            )
          else
            ...slides.map(
              (slide) => Card(
                child: ListTile(
                  leading: _miniatura(slide['imagen_url']?.toString()),
                  title: Text(slide['titulo']?.toString() ?? 'Banner'),
                  subtitle: Text(slide['descripcion']?.toString() ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editarSlide(slide: slide);
                      if (value == 'delete') {
                        _confirmarEliminar(
                          'imagen',
                          () => vm.eliminarSlide((slide['id'] as num).toInt()),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editarSitio(Map<String, dynamic> config) async {
    final nombre = TextEditingController(
      text: config['nombre_empresa']?.toString(),
    );
    final descripcion = TextEditingController(
      text: config['descripcion_inicio']?.toString(),
    );
    final mision = TextEditingController(text: config['mision']?.toString());
    final vision = TextEditingController(text: config['vision']?.toString());
    final receptorEnvases = TextEditingController(
      text: config['receptor_envases']?.toString(),
    );
    final direccionEnvases = TextEditingController(
      text: config['direccion_envases']?.toString(),
    );
    final telefonoEnvases = TextEditingController(
      text: config['telefono_envases']?.toString(),
    );
    XFile? logo;
    Map<String, String>? camposGuardados;
    String? rutaLogoGuardada;
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          scrollable: true,
          title: const Text('Editar contenido de marca'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _campo(nombre, 'Nombre de tienda', requerido: true),
                    _campo(
                      descripcion,
                      'Descripción de inicio',
                      requerido: true,
                      maxLines: 2,
                    ),
                    _campo(mision, 'Misión', requerido: true, maxLines: 3),
                    _campo(vision, 'Visión', requerido: true, maxLines: 3),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recepción de frascos propios',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    _campo(receptorEnvases, 'Persona o empresa receptora'),
                    _campo(
                      direccionEnvases,
                      'Dirección para enviar frascos',
                      maxLines: 2,
                    ),
                    _campo(
                      telefonoEnvases,
                      'Teléfono de recepción',
                      teclado: TextInputType.phone,
                    ),
                    _selectorImagen(
                      editorContext: context,
                      imagen: logo,
                      etiquetaGaleria: 'Cambiar logo (opcional)',
                      alSeleccionar: (picked) => setDialog(() => logo = picked),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                camposGuardados = {
                  'nombre_empresa': nombre.text.trim(),
                  'descripcion_inicio': descripcion.text.trim(),
                  'mision': mision.text.trim(),
                  'vision': vision.text.trim(),
                  'receptor_envases': receptorEnvases.text.trim(),
                  'direccion_envases': direccionEnvases.text.trim(),
                  'telefono_envases': telefonoEnvases.text.trim(),
                };
                rutaLogoGuardada = logo?.path;
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (camposGuardados != null) {
      await vm.guardarSitio(camposGuardados!, logoPath: rutaLogoGuardada);
    }
    nombre.dispose();
    descripcion.dispose();
    mision.dispose();
    vision.dispose();
    receptorEnvases.dispose();
    direccionEnvases.dispose();
    telefonoEnvases.dispose();
  }

  Future<void> _editarSlide({Map<String, dynamic>? slide}) async {
    final titulo = TextEditingController(text: slide?['titulo']?.toString());
    final descripcion = TextEditingController(
      text: slide?['descripcion']?.toString(),
    );
    final orden = TextEditingController(
      text: slide?['orden']?.toString() ?? '0',
    );
    var activo = slide?['activo'] == true;
    XFile? imagen;
    Map<String, String>? camposGuardados;
    String? rutaImagenGuardada;
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          scrollable: true,
          title: Text(slide == null ? 'Agregar banner' : 'Editar banner'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(titulo, 'Título', requerido: true),
                _campo(descripcion, 'Descripción'),
                _campo(orden, 'Orden', teclado: TextInputType.number),
                SwitchListTile(
                  value: activo,
                  onChanged: (v) => setDialog(() => activo = v),
                  title: const Text('Activo'),
                ),
                _selectorImagen(
                  editorContext: context,
                  imagen: imagen,
                  etiquetaGaleria: slide == null
                      ? 'Seleccionar imagen *'
                      : 'Cambiar imagen (opcional)',
                  alSeleccionar: (picked) => setDialog(() => imagen = picked),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate() ||
                    (slide == null && imagen == null)) {
                  return;
                }
                camposGuardados = {
                  'titulo': titulo.text.trim(),
                  'descripcion': descripcion.text.trim(),
                  'orden': orden.text.trim(),
                  'activo': activo.toString(),
                };
                rutaImagenGuardada = imagen?.path;
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (camposGuardados != null) {
      await vm.guardarSlide(
        id: (slide?['id'] as num?)?.toInt(),
        fields: camposGuardados!,
        imagePath: rutaImagenGuardada,
      );
    }
    titulo.dispose();
    descripcion.dispose();
    orden.dispose();
  }

  Future<void> _editarProducto({Map<String, dynamic>? producto}) async {
    final nombre = TextEditingController(text: producto?['nombre']?.toString());
    final desc = TextEditingController(
      text: producto?['descripcion']?.toString(),
    );
    final precio = TextEditingController(text: producto?['precio']?.toString());
    final stock = TextEditingController(text: producto?['stock']?.toString());
    final categoria = TextEditingController(
      text: producto?['categoria']?.toString(),
    );
    final opcionesEnvase = (producto?['opciones_envase'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    Map<String, dynamic>? opcion(String codigo) {
      for (final item in opcionesEnvase) {
        if (item['codigo'] == codigo) return item;
      }
      return null;
    }

    final envaseConvencional = opcion('convencional');
    final envaseVidrio = opcion('vidrio_dulcemiel');
    final envasePropio = opcion('frasco_cliente');
    final infoOds = TextEditingController(
      text: producto?['informacion_ods12']?.toString(),
    );
    final descripcionConvencional = TextEditingController(
      text:
          envaseConvencional?['descripcion']?.toString() ??
          'Presentación convencional del producto.',
    );
    final descripcionVidrio = TextEditingController(
      text:
          envaseVidrio?['descripcion']?.toString() ??
          'Frasco de vidrio suministrado por Dulce Miel.',
    );
    final descripcionPropio = TextEditingController(
      text:
          envasePropio?['descripcion']?.toString() ??
          'Envía tu frasco de vidrio limpio para recargarlo.',
    );
    final costoVidrio = TextEditingController(
      text: envaseVidrio?['costo_extra']?.toString() ?? '0',
    );
    var metaOds = producto?['meta_ods12']?.toString() ?? '12.5';
    var vidrioActivo = envaseVidrio?['activo'] == true;
    var frascoPropioActivo = envasePropio?['activo'] == true;
    var estado = producto?['estado']?.toString() ?? 'disponible';
    XFile? imagen;
    Map<String, String>? camposGuardados;
    String? rutaImagenGuardada;
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          scrollable: true,
          title: Text(producto == null ? 'Nuevo producto' : 'Editar producto'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _campo(
                      nombre,
                      'Nombre',
                      requerido: true,
                      labelArriba: true,
                    ),
                    _campo(desc, 'Descripción', maxLines: 3, labelArriba: true),
                    _campo(
                      precio,
                      'Precio',
                      teclado: TextInputType.number,
                      labelArriba: true,
                    ),
                    _campo(
                      stock,
                      'Stock',
                      teclado: TextInputType.number,
                      labelArriba: true,
                    ),
                    _campo(categoria, 'Categoría', labelArriba: true),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Opciones de envase',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _campo(
                      descripcionConvencional,
                      'Descripción del envase convencional',
                      maxLines: 2,
                      labelArriba: true,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: vidrioActivo,
                      onChanged: (value) =>
                          setDialog(() => vidrioActivo = value),
                      title: const Text(
                        'Ofrecer frasco de vidrio de la tienda',
                      ),
                    ),
                    if (vidrioActivo) ...[
                      _campo(
                        costoVidrio,
                        'Costo adicional del frasco (S/)',
                        teclado: TextInputType.number,
                        labelArriba: true,
                      ),
                      _campo(
                        descripcionVidrio,
                        'Descripción del frasco de vidrio',
                        maxLines: 2,
                        labelArriba: true,
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: frascoPropioActivo,
                      onChanged: (value) =>
                          setDialog(() => frascoPropioActivo = value),
                      title: const Text('Permitir recarga en frasco propio'),
                    ),
                    if (frascoPropioActivo)
                      _campo(
                        descripcionPropio,
                        'Condiciones del frasco propio',
                        maxLines: 2,
                        labelArriba: true,
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Información ODS 12',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _campo(
                      infoOds,
                      'Información breve de consumo responsable',
                      maxLines: 3,
                      maxLength: 700,
                      labelArriba: true,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: metaOds,
                      decoration: const InputDecoration(
                        labelText: 'Meta relacionada',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '12.5',
                          child: Text('12.5 · Reutilizar y reducir residuos'),
                        ),
                        DropdownMenuItem(
                          value: '12.8',
                          child: Text(
                            '12.8 · Información para consumo sostenible',
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialog(() => metaOds = value ?? metaOds),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Estado del producto',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: estado,
                      decoration: const InputDecoration(
                        hintText: 'Selecciona un estado',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['disponible', 'agotado', 'discontinuado']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setDialog(() => estado = v ?? estado),
                    ),
                    const SizedBox(height: 8),
                    _selectorImagen(
                      editorContext: context,
                      imagen: imagen,
                      etiquetaGaleria: producto?['imagen_url'] == null
                          ? 'Seleccionar imagen (opcional)'
                          : 'Cambiar imagen',
                      alSeleccionar: (picked) =>
                          setDialog(() => imagen = picked),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                camposGuardados = {
                  'nombre': nombre.text.trim(),
                  'descripcion': desc.text.trim(),
                  'precio': precio.text.trim().replaceAll(',', '.'),
                  'stock': stock.text.trim(),
                  'categoria': categoria.text.trim(),
                  'estado': estado,
                  'descripcion_envase_convencional': descripcionConvencional
                      .text
                      .trim(),
                  'frasco_vidrio_activo': vidrioActivo.toString(),
                  'costo_envase_vidrio': costoVidrio.text.trim().replaceAll(
                    ',',
                    '.',
                  ),
                  'descripcion_envase_vidrio': descripcionVidrio.text.trim(),
                  'frasco_cliente_activo': frascoPropioActivo.toString(),
                  'descripcion_envase_propio': descripcionPropio.text.trim(),
                  'informacion_ods12': infoOds.text.trim(),
                  'meta_ods12': infoOds.text.trim().isEmpty ? '' : metaOds,
                };
                rutaImagenGuardada = imagen?.path;
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (camposGuardados != null) {
      await vm.guardarProducto(
        id: (producto?['id'] as num?)?.toInt(),
        imagePath: rutaImagenGuardada,
        campos: camposGuardados!,
      );
    }
    nombre.dispose();
    desc.dispose();
    precio.dispose();
    stock.dispose();
    categoria.dispose();
    infoOds.dispose();
    descripcionConvencional.dispose();
    descripcionVidrio.dispose();
    descripcionPropio.dispose();
    costoVidrio.dispose();
  }

  Future<void> _editarPromocion({Map<String, dynamic>? promo}) async {
    final titulo = TextEditingController(text: promo?['titulo']?.toString());
    final desc = TextEditingController(text: promo?['descripcion']?.toString());
    final descuento = TextEditingController(
      text: promo?['descuento_porcentaje']?.toString(),
    );
    final inicio = TextEditingController(
      text: _fechaInput(promo?['fecha_inicio']),
    );
    final fin = TextEditingController(text: _fechaInput(promo?['fecha_fin']));
    var activo = promo?['activo'] == true;
    final key = GlobalKey<FormState>();
    final camposGuardados = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          scrollable: true,
          title: Text(promo == null ? 'Nueva promoción' : 'Editar promoción'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _campo(titulo, 'Título', requerido: true),
                    _campo(desc, 'Descripción', maxLines: 2),
                    _campo(
                      descuento,
                      'Descuento (%)',
                      requerido: true,
                      teclado: TextInputType.number,
                    ),
                    _campo(
                      inicio,
                      'Fecha inicio (AAAA-MM-DD)',
                      requerido: true,
                    ),
                    _campo(fin, 'Fecha fin (opcional)', hint: 'AAAA-MM-DD'),
                    SwitchListTile(
                      value: activo,
                      onChanged: (v) => setDialog(() => activo = v),
                      title: const Text('Promoción activa'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'titulo': titulo.text.trim(),
                  'descripcion': desc.text.trim(),
                  'descuento_porcentaje':
                      double.tryParse(descuento.text.replaceAll(',', '.')) ?? 0,
                  'fecha_inicio': inicio.text.trim(),
                  'fecha_fin': fin.text.trim().isEmpty ? null : fin.text.trim(),
                  'activo': activo,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    titulo.dispose();
    desc.dispose();
    descuento.dispose();
    inicio.dispose();
    fin.dispose();
    if (camposGuardados != null && mounted) {
      await vm.guardarPromocion(
        id: (promo?['id'] as num?)?.toInt(),
        body: camposGuardados,
      );
    }
  }

  Future<void> _crearEmpleado() async {
    final nombre = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    var rol = 'empleado';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          scrollable: true,
          title: const Text('Crear acceso del equipo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(nombre, 'Nombre', requerido: true),
                _campo(
                  email,
                  'Correo',
                  requerido: true,
                  teclado: TextInputType.emailAddress,
                ),
                _campo(
                  password,
                  'Contraseña temporal',
                  requerido: true,
                  oculto: true,
                ),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const ['empleado', 'admin']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setDialog(() => rol = v ?? rol),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                vm.crearEmpleado({
                  'nombre': nombre.text.trim(),
                  'email': email.text.trim(),
                  'password': password.text,
                  'rol': rol,
                });
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    nombre.dispose();
    email.dispose();
    password.dispose();
  }

  Future<void> _editarUsuario(Map<String, dynamic> user) async {
    final nombre = TextEditingController(text: user['nombre']?.toString());
    final email = TextEditingController(text: user['email']?.toString());
    var rol = user['rol']?.toString() ?? 'usuario';
    var estado = user['estado']?.toString() ?? 'activo';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          scrollable: true,
          title: Text('Editar ${user['nombre']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(nombre, 'Nombre', requerido: true),
                _campo(
                  email,
                  'Correo',
                  requerido: true,
                  teclado: TextInputType.emailAddress,
                ),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const ['usuario', 'empleado', 'admin']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setDialog(() => rol = v ?? rol),
                ),
                DropdownButtonFormField<String>(
                  initialValue: estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const ['activo', 'inactivo']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setDialog(() => estado = v ?? estado),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                vm.actualizarUsuario((user['id'] as num).toInt(), {
                  'nombre': nombre.text.trim(),
                  'email': email.text.trim(),
                  'rol': rol,
                  'estado': estado,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    nombre.dispose();
    email.dispose();
  }

  Future<void> _confirmarEliminar(
    String nombre,
    Future<void> Function() eliminar,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Eliminar $nombre'),
        content: const Text('¿Confirmas esta acción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await eliminar();
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    bool requerido = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? teclado,
    String? hint,
    bool oculto = false,
    bool labelArriba = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelArriba) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              requerido ? '$label *' : label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: c,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: teclado,
          obscureText: oculto,
          decoration: InputDecoration(
            labelText: labelArriba ? null : label,
            hintText: hint,
            alignLabelWithHint: maxLines > 1,
            errorMaxLines: 2,
          ),
          validator: requerido
              ? (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null
              : null,
        ),
      ],
    ),
  );
  Widget _encabezado(
    String title,
    String subtitle,
    IconData icon,
    Widget? action,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final intro = PageIntro(title: title, subtitle: subtitle, icon: icon);
      if (action == null) return intro;
      if (constraints.maxWidth < 400) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              intro,
              Align(alignment: Alignment.centerRight, child: action),
            ],
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: intro),
          Padding(padding: const EdgeInsets.only(top: 3), child: action),
        ],
      );
    },
  );
  Widget _miniatura(String? url) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 52,
      height: 52,
      child: url == null || url.isEmpty
          ? const ColoredBox(
              color: Color(0xFFFFF1CE),
              child: Icon(Icons.hive_outlined),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFFFF1CE),
                child: Icon(Icons.hive_outlined),
              ),
            ),
    ),
  );
  String _dinero(dynamic value) =>
      (double.tryParse('$value') ?? 0).toStringAsFixed(2);
  String _porcentaje(dynamic value) {
    final number = double.tryParse('$value') ?? 0;
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toString();
  }

  String _fechaInput(dynamic value) => value == null
      ? ''
      : value.toString().substring(
          0,
          value.toString().length >= 10 ? 10 : value.toString().length,
        );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}
