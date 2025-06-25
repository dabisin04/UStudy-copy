import 'package:equatable/equatable.dart';
import 'package:ustudy/domain/entities/estado_psicologico.dart';

abstract class EstadoPsicologicoState extends Equatable {
  const EstadoPsicologicoState();

  @override
  List<Object?> get props => [];
}

class EstadoPsicologicoInicial extends EstadoPsicologicoState {}

class EstadoPsicologicoCargando extends EstadoPsicologicoState {}

class EvaluacionPendiente extends EstadoPsicologicoState {}

class EvaluacionYaRegistrada extends EstadoPsicologicoState {}

class EstadoPsicologicoEvaluado extends EstadoPsicologicoState {
  final EstadoPsicologico estado;

  const EstadoPsicologicoEvaluado(this.estado);

  @override
  List<Object?> get props => [estado];
}

class EstadoPsicologicoError extends EstadoPsicologicoState {
  final String mensaje;

  const EstadoPsicologicoError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
