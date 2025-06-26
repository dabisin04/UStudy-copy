import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/domain/repositories/tareas.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_event.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_state.dart';

class TareaBloc extends Bloc<TareaEvent, TareaState> {
  final TareaRepository tareaRepository;

  TareaBloc(this.tareaRepository) : super(TareaInicial()) {
    on<CargarTareas>(_onCargarTareas);
    on<FiltrarTareas>(_onFiltrarTareas);
    on<AgregarTarea>(_onAgregarTarea);
    on<ActualizarTarea>(_onActualizarTarea);
    on<EliminarTarea>(_onEliminarTarea);
    on<CompletarTarea>(_onCompletarTarea);
    on<SincronizarTareas>(_onSincronizarTareas);
    on<SincronizarDesdeServidor>(_onSincronizarDesdeServidor);
    on<SincronizacionBidireccional>(_onSincronizacionBidireccional);
  }

  Future<void> _onCargarTareas(
    CargarTareas event,
    Emitter<TareaState> emit,
  ) async {
    print('🎯 [BLOC] Cargando tareas para usuario: ${event.usuarioId}');
    emit(TareaCargando());
    try {
      final tareas = await tareaRepository.getTareas(event.usuarioId);
      print('✅ [BLOC] Tareas cargadas exitosamente: ${tareas.length}');
      print(
        '✅ [BLOC] Títulos de tareas: ${tareas.map((t) => t.titulo).toList()}',
      );
      emit(TareasCargadas(tareas));
      print('✅ [BLOC] Estado TareasCargadas emitido');

      // Hacer sincronización en segundo plano
      _sincronizarEnSegundoPlano(event.usuarioId);
    } catch (e) {
      print('💥 [BLOC] Error al cargar tareas: $e');
      emit(TareaError('Error al cargar tareas.'));
    }
  }

  Future<void> _sincronizarEnSegundoPlano(String usuarioId) async {
    try {
      print('🔄 [BLOC] Iniciando sincronización en segundo plano');
      await tareaRepository.syncBidireccional(usuarioId);
      print('✅ [BLOC] Sincronización en segundo plano completada');

      // Recargar tareas después de sincronización
      final tareas = await tareaRepository.getTareas(usuarioId);
      emit(TareasCargadas(tareas));
    } catch (e) {
      print('💥 [BLOC] Error en sincronización en segundo plano: $e');
    }
  }

  Future<void> _onFiltrarTareas(
    FiltrarTareas event,
    Emitter<TareaState> emit,
  ) async {
    emit(TareaCargando());
    try {
      final tareas = await tareaRepository.filtrarTareas(
        event.usuarioId,
        prioridad: event.prioridad,
        origen: event.origen,
      );
      emit(TareasCargadas(tareas));
    } catch (_) {
      emit(TareaError('Error al filtrar tareas.'));
    }
  }

  Future<void> _onAgregarTarea(
    AgregarTarea event,
    Emitter<TareaState> emit,
  ) async {
    print('➕ [BLOC] Agregando nueva tarea: ${event.tarea.titulo}');
    print('➕ [BLOC] Tarea data: ${event.tarea.toMap()}');
    try {
      await tareaRepository.addTarea(event.tarea);
      print('✅ [BLOC] Tarea agregada exitosamente');
      add(CargarTareas(event.tarea.usuarioLocalId));
    } catch (e) {
      print('💥 [BLOC] Error al agregar tarea: $e');
      emit(TareaError('No se pudo agregar la tarea.'));
    }
  }

  Future<void> _onActualizarTarea(
    ActualizarTarea event,
    Emitter<TareaState> emit,
  ) async {
    print('🔄 [BLOC] Actualizando tarea: ${event.id}');
    print('🔄 [BLOC] Campos a actualizar: ${event.camposActualizados}');
    try {
      await tareaRepository.updateTarea(event.id, event.camposActualizados);
      print('✅ [BLOC] Tarea actualizada exitosamente');

      // Recargar tareas para actualizar la UI
      final usuarioId = event.camposActualizados['usuario_local_id'];
      if (usuarioId != null) {
        add(CargarTareas(usuarioId));
      }
    } catch (e) {
      print('💥 [BLOC] Error al actualizar tarea: $e');
      emit(TareaError('No se pudo actualizar la tarea.'));
    }
  }

  Future<void> _onEliminarTarea(
    EliminarTarea event,
    Emitter<TareaState> emit,
  ) async {
    print('🗑️ [BLOC] Eliminando tarea: ${event.tareaId}');
    try {
      await tareaRepository.deleteTarea(event.tareaId);
      print('✅ [BLOC] Tarea eliminada exitosamente');
    } catch (e) {
      print('💥 [BLOC] Error al eliminar tarea: $e');
      emit(TareaError('No se pudo eliminar la tarea.'));
    }
  }

  Future<void> _onCompletarTarea(
    CompletarTarea event,
    Emitter<TareaState> emit,
  ) async {
    print(
      '✅ [BLOC] Marcando tarea como ${event.completada ? "completada" : "pendiente"}: ${event.tareaId}',
    );
    try {
      await tareaRepository.completarTarea(
        event.tareaId,
        completada: event.completada,
      );
      print('✅ [BLOC] Tarea marcada exitosamente');

      // Recargar tareas para actualizar la UI
      final currentState = state;
      if (currentState is TareasCargadas) {
        final tarea = currentState.tareas.firstWhere(
          (t) => t.id == event.tareaId,
          orElse: () => currentState.tareas.first,
        );
        add(CargarTareas(tarea.usuarioLocalId));
      }
    } catch (e) {
      print('💥 [BLOC] Error al marcar tarea: $e');
      emit(TareaError('No se pudo marcar como completada.'));
    }
  }

  Future<void> _onSincronizarTareas(
    SincronizarTareas event,
    Emitter<TareaState> emit,
  ) async {
    try {
      await tareaRepository.syncWithServer();
    } catch (_) {
      emit(TareaError('Error de sincronización.'));
    }
  }

  Future<void> _onSincronizarDesdeServidor(
    SincronizarDesdeServidor event,
    Emitter<TareaState> emit,
  ) async {
    print(
      '📥 [BLOC] Sincronizando desde servidor para usuario: ${event.usuarioId}',
    );
    try {
      final nuevasTareas = await tareaRepository.syncFromServer(
        event.usuarioId,
      );
      if (nuevasTareas.isNotEmpty) {
        print('✅ [BLOC] Nuevas tareas sincronizadas: ${nuevasTareas.length}');
        // En lugar de emitir TareasSincronizadas, recargar todas las tareas
        final todasLasTareas = await tareaRepository.getTareas(event.usuarioId);
        emit(TareasCargadas(todasLasTareas));
      } else {
        print('✅ [BLOC] Sincronización completada sin nuevas tareas');
        // Recargar tareas para asegurar que la UI esté actualizada
        final todasLasTareas = await tareaRepository.getTareas(event.usuarioId);
        emit(TareasCargadas(todasLasTareas));
      }
    } catch (e) {
      print('💥 [BLOC] Error en sincronización desde servidor: $e');
      // En caso de error, intentar cargar tareas locales
      try {
        final tareas = await tareaRepository.getTareas(event.usuarioId);
        emit(TareasCargadas(tareas));
      } catch (localError) {
        emit(TareaError('Error al sincronizar tareas.'));
      }
    }
  }

  Future<void> _onSincronizacionBidireccional(
    SincronizacionBidireccional event,
    Emitter<TareaState> emit,
  ) async {
    print(
      '🔄 [BLOC] Iniciando sincronización bidireccional para usuario: ${event.usuarioId}',
    );
    try {
      await tareaRepository.syncBidireccional(event.usuarioId);
      print('✅ [BLOC] Sincronización bidireccional completada');

      final tareas = await tareaRepository.getTareas(event.usuarioId);
      print(
        '✅ [BLOC] Tareas actualizadas después de sincronización: ${tareas.length}',
      );
      emit(TareasCargadas(tareas));
    } catch (e) {
      print('💥 [BLOC] Error en sincronización bidireccional: $e');
      try {
        final tareas = await tareaRepository.getTareas(event.usuarioId);
        print(
          '🔄 [BLOC] Cargando tareas locales como fallback: ${tareas.length}',
        );
        emit(TareasCargadas(tareas));
      } catch (localError) {
        print('💥 [BLOC] Error al cargar tareas locales: $localError');
        emit(TareaError('Error al cargar tareas.'));
      }
    }
  }
}
