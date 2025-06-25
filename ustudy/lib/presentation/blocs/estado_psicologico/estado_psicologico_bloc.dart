import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/domain/repositories/estado_psicologico.dart';

import 'estado_psicologico_event.dart';
import 'estado_psicologico_state.dart';

class EstadoPsicologicoBloc
    extends Bloc<EstadoPsicologicoEvent, EstadoPsicologicoState> {
  final EstadoPsicologicoRepository repository;

  EstadoPsicologicoBloc(this.repository) : super(EstadoPsicologicoInicial()) {
    on<VerificarEvaluacionInicial>(_onVerificar);
    on<EvaluarEstadoEmocional>(_onEvaluar);
  }

  Future<void> _onVerificar(
    VerificarEvaluacionInicial event,
    Emitter<EstadoPsicologicoState> emit,
  ) async {
    emit(EstadoPsicologicoCargando());
    try {
      final pendiente = await repository.verificarEvaluacionInicial(
        event.usuarioId,
      );
      if (pendiente) {
        emit(EvaluacionPendiente());
      } else {
        emit(EvaluacionYaRegistrada());
      }
    } catch (e) {
      emit(EstadoPsicologicoError('Error al verificar evaluación.'));
    }
  }

  Future<void> _onEvaluar(
    EvaluarEstadoEmocional event,
    Emitter<EstadoPsicologicoState> emit,
  ) async {
    emit(EstadoPsicologicoCargando());
    try {
      final estado = await repository.evaluarEstadoEmocional(
        event.usuarioId,
        event.respuestas,
      );
      emit(EstadoPsicologicoEvaluado(estado));
    } catch (e) {
      emit(EstadoPsicologicoError('Error al evaluar estado emocional.'));
    }
  }
}
