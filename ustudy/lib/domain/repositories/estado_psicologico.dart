import 'package:ustudy/domain/entities/estado_psicologico.dart';

abstract class EstadoPsicologicoRepository {
  /// Verifica si el usuario ya completó su perfil emocional
  Future<bool> verificarEvaluacionInicial(String usuarioId);

  /// Evalúa el estado emocional con respuestas tipo List<Map>
  Future<EstadoPsicologico> evaluarEstadoEmocional(
    String usuarioId,
    List<Map<String, dynamic>> respuestas,
  );
}
