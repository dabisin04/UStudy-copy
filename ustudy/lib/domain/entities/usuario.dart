class Usuario {
  final String localId;
  final String? remoteId;
  final String nombre;
  final String correo;
  final DateTime lastModified;
  final String syncStatus;
  final String? uId;

  Usuario({
    required this.localId,
    this.remoteId,
    required this.nombre,
    required this.correo,
    required this.lastModified,
    required this.syncStatus,
    this.uId,
  });

  static Future<Map<String, dynamic>> toDb(Usuario usuario) async {
    return {
      'local_id': usuario.localId,
      'remote_id': usuario.remoteId,
      'nombre': usuario.nombre,
      'correo': usuario.correo,
      'last_modified': usuario.lastModified.toIso8601String(),
      'sync_status': usuario.syncStatus,
      'u_id': usuario.uId,
    };
  }

  static Future<Usuario> fromDb(Map<String, dynamic> json) async {
    return Usuario(
      localId: json['local_id'],
      remoteId: json['remote_id'],
      nombre: json['nombre'],
      correo: json['correo'],
      lastModified: DateTime.parse(json['last_modified']),
      syncStatus: json['sync_status'],
      uId: json['u_id'],
    );
  }
}
