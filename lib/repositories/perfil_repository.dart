import '../models/perfil_usuario.dart';
import 'autenticacion_repository.dart';

class PerfilRepository {
  const PerfilRepository(this._autenticacionRepository);
  final AutenticacionRepository _autenticacionRepository;

  Future<PerfilUsuario> cargar() async =>
      PerfilUsuario.fromJson(await _autenticacionRepository.consultarPerfil());
}
