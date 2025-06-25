import 'package:equatable/equatable.dart';

abstract class EstadoPsicologicoEvent extends Equatable {
  const EstadoPsicologicoEvent();

  @override
  List<Object?> get props => [];
}

class VerificarEvaluacionInicial extends EstadoPsicologicoEvent {
  final String usuarioId;

  const VerificarEvaluacionInicial(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}

class EvaluarEstadoEmocional extends EstadoPsicologicoEvent {
  final String usuarioId;
  final List<Map<String, dynamic>> respuestas;

  const EvaluarEstadoEmocional(this.usuarioId, this.respuestas);

  @override
  List<Object?> get props => [usuarioId, respuestas];
}
