import 'package:ustudy/domain/entities/usuario.dart';

abstract class UsuarioRepository {
  Future<void> saveUser(Usuario user, String contrasena);
  Future<Usuario?> login(String correo, String contrasena);
  Future<Usuario?> getUserById(String localId);
  Future<List<Usuario>> getAllUsers();
  Future<void> updateUser(Usuario user);
  Future<void> deleteUser(String localId);
  Future<void> deleteAllUsers();
  Future<void> updateUId(String localId, String uId);
}
