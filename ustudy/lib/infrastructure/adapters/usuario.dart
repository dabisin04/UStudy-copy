import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ustudy/core/constants/api.dart';
import 'package:ustudy/domain/entities/usuario.dart';
import 'package:ustudy/domain/repositories/usuario.dart';
import 'package:ustudy/core/services/sqflite.dart';
import 'package:ustudy/infrastructure/utils/session.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  @override
  Future<void> saveUser(Usuario user, String contrasena) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.usuario}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': user.nombre,
        'correo': user.correo,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'];
      throw Exception('Error al registrar usuario: $error');
    }
  }

  @override
  Future<Usuario?> getUserById(String localId) async {
    final db = await SQLiteService.instance;
    final result = await db.query(
      'usuarios',
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    if (result.isEmpty) return null;
    return await Usuario.fromDb(result.first);
  }

  @override
  Future<List<Usuario>> getAllUsers() async {
    final db = await SQLiteService.instance;
    final result = await db.query('usuarios');
    return Future.wait(result.map((e) => Usuario.fromDb(e)));
  }

  @override
  Future<void> updateUser(Usuario user) async {
    final db = await SQLiteService.instance;
    await db.update(
      'usuarios',
      await Usuario.toDb(user),
      where: 'local_id = ?',
      whereArgs: [user.localId],
    );
  }

  @override
  Future<void> deleteUser(String localId) async {
    final db = await SQLiteService.instance;
    await db.delete('usuarios', where: 'local_id = ?', whereArgs: [localId]);
  }

  @override
  Future<void> deleteAllUsers() async {
    final db = await SQLiteService.instance;
    await db.delete('usuarios');
  }

  @override
  Future<Usuario?> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.usuario}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    final userJson = data['usuario'];

    if (userJson == null) {
      throw Exception(
        'Respuesta del servidor inválida: usuario no encontrado en la respuesta',
      );
    }

    final user = Usuario(
      localId: userJson['id'],
      remoteId: userJson['id'],
      nombre: userJson['nombre'],
      correo: userJson['correo'],
      lastModified: DateTime.now(),
      syncStatus: 'synced',
      uId: userJson['u_id'],
    );

    // guardar localmente cifrado
    final db = await SQLiteService.instance;
    await db.insert('usuarios', await Usuario.toDb(user));

    return user;
  }

  @override
  Future<void> updateUId(String localId, String uId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.usuario}/$localId/u_id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'u_id': uId}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar al actualizar su universidad: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final userJson = data['usuario'];

    if (userJson == null) {
      throw Exception(
        'Respuesta del servidor inválida: usuario no encontrado en la respuesta',
      );
    }

    final user = Usuario(
      localId: userJson['id'],
      remoteId: userJson['id'],
      nombre: userJson['nombre'],
      correo: userJson['correo'],
      lastModified: DateTime.now(),
      syncStatus: 'synced',
      uId: userJson['u_id'],
    );

    final db = await SQLiteService.instance;
    await db.update(
      'usuarios',
      await Usuario.toDb(user),
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    // Update session with new uId
    await SessionService.saveUserSession(
      localId: user.localId,
      remoteId: user.remoteId,
      nombre: user.nombre,
      correo: user.correo,
      uId: user.uId,
    );
  }

  @override
  Future<void> changePassword(
    String localId,
    String currentPassword,
    String newPassword,
  ) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.usuario}/$localId/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contrasena_actual': currentPassword,
        'contrasena_nueva': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'];
      throw Exception('Error al cambiar contraseña: $error');
    }
  }

  @override
  Future<String?> getCurrentUId(String localId) async {
    final db = await SQLiteService.instance;
    final result = await db.query(
      'usuarios',
      columns: ['u_id'],
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    if (result.isEmpty) return null;
    return result.first['u_id'] as String?;
  }
}
