import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../network/api_service.dart';
import '../repositories/catalogo_repository.dart';
import '../repositories/carrito_repository.dart';
import '../viewmodels/carrito_view_model.dart';
import '../viewmodels/catalogo_view_model.dart';
import 'widgets/ui_components.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({
    super.key,
    required this.apiService,
    this.initialSearch = '',
    this.initialCategory = '',
    this.initialProduct,
    this.carritoViewModel,
    this.onGoToCart,
  });

  final ApiService apiService;
  final String initialSearch;
  final String initialCategory;
  final Producto? initialProduct;
  final CarritoViewModel? carritoViewModel;
  final VoidCallback? onGoToCart;

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late final CatalogoViewModel _viewModel;
  late final CarritoViewModel _carritoViewModel;
  late final bool _creaCarritoViewModel;
  late final TextEditingController _busquedaController;
  String _busqueda = '';
  String _categoria = '';

  @override
  void initState() {
    super.initState();
    _viewModel = CatalogoViewModel(CatalogoRepository(widget.apiService));
    _creaCarritoViewModel = widget.carritoViewModel == null;
    _carritoViewModel =
        widget.carritoViewModel ??
        CarritoViewModel(CarritoRepository(widget.apiService));
    _busquedaController = TextEditingController(text: widget.initialSearch);
    _busqueda = widget.initialSearch;
    _categoria = widget.initialCategory;
    _viewModel.cargar();
    if (widget.initialProduct != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarDetalle(context, widget.initialProduct!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant CatalogoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSearch != widget.initialSearch) {
      _busquedaController.text = widget.initialSearch;
      _busqueda = widget.initialSearch;
    }
    if (oldWidget.initialCategory != widget.initialCategory) {
      _categoria = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    if (_creaCarritoViewModel) _carritoViewModel.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.cargando && _viewModel.productos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.error != null && _viewModel.productos.isEmpty) {
            return _MensajeCatalogo(
              mensaje: _viewModel.error!,
              accion: _viewModel.cargar,
            );
          }
          if (_viewModel.cargado && _viewModel.productos.isEmpty) {
            return const FeedbackPanel(
              icon: Icons.inventory_2_outlined,
              title: 'Catálogo vacío',
              message: 'Aún no hay productos disponibles.',
            );
          }
          final categorias =
              _viewModel.productos
                  .map((producto) => producto.categoria.trim())
                  .where((categoria) => categoria.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final productos = _viewModel.productos
              .where((producto) {
                final coincideTexto =
                    _busqueda.isEmpty ||
                    '${producto.nombre} ${producto.descripcion} ${producto.categoria}'
                        .toLowerCase()
                        .contains(_busqueda.toLowerCase());
                final coincideCategoria =
                    _categoria.isEmpty || producto.categoria == _categoria;
                return coincideTexto && coincideCategoria;
              })
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: _viewModel.cargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                const PageIntro(
                  title: 'Tienda',
                  subtitle: 'Encuentra tus productos favoritos de la colmena.',
                  icon: Icons.storefront_outlined,
                ),
                TextField(
                  controller: _busquedaController,
                  onChanged: (value) =>
                      setState(() => _busqueda = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() => _busqueda = '');
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Limpiar búsqueda',
                          ),
                  ),
                ),
                if (categorias.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: _categoria.isEmpty,
                            onSelected: (_) => setState(() => _categoria = ''),
                          ),
                        ),
                        ...categorias.map(
                          (categoria) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(categoria),
                              selected: _categoria == categoria,
                              onSelected: (_) =>
                                  setState(() => _categoria = categoria),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  '${productos.length} productos',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                if (productos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: FeedbackPanel(
                      icon: Icons.search_off,
                      title: 'No encontramos resultados',
                      message: 'Prueba otra búsqueda o selecciona una categoría distinta.',
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .66,
                        ),
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      return _TarjetaProducto(
                        producto: producto,
                        ocupado: _carritoViewModel.ocupado,
                        alSeleccionar: () => _mostrarDetalle(context, producto),
                        alAgregar: () => _agregarProducto(producto),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _agregarProducto(Producto producto) async {
    await _carritoViewModel.agregar(producto.id);
    if (!mounted) return;
    final error = _carritoViewModel.error;
    if (error == null) {
      final irAlCarrito = await mostrarDialogoProductoAgregado(
        context,
        nombre: producto.nombre,
        cantidad: 1,
      );
      if (irAlCarrito == true && mounted) widget.onGoToCart?.call();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _mostrarDetalle(BuildContext context, Producto producto) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final imageUrl = producto.imagenUrl?.trim();
        final opciones = producto.opcionesEnvase.isEmpty
            ? const [
                OpcionEnvase(
                  codigo: 'convencional',
                  nombre: 'Envase convencional',
                  descripcion: 'Presentación convencional del producto.',
                  costoExtra: 0,
                ),
              ]
            : producto.opcionesEnvase;
        var envase = opciones.firstWhere(
          (opcion) => opcion.codigo == 'convencional',
          orElse: () => opciones.first,
        );
        var cantidad = producto.stock > 0 ? 1 : 0;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => FractionallySizedBox(
            heightFactor: .92,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AspectRatio(
                          aspectRatio: 1.45,
                          child: imageUrl == null || imageUrl.isEmpty
                              ? const _ImagenProductoVacia()
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const _ImagenProductoVacia(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          if (producto.categoria.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                producto.categoria,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: colors.onSecondaryContainer,
                                    ),
                              ),
                            ),
                          const Spacer(),
                          Icon(
                            producto.stock > 0
                                ? Icons.check_circle_outline
                                : Icons.remove_circle_outline,
                            size: 18,
                            color: producto.stock > 0
                                ? const Color(0xFF4F7753)
                                : colors.error,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            producto.stock > 0
                                ? '${producto.stock} disponibles'
                                : 'Agotado',
                            style: Theme.of(sheetContext).textTheme.labelLarge
                                ?.copyWith(
                                  color: producto.stock > 0
                                      ? const Color(0xFF4F7753)
                                      : colors.error,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        producto.nombre,
                        style: Theme.of(sheetContext).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/ ${producto.precio.toStringAsFixed(2)}',
                        style: Theme.of(sheetContext).textTheme.headlineMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Acerca de este producto',
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        producto.descripcion.trim().isEmpty
                            ? 'Consulta la disponibilidad de este producto con nuestro equipo.'
                            : producto.descripcion,
                        style: Theme.of(sheetContext).textTheme.bodyLarge
                            ?.copyWith(height: 1.5),
                      ),
                      if (producto.informacionOds12.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: colors.secondaryContainer.withValues(
                            alpha: .55,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consumo responsable · ODS ${producto.metaOds12 ?? '12'}',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Text(producto.informacionOds12),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Presentación del envase',
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<OpcionEnvase>(
                        initialValue: envase,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Elige cómo recibir este producto',
                        ),
                        items: opciones
                            .map(
                              (opcion) => DropdownMenuItem(
                                value: opcion,
                                child: Text(
                                  opcion.costoExtra > 0
                                      ? '${opcion.nombre} · + S/ ${opcion.costoExtra.toStringAsFixed(2)}'
                                      : opcion.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => envase = value);
                          }
                        },
                      ),
                      const SizedBox(height: 7),
                      Text(
                        envase.descripcion,
                        style: Theme.of(sheetContext).textTheme.bodySmall,
                      ),
                      if (envase.usaFrascoCliente) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Debes enviar tu frasco a Dulce Miel y asumir el costo de ese envío y el del pedido preparado. La dirección y el comprobante se solicitan al confirmar.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Cantidad',
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: cantidad <= 1
                                ? null
                                : () => setSheetState(() => cantidad--),
                            icon: const Icon(Icons.remove),
                            tooltip: 'Quitar una unidad',
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '$cantidad',
                              textAlign: TextAlign.center,
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleLarge,
                            ),
                          ),
                          IconButton.outlined(
                            onPressed: cantidad >= producto.stock
                                ? null
                                : () => setSheetState(() => cantidad++),
                            icon: const Icon(Icons.add),
                            tooltip: 'Agregar una unidad',
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Máximo ${producto.stock} unidades',
                              textAlign: TextAlign.end,
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _carritoViewModel,
                  builder: (context, _) => Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total'),
                              Text(
                                'S/ ${((producto.precio + envase.costoExtra) * cantidad).toStringAsFixed(2)}',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _carritoViewModel.ocupado || cantidad <= 0
                                  ? null
                                  : () async {
                                      await _carritoViewModel.agregar(
                                        producto.id,
                                        cantidad: cantidad,
                                        opcionEnvaseId: envase.id,
                                      );
                                      if (!sheetContext.mounted) return;
                                      final error = _carritoViewModel.error;
                                      if (error != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(content: Text(error)),
                                            );
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      final irAlCarrito =
                                          await mostrarDialogoProductoAgregado(
                                            context,
                                            nombre: producto.nombre,
                                            cantidad: cantidad,
                                          );
                                      if (irAlCarrito == true && mounted) {
                                        widget.onGoToCart?.call();
                                      }
                                    },
                              icon: Icon(
                                _carritoViewModel.ocupado
                                    ? Icons.hourglass_top
                                    : Icons.add_shopping_cart,
                              ),
                              label: Text(
                                _carritoViewModel.ocupado
                                    ? 'Agregando…'
                                    : producto.stock <= 0
                                    ? 'Producto agotado'
                                    : 'Agregar al carrito',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImagenProductoVacia extends StatelessWidget {
  const _ImagenProductoVacia();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFFFF1CE),
    child: Center(
      child: Icon(Icons.hive_outlined, size: 76, color: Color(0xFF8A620C)),
    ),
  );
}

class _MensajeCatalogo extends StatelessWidget {
  const _MensajeCatalogo({required this.mensaje, this.accion});

  final String mensaje;
  final VoidCallback? accion;

  @override
  Widget build(BuildContext context) => FeedbackPanel(
    icon: Icons.wifi_off_rounded,
    title: 'No se pudo cargar el catálogo',
    message: mensaje,
    actionLabel: accion == null ? null : 'Reintentar',
    onAction: accion,
  );
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({
    required this.producto,
    required this.ocupado,
    required this.alSeleccionar,
    required this.alAgregar,
  });

  final Producto producto;
  final bool ocupado;
  final VoidCallback alSeleccionar;
  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: alSeleccionar,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  producto.imagenUrl == null
                      ? const ColoredBox(
                          color: Color(0xFFFFF1CE),
                          child: Icon(
                            Icons.hive_outlined,
                            size: 48,
                            color: Color(0xFF8A620C),
                          ),
                        )
                      : Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFFFF1CE),
                            child: Icon(
                              Icons.hive_outlined,
                              size: 48,
                              color: Color(0xFF8A620C),
                            ),
                          ),
                        ),
                  if (producto.categoria.isNotEmpty)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          producto.categoria,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF634500),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 7, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: alSeleccionar,
                  child: Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(height: 1.15),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'S/ ${producto.precio.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF634500),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        producto.stock > 0 ? 'Disponible' : 'Agotado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: producto.stock > 0
                              ? const Color(0xFF4F7753)
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: ocupado || producto.stock <= 0
                          ? null
                          : alAgregar,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Agregar al carrito',
                      icon: const Icon(
                        Icons.add_shopping_cart_outlined,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
