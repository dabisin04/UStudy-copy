import 'package:equatable/equatable.dart';
import 'package:ustudy/domain/entities/tareas.dart';

abstract class TareaEvent extends Equatable {
  const TareaEvent();

  @override
  List<Object?> get props => [];
}

class CargarTareas extends TareaEvent {
  final String usuarioId;

  const CargarTareas(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}

class FiltrarTareas extends TareaEvent {
  final String usuarioId;
  final String? prioridad;
  final String? origen;

  const FiltrarTareas(this.usuarioId, {this.prioridad, this.origen});

  @override
  List<Object?> get props => [usuarioId, prioridad, origen];
}

class AgregarTarea extends TareaEvent {
  final Tarea tarea;

  const AgregarTarea(this.tarea);

  @override
  List<Object?> get props => [tarea];
}

class ActualizarTarea extends TareaEvent {
  final String id;
  final Map<String, dynamic> camposActualizados;

  const ActualizarTarea(this.id, this.camposActualizados);

  @override
  List<Object?> get props => [id, camposActualizados];
}

class EliminarTarea extends TareaEvent {
  final String tareaId;

  const EliminarTarea(this.tareaId);

  @override
  List<Object?> get props => [tareaId];
}

class CompletarTarea extends TareaEvent {
  final String tareaId;
  final bool completada;

  const CompletarTarea(this.tareaId, {this.completada = true});

  @override
  List<Object?> get props => [tareaId, completada];
}

class SincronizarTareas extends TareaEvent {
  const SincronizarTareas();
}

class SincronizarDesdeServidor extends TareaEvent {
  final String usuarioId;

  const SincronizarDesdeServidor(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}

class SincronizacionBidireccional extends TareaEvent {
  final String usuarioId;

  const SincronizacionBidireccional(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}
