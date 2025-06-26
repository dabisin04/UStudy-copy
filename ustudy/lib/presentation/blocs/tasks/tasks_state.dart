import 'package:equatable/equatable.dart';
import 'package:ustudy/domain/entities/tareas.dart';

abstract class TareaState extends Equatable {
  const TareaState();

  @override
  List<Object?> get props => [];
}

class TareaInicial extends TareaState {}

class TareaCargando extends TareaState {}

class TareasCargadas extends TareaState {
  final List<Tarea> tareas;

  const TareasCargadas(this.tareas);

  @override
  List<Object?> get props => [tareas];
}

class TareasSincronizadas extends TareaState {
  final List<Tarea> nuevasTareas;

  const TareasSincronizadas(this.nuevasTareas);

  @override
  List<Object?> get props => [nuevasTareas];
}

class TareaSincronizacionCompletada extends TareaState {}

class TareaError extends TareaState {
  final String mensaje;

  const TareaError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
