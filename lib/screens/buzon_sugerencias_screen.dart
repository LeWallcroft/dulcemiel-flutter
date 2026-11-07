import 'package:flutter/material.dart';

import '../firebase/firebase_auth_manager.dart';
import '../firebase/firestore_repository.dart';
import '../repositories/sugerencias_repository.dart';
import '../viewmodels/buzon_sugerencias_view_model.dart';
import 'widgets/ui_components.dart';

class BuzonSugerenciasScreen extends StatefulWidget {
  const BuzonSugerenciasScreen({super.key});

  @override
  State<BuzonSugerenciasScreen> createState() => _BuzonSugerenciasScreenState();
}

class _BuzonSugerenciasScreenState extends State<BuzonSugerenciasScreen> {
  final _mensajeController = TextEditingController();
  late final BuzonSugerenciasViewModel _viewModel;
  String _categoria = SugerenciasRepository.categorias.first;

  @override
  void initState() {
    super.initState();
    _viewModel = BuzonSugerenciasViewModel(
      SugerenciasRepository(
        autenticacion: FirebaseAuthManager(),
        firestore: FirestoreRepository(),
      ),
    );
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buzón de sugerencias')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageIntro(
              title: 'Tu opinión importa',
              subtitle: 'Cuéntanos cómo mejorar tu experiencia con Dulce Miel.',
              icon: Icons.chat_bubble_outline,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: SugerenciasRepository.categorias
                          .map(
                            (categoria) => DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria),
                            ),
                          )
                          .toList(),
                      onChanged: _viewModel.enviando
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _categoria = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mensajeController,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 1000,
                      enabled: !_viewModel.enviando,
                      decoration: const InputDecoration(
                        labelText: 'Tu sugerencia',
                        hintText: 'Escribe entre 10 y 1000 caracteres',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_viewModel.error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_viewModel.confirmacion case final confirmacion?) ...[
              const SizedBox(height: 8),
              Text(
                confirmacion,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _viewModel.enviando
                  ? null
                  : () => _viewModel.enviar(
                      mensaje: _mensajeController.text,
                      categoria: _categoria,
                    ),
              icon: _viewModel.enviando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _viewModel.enviando ? 'Enviando…' : 'Enviar sugerencia',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
