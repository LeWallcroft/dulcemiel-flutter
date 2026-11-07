import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'firebase/firebase_auth_manager.dart';
import 'firebase/perfil_firestore_repository.dart';
import 'firebase_options.dart';
import 'network/api_service.dart';
import 'repositories/autenticacion_repository.dart';
import 'repositories/sesion_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api/',
  );
  final sesiones = SesionRepository(const FlutterSecureStorage());
  final apiService = ApiService(
    baseUrl: baseUrl,
    tokenProvider: () async => (await sesiones.leer())?.tokenApi,
  );
  final autenticacion = AutenticacionRepository(
    autenticacion: FirebaseAuthManager(),
    perfiles: PerfilFirestoreRepository(),
    api: apiService,
    sesiones: sesiones,
  );
  runApp(
    DulceMielApp(
      apiService: apiService,
      autenticacionRepository: autenticacion,
      sesionRepository: sesiones,
    ),
  );
}
