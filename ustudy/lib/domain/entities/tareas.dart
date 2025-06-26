class Tarea {
  final String id;
  final String usuarioLocalId;
  final String titulo;
  final String? descripcion;
  final bool completada;
  final String lastModified;
  final String syncStatus;
  final String prioridad;
  final DateTime? fechaRecordatorio;
  final String origen;

  Tarea({
    required this.id,
    required this.usuarioLocalId,
    required this.titulo,
    this.descripcion,
    required this.completada,
    required this.lastModified,
    required this.syncStatus,
    this.prioridad = 'media',
    this.fechaRecordatorio,
    this.origen = 'usuario',
  });

  factory Tarea.fromMap(Map<String, dynamic> map) {
    print('🔧 [TAREA] fromMap - Datos recibidos: $map');

    try {
      return Tarea(
        id: map['id']?.toString() ?? '',
        usuarioLocalId:
            map['usuario_local_id'] ?? map['usuario_id']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? '',
        descripcion: map['descripcion']?.toString(),
        completada: map['completado'] == 1 || map['completada'] == true,
        lastModified:
            map['last_modified'] ??
            map['fecha_actualizacion']?.toString() ??
            DateTime.now().toIso8601String(),
        syncStatus:
            map['sync_status'] ??
            (map['sincronizada'] == true ? 'synced' : 'pending'),
        prioridad: map['prioridad']?.toString() ?? 'media',
        fechaRecordatorio: map['fecha_recordatorio'] != null
            ? DateTime.tryParse(map['fecha_recordatorio'].toString())
            : null,
        origen: map['origen']?.toString() ?? 'usuario',
      );
    } catch (e) {
      print('💥 [TAREA] Error en fromMap: $e');
      print('💥 [TAREA] Map problemático: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioLocalId,
      'titulo': titulo,
      'descripcion': descripcion,
      'completada': completada,
      'sincronizada': syncStatus == 'synced',
      'prioridad': prioridad,
      'fecha_recordatorio': fechaRecordatorio?.toIso8601String(),
      'origen': origen,
      'fecha_creacion': lastModified,
      'fecha_actualizacion': lastModified,
    };
  }

  Map<String, dynamic> toMapLocal() {
    return {
      'id': id,
      'usuario_local_id': usuarioLocalId,
      'titulo': titulo,
      'descripcion': descripcion,
      'completado': completada ? 1 : 0,
      'last_modified': lastModified,
      'sync_status': syncStatus,
      'prioridad': prioridad,
      'fecha_recordatorio': fechaRecordatorio?.toIso8601String(),
      'origen': origen,
    };
  }
}
