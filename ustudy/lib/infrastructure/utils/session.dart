import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _localIdKey = 'usuario_local_id';
  static const String _remoteIdKey = 'usuario_remote_id';
  static const String _userNombreKey = 'usuario_nombre';
  static const String _userCorreoKey = 'usuario_correo';

  /// Guarda los datos del usuario en sesión
  static Future<void> saveUserSession({
    required String localId,
    required String? remoteId,
    required String nombre,
    required String correo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localIdKey, localId);
    if (remoteId != null) {
      await prefs.setString(_remoteIdKey, remoteId);
    }
    await prefs.setString(_userNombreKey, nombre);
    await prefs.setString(_userCorreoKey, correo);
  }

  /// Elimina todos los datos de sesión
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localIdKey);
    await prefs.remove(_remoteIdKey);
    await prefs.remove(_userNombreKey);
    await prefs.remove(_userCorreoKey);
  }

  /// Verifica si hay sesión activa
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_localIdKey);
  }

  /// Recupera los datos del usuario actual
  static Future<Map<String, String>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_localIdKey)) return null;

    return {
      'localId': prefs.getString(_localIdKey)!,
      'remoteId': prefs.getString(_remoteIdKey) ?? '',
      'nombre': prefs.getString(_userNombreKey)!,
      'correo': prefs.getString(_userCorreoKey)!,
    };
  }
}
