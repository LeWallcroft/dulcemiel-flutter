import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/coordenada.dart';
import '../repositories/ubicacion_repository.dart';
import '../viewmodels/ubicacion_view_model.dart';

class MapaUbicacionScreen extends StatefulWidget {
  const MapaUbicacionScreen({
    super.key,
    this.inicial,
    this.soloLectura = false,
  });
  final Coordenada? inicial;
  final bool soloLectura;

  @override
  State<MapaUbicacionScreen> createState() => _MapaUbicacionScreenState();
}

class _MapaUbicacionScreenState extends State<MapaUbicacionScreen> {
  late final UbicacionViewModel _vm;
  GoogleMapController? _controller;
  static const _lima = LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
    _vm = UbicacionViewModel(UbicacionRepository());
    if (widget.inicial != null) {
      _vm.seleccionar(widget.inicial!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ubicación de entrega')),
    body: AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        final selected = _vm.state.data;
        final position = selected == null
            ? null
            : LatLng(selected.latitud, selected.longitud);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Toca el mapa para marcar dónde recibirás tu pedido. También puedes usar tu ubicación actual.',
                  ),
                  if (_vm.state.hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      _vm.state.message ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (_vm.issue == LocationIssue.deniedForever)
                      TextButton.icon(
                        onPressed: _vm.abrirConfiguracionPermisos,
                        icon: const Icon(Icons.settings),
                        label: const Text('Abrir ajustes de permisos'),
                      ),
                    if (_vm.issue == LocationIssue.serviceDisabled)
                      TextButton.icon(
                        onPressed: _vm.abrirConfiguracionUbicacion,
                        icon: const Icon(Icons.location_searching),
                        label: const Text('Activar ubicación'),
                      ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position ?? _lima,
                  zoom: selected == null ? 12 : 16,
                ),
                onMapCreated: (controller) => _controller = controller,
                onTap: widget.soloLectura
                    ? null
                    : (point) => _vm.seleccionar(
                        Coordenada(
                          latitud: point.latitude,
                          longitud: point.longitude,
                        ),
                      ),
                markers: position == null
                    ? const {}
                    : {
                        Marker(
                          markerId: const MarkerId('ubicacion_entrega'),
                          position: position,
                          draggable: !widget.soloLectura,
                          onDragEnd: widget.soloLectura
                              ? null
                              : (point) => _vm.seleccionar(
                                  Coordenada(
                                    latitud: point.latitude,
                                    longitud: point.longitude,
                                  ),
                                ),
                        ),
                      },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: true,
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selected != null)
                      Text(
                        'Latitud ${selected.latitud.toStringAsFixed(6)} · Longitud ${selected.longitud.toStringAsFixed(6)}',
                        textAlign: TextAlign.center,
                      ),
                    if (widget.soloLectura)
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _vm.state.isLoading
                                  ? null
                                  : () async {
                                      await _vm.usarUbicacionActual();
                                      final position = _vm.state.data;
                                      if (position != null) {
                                        _controller?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                            LatLng(
                                              position.latitud,
                                              position.longitud,
                                            ),
                                            16,
                                          ),
                                        );
                                      }
                                    },
                              icon: _vm.state.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                              label: const Text('Mi ubicación'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: selected == null
                                  ? null
                                  : () => Navigator.of(context).pop(selected),
                              child: const Text('Usar este punto'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
