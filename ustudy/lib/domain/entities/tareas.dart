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
    return Tarea(
      id: map['id'],
      usuarioLocalId: map['usuario_local_id'],
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      completada: map['completado'] == 1,
      lastModified: map['last_modified'],
      syncStatus: map['sync_status'],
      prioridad: map['prioridad'] ?? 'media',
      fechaRecordatorio: map['fecha_recordatorio'] != null
          ? DateTime.tryParse(map['fecha_recordatorio'])
          : null,
      origen: map['origen'] ?? 'usuario',
    );
  }

  Map<String, dynamic> toMap() {
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
