import 'package:ustudy/domain/entities/tareas.dart';

abstract class TareaRepository {
  Future<List<Tarea>> getTareas(String usuarioId);
  Future<List<Tarea>> getTareasLocal(String usuarioLocalId);
  Future<Tarea?> getTareaById(String tareaId);
  Future<List<Tarea>> filtrarTareas(
    String usuarioId, {
    String? prioridad,
    String? origen,
  });
  Future<List<Tarea>> getTareasCompletadas(
    String usuarioId, {
    bool completadas = true,
  });
  Future<void> addTarea(Tarea tarea);
  Future<void> updateTarea(String id, Map<String, dynamic> camposActualizados);
  Future<void> completarTarea(String id, {bool completada = true});
  Future<void> deleteTarea(String id);
  Future<void> syncWithServer();
  Future<void> clearLocalData();
}
