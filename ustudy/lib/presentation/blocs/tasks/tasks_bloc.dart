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
  }

  Future<void> _onCargarTareas(
    CargarTareas event,
    Emitter<TareaState> emit,
  ) async {
    emit(TareaCargando());
    try {
      final tareas = await tareaRepository.getTareas(event.usuarioId);
      emit(TareasCargadas(tareas));
    } catch (e) {
      emit(TareaError('Error al cargar tareas.'));
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
    try {
      await tareaRepository.addTarea(event.tarea);
      add(CargarTareas(event.tarea.usuarioLocalId));
    } catch (_) {
      emit(TareaError('No se pudo agregar la tarea.'));
    }
  }

  Future<void> _onActualizarTarea(
    ActualizarTarea event,
    Emitter<TareaState> emit,
  ) async {
    try {
      await tareaRepository.updateTarea(event.id, event.camposActualizados);
      final usuarioId = event.camposActualizados['usuario_local_id'];
      if (usuarioId != null) add(CargarTareas(usuarioId));
    } catch (_) {
      emit(TareaError('No se pudo actualizar la tarea.'));
    }
  }

  Future<void> _onEliminarTarea(
    EliminarTarea event,
    Emitter<TareaState> emit,
  ) async {
    try {
      await tareaRepository.deleteTarea(event.tareaId);
    } catch (_) {
      emit(TareaError('No se pudo eliminar la tarea.'));
    }
  }

  Future<void> _onCompletarTarea(
    CompletarTarea event,
    Emitter<TareaState> emit,
  ) async {
    try {
      await tareaRepository.completarTarea(
        event.tareaId,
        completada: event.completada,
      );
    } catch (_) {
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
}
