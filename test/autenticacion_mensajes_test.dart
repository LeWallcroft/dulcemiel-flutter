// Pruebas de los mensajes de error de autenticación que ve el usuario.
import 'package:dulce_miel_flutter/network/api_service.dart';
import 'package:dulce_miel_flutter/repositories/autenticacion_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mensajeErrorAutenticacion', () {
    test('PU-20 credenciales incorrectas muestran un mensaje genérico seguro', () {
      for (final code in ['invalid-credential', 'wrong-password', 'user-not-found']) {
        expect(
          mensajeErrorAutenticacion(FirebaseAuthException(code: code)),
          'Correo o contraseña incorrectos.',
        );
      }
    });

    test('PU-21 contraseña débil y correo inválido tienen mensajes propios', () {
      expect(mensajeErrorAutenticacion(FirebaseAuthException(code: 'weak-password')),
          contains('al menos 6 caracteres'));
      expect(mensajeErrorAutenticacion(FirebaseAuthException(code: 'invalid-email')),
          'Escribe un correo válido.');
    });

    test('PU-22 sin red se indica revisar la conexión', () {
      expect(
        mensajeErrorAutenticacion(FirebaseAuthException(code: 'network-request-failed')),
        contains('Revisa tu red'),
      );
    });

    test('PU-23 los errores del API conservan el mensaje del servidor', () {
      expect(mensajeErrorAutenticacion(const ApiException('Usuario bloqueado')),
          'Usuario bloqueado');
    });
  });
}
