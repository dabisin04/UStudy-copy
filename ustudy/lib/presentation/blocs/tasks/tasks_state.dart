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

class TareaError extends TareaState {
  final String mensaje;

  const TareaError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
