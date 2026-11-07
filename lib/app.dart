import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'network/api_service.dart';
import 'repositories/autenticacion_repository.dart';
import 'repositories/sesion_repository.dart';
import 'screens/inicio_screen.dart';

class DulceMielApp extends StatelessWidget {
  const DulceMielApp({
    super.key,
    required this.apiService,
    required this.autenticacionRepository,
    required this.sesionRepository,
  });

  final ApiService apiService;
  final AutenticacionRepository autenticacionRepository;
  final SesionRepository sesionRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dulce Miel',
      debugShowCheckedModeBanner: false,
      theme: buildDulceMielTheme(),
      home: InicioScreen(
        apiService: apiService,
        autenticacionRepository: autenticacionRepository,
        sesionRepository: sesionRepository,
      ),
    );
  }
}
