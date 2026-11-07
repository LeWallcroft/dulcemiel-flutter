import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/estado_api.dart';
import '../models/contenido_tienda.dart';
import '../models/producto.dart';
import '../network/api_service.dart';
import '../repositories/autenticacion_repository.dart';
import '../repositories/carrito_repository.dart';
import '../repositories/catalogo_repository.dart';
import '../repositories/contenido_tienda_repository.dart';
import '../repositories/sesion_repository.dart';
import '../viewmodels/carrito_view_model.dart';
import '../viewmodels/catalogo_view_model.dart';
import '../viewmodels/contenido_tienda_view_model.dart';
import '../viewmodels/inicio_view_model.dart';
import 'acceso_screen.dart';
import 'buzon_sugerencias_screen.dart';
import 'carrito_screen.dart';
import 'catalogo_screen.dart';
import 'pedidos_screen.dart';
import 'ods12_screen.dart';
import 'widgets/ui_components.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({
    super.key,
    required this.apiService,
    required this.autenticacionRepository,
    required this.sesionRepository,
  });

  final ApiService apiService;
  final AutenticacionRepository autenticacionRepository;
  final SesionRepository sesionRepository;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late final InicioViewModel _inicioViewModel;
  late final CatalogoViewModel _catalogoViewModel;
  late final ContenidoTiendaViewModel _contenidoViewModel;
  late final CarritoViewModel _carritoViewModel;
  final _busquedaController = TextEditingController();
  final List<Widget?> _paginas = List<Widget?>.filled(6, null);
  int _indiceSeleccionado = 0;
  final ScrollController _promocionesController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inicioViewModel = InicioViewModel(widget.apiService)..verificarApi();
    _catalogoViewModel = CatalogoViewModel(
      CatalogoRepository(widget.apiService),
    )..cargar();
    _contenidoViewModel = ContenidoTiendaViewModel(
      ContenidoTiendaRepository(widget.apiService),
    )..cargar();
    _carritoViewModel = CarritoViewModel(CarritoRepository(widget.apiService));
    _cargarCarritoSiHaySesion();
    _paginas[0] = _buildHomePage();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _promocionesController.dispose();
    _inicioViewModel.dispose();
    _catalogoViewModel.dispose();
    _contenidoViewModel.dispose();
    _carritoViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _indiceSeleccionado,
      children: List.generate(
        _paginas.length,
        (index) => _paginas[index] ?? const SizedBox.shrink(),
      ),
    ),
    bottomNavigationBar: AnimatedBuilder(
      animation: _carritoViewModel,
      builder: (context, _) => NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: _seleccionarPagina,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Tienda',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _carritoViewModel.cantidadTotal > 0,
              label: Text(
                _carritoViewModel.cantidadTotal > 99
                    ? '99+'
                    : '${_carritoViewModel.cantidadTotal}',
              ),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _carritoViewModel.cantidadTotal > 0,
              label: Text(
                _carritoViewModel.cantidadTotal > 99
                    ? '99+'
                    : '${_carritoViewModel.cantidadTotal}',
              ),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cuenta',
          ),
          const NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco_rounded),
            label: 'ODS 12',
          ),
        ],
      ),
    ),
  );

  void _seleccionarPagina(int indice) {
    if (_paginas[indice] == null) _paginas[indice] = _crearPagina(indice);
    if (indice == 0) {
      // Actualiza las tarjetas al volver del área de administración u otras pantallas.
      _catalogoViewModel.cargar();
      _contenidoViewModel.cargar();
    }
    setState(() => _indiceSeleccionado = indice);
  }

  Widget _crearPagina(int indice) => switch (indice) {
    0 => _buildHomePage(),
    1 => CatalogoScreen(
      apiService: widget.apiService,
      carritoViewModel: _carritoViewModel,
      onGoToCart: () => _seleccionarPagina(2),
    ),
    2 => CarritoScreen(
      apiService: widget.apiService,
      sesionRepository: widget.sesionRepository,
      autenticacionRepository: widget.autenticacionRepository,
      carritoViewModel: _carritoViewModel,
    ),
    3 => PedidosScreen(
      apiService: widget.apiService,
      sesionRepository: widget.sesionRepository,
      autenticacionRepository: widget.autenticacionRepository,
    ),
    4 => AccesoScreen(
      repository: widget.autenticacionRepository,
      apiService: widget.apiService,
      carritoViewModel: _carritoViewModel,
    ),
    5 => const Ods12Screen(),
    _ => const SizedBox.shrink(),
  };

  Widget _buildHomePage() => Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _contenidoViewModel,
        builder: (context, _) {
          final contenido = _contenidoViewModel.contenido;
          return AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 38,
                    height: 38,
                    color: const Color(0xFFFFE8AE),
                    child: contenido?.logoUrl?.isNotEmpty == true
                        ? Image.network(
                            contenido!.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.hive_outlined,
                              color: DulceMielColors.mielProfunda,
                              size: 23,
                            ),
                          )
                        : const Icon(
                            Icons.hive_outlined,
                            color: DulceMielColors.mielProfunda,
                            size: 23,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contenido?.nombre ?? 'Dulce Miel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'De nuestra colmena',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: DulceMielColors.secundaria,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    body: AnimatedBuilder(
      animation: Listenable.merge([
        _inicioViewModel,
        _catalogoViewModel,
        _contenidoViewModel,
      ]),
      builder: (context, _) {
        final productos = _catalogoViewModel.productos;
        final contenido = _contenidoViewModel.contenido;
        final categorias =
            productos
                .map((p) => p.categoria.trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _inicioViewModel.verificarApi(),
              _catalogoViewModel.cargar(),
              _contenidoViewModel.cargar(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              _BuscadorTienda(
                controller: _busquedaController,
                onSearch: _buscar,
              ),
              const SizedBox(height: 16),
              _BannerTienda(
                onTap: _abrirCatalogo,
                title: contenido?.nombre ?? 'Dulce Miel',
                description:
                    contenido?.descripcion ??
                    'Explora nuestra selección de miel y productos apícolas.',
              ),
              const SizedBox(height: 22),
              if (contenido?.carrusel.isNotEmpty == true) ...[
                _CarruselTienda(items: contenido!.carrusel),
                const SizedBox(height: 22),
              ],
              if (contenido?.promociones.isNotEmpty == true) ...[
                _TituloPromociones(
                  controller: _promocionesController,
                  count: contenido!.promociones.length,
                  onSeeStore: _abrirCatalogo,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    controller: _promocionesController,
                    scrollDirection: Axis.horizontal,
                    itemCount: contenido.promociones.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => SizedBox(
                      width: 300,
                      child: _TarjetaPromocion(
                        promo: contenido.promociones[index],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (categorias.isNotEmpty) ...[
                _TituloFila(
                  title: 'Explora por categoría',
                  action: 'Ver tienda',
                  onTap: _abrirCatalogo,
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categorias.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => ActionChip(
                      avatar: const Icon(Icons.hive_outlined, size: 17),
                      label: Text(categorias[index]),
                      onPressed: () =>
                          _abrirCatalogo(categoria: categorias[index]),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              _TituloFila(
                title: 'Productos de la colmena',
                action: 'Ver todos',
                onTap: _abrirCatalogo,
              ),
              const SizedBox(height: 12),
              if (_catalogoViewModel.cargando && productos.isEmpty)
                const SizedBox(
                  height: 190,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_catalogoViewModel.error != null && productos.isEmpty)
                _ErrorTienda(
                  message: _catalogoViewModel.error!,
                  onRetry: _catalogoViewModel.cargar,
                )
              else if (productos.isEmpty)
                const SizedBox(
                  height: 130,
                  child: Center(
                    child: Text('Pronto encontrarás nuestros productos aquí.'),
                  ),
                )
              else
                SizedBox(
                  height: 258,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: productos.length > 6 ? 6 : productos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _ProductoDestacado(
                      producto: productos[index],
                      ocupado: _carritoViewModel.ocupado,
                      onOpen: () => _abrirDetalleProducto(productos[index]),
                      onAdd: () => _agregarAlCarrito(productos[index]),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const PageIntro(
                title: '¿Nos ayudas a mejorar?',
                subtitle: 'Cuéntanos cómo fue tu experiencia.',
                icon: Icons.chat_bubble_outline,
              ),
              _AtajoCliente(
                icon: Icons.chat_bubble_outline,
                title: 'Enviar una sugerencia',
                onTap: _abrirSugerencias,
              ),
              if (contenido?.mision.isNotEmpty == true ||
                  contenido?.vision.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => _mostrarHistoria(contenido!),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Conoce Dulce Miel'),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _EstadoServidor(
                estado: _inicioViewModel.estado,
                mensaje: _inicioViewModel.mensaje,
                onRetry: _inicioViewModel.verificarApi,
              ),
            ],
          ),
        );
      },
    ),
  );

  void _buscar(String value) => _abrirCatalogo(busqueda: value.trim());

  void _abrirCatalogo({String busqueda = '', String categoria = ''}) {
    _paginas[1] = CatalogoScreen(
      apiService: widget.apiService,
      initialSearch: busqueda,
      initialCategory: categoria,
      carritoViewModel: _carritoViewModel,
      onGoToCart: () => _seleccionarPagina(2),
    );
    _seleccionarPagina(1);
  }

  void _abrirDetalleProducto(Producto producto) {
    _paginas[1] = CatalogoScreen(
      key: ValueKey(
        'producto-${producto.id}-${DateTime.now().microsecondsSinceEpoch}',
      ),
      apiService: widget.apiService,
      initialProduct: producto,
      carritoViewModel: _carritoViewModel,
      onGoToCart: () => _seleccionarPagina(2),
    );
    _seleccionarPagina(1);
  }

  void _abrirCuenta() => _seleccionarPagina(4);
  void _abrirSugerencias() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const BuzonSugerenciasScreen()),
  );

  Future<void> _agregarAlCarrito(Producto producto) async {
    await _carritoViewModel.agregar(producto.id);
    if (!mounted) return;
    final error = _carritoViewModel.error;
    if (error?.contains('Inicia sesión') == true) {
      _abrirCuenta();
    } else if (error == null) {
      final irAlCarrito = await mostrarDialogoProductoAgregado(
        context,
        nombre: producto.nombre,
        cantidad: 1,
      );
      if (irAlCarrito == true && mounted) _seleccionarPagina(2);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _cargarCarritoSiHaySesion() async {
    if (await widget.sesionRepository.leer() != null) {
      await _carritoViewModel.cargar();
    }
  }

  Future<void> _mostrarHistoria(
    ContenidoTienda contenido,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PageIntro(
              title: contenido.nombre,
              subtitle: 'Nuestra historia y propósito.',
              icon: Icons.hive_outlined,
            ),
            if (contenido.mision.isNotEmpty) ...[
              Text('Misión', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(contenido.mision),
            ],
            if (contenido.vision.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Visión', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(contenido.vision),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BuscadorTienda extends StatelessWidget {
  const _BuscadorTienda({required this.controller, required this.onSearch});
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textInputAction: TextInputAction.search,
    onSubmitted: onSearch,
    decoration: InputDecoration(
      hintText: 'Buscar miel, propóleo y más',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        tooltip: 'Buscar',
        onPressed: () => onSearch(controller.text),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
    ),
  );
}

class _BannerTienda extends StatelessWidget {
  const _BannerTienda({
    required this.onTap,
    required this.title,
    required this.description,
  });
  final VoidCallback onTap;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Material(
    color: DulceMielColors.mielProfunda,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Icon(
              Icons.hive_outlined,
              size: 170,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'DULCE MIEL · PRODUCTOS APÍCOLAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .65,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Comprar ahora'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE8AE),
                    foregroundColor: DulceMielColors.mielProfunda,
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CarruselTienda extends StatefulWidget {
  const _CarruselTienda({required this.items});
  final List<CarruselTienda> items;

  @override
  State<_CarruselTienda> createState() => _CarruselTiendaState();
}

class _CarruselTiendaState extends State<_CarruselTienda> {
  late final PageController _controller;
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _irA(int pagina) {
    if (pagina < 0 || pagina >= widget.items.length) return;
    _controller.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 176,
    child: Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.items.length,
          onPageChanged: (pagina) => setState(() => _pagina = pagina),
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imagenUrl?.isNotEmpty == true)
                      Image.network(
                        item.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: Color(0xFF8A620C)),
                      )
                    else
                      const ColoredBox(color: Color(0xFF8A620C)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC302B24)],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item.descripcion.isNotEmpty)
                              Text(
                                item.descripcion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.items.length > 1) ...[
          Positioned(
            left: 7,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                tooltip: 'Anterior',
                onPressed: _pagina == 0 ? null : () => _irA(_pagina - 1),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .9),
                ),
              ),
            ),
          ),
          Positioned(
            right: 7,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                tooltip: 'Siguiente',
                onPressed: _pagina == widget.items.length - 1
                    ? null
                    : () => _irA(_pagina + 1),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .9),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _TituloPromociones extends StatelessWidget {
  const _TituloPromociones({
    required this.controller,
    required this.count,
    required this.onSeeStore,
  });

  final ScrollController controller;
  final int count;
  final VoidCallback onSeeStore;

  void _desplazar(double direction) {
    if (!controller.hasClients) return;
    final max = controller.position.maxScrollExtent;
    final target = (controller.offset + direction * 310).clamp(0.0, max);
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Promociones',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      IconButton(
        tooltip: 'Promoción anterior',
        visualDensity: VisualDensity.compact,
        onPressed: count < 2 ? null : () => _desplazar(-1),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      ),
      IconButton(
        tooltip: 'Siguiente promoción',
        visualDensity: VisualDensity.compact,
        onPressed: count < 2 ? null : () => _desplazar(1),
        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
      TextButton(
        onPressed: onSeeStore,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text('Ver tienda'), Icon(Icons.chevron_right, size: 18)],
        ),
      ),
    ],
  );
}

class _TarjetaPromocion extends StatelessWidget {
  const _TarjetaPromocion({required this.promo});
  final PromocionTienda promo;
  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(promo.descuento) ?? 0;
    final discount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFFFE8AE),
          child: FittedBox(
            child: Text(
              '$discount%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        title: Text(promo.titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: promo.descripcion.isEmpty
            ? null
            : Text(
                promo.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

class _TituloFila extends StatelessWidget {
  const _TituloFila({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Text(
        title,
        maxLines: constraints.maxWidth < 360 ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge,
      );
      final link = TextButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(action, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      );
      if (constraints.maxWidth < 360) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            Align(alignment: Alignment.centerRight, child: link),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: heading),
          link,
        ],
      );
    },
  );
}

class _ProductoDestacado extends StatelessWidget {
  const _ProductoDestacado({
    required this.producto,
    required this.ocupado,
    required this.onOpen,
    required this.onAdd,
  });
  final Producto producto;
  final bool ocupado;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final imageUrl = producto.imagenUrl?.trim();
    return SizedBox(
      width: 178,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpen,
              child: SizedBox(
                height: 124,
                width: double.infinity,
                child: imageUrl == null || imageUrl.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFFFF1CE),
                        child: Icon(
                          Icons.hive_outlined,
                          size: 44,
                          color: DulceMielColors.miel,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) =>
                                frame != null || wasSynchronouslyLoaded
                                ? child
                                : const ColoredBox(
                                    color: Color(0xFFFFF1CE),
                                    child: Center(
                                      child: SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFFFF1CE),
                          child: Icon(
                            Icons.hive_outlined,
                            size: 44,
                            color: DulceMielColors.miel,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onOpen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (producto.categoria.isNotEmpty)
                              Text(
                                producto.categoria.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: DulceMielColors.miel,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            Text(
                              producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'S/ ${producto.precio.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: DulceMielColors.mielProfunda,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: ocupado || producto.stock <= 0 ? null : onAdd,
                      tooltip: 'Agregar al carrito',
                      icon: const Icon(
                        Icons.add_shopping_cart_outlined,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtajoCliente extends StatelessWidget {
  const _AtajoCliente({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1CE),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: DulceMielColors.mielProfunda),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _EstadoServidor extends StatelessWidget {
  const _EstadoServidor({
    required this.estado,
    required this.mensaje,
    required this.onRetry,
  });
  final EstadoApi estado;
  final String? mensaje;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        estado == EstadoApi.disponible
            ? Icons.check_circle_outline
            : estado == EstadoApi.error
            ? Icons.error_outline
            : Icons.sync,
        size: 17,
        color: estado == EstadoApi.error
            ? Theme.of(context).colorScheme.error
            : DulceMielColors.hoja,
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          estado == EstadoApi.disponible
              ? 'Tienda conectada'
              : estado == EstadoApi.error
              ? mensaje ?? 'Sin conexión'
              : 'Conectando…',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      if (estado == EstadoApi.error)
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}

class _ErrorTienda extends StatelessWidget {
  const _ErrorTienda({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
        ],
      ),
    ),
  );
}
