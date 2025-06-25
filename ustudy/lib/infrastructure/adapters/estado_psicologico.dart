import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ustudy/core/constants/api.dart';
import 'package:ustudy/domain/entities/estado_psicologico.dart';
import 'package:ustudy/domain/repositories/estado_psicologico.dart';

class EstadoPsicologicoRepositoryImpl implements EstadoPsicologicoRepository {
  @override
  Future<bool> verificarEvaluacionInicial(String usuarioId) async {
    final url = Uri.parse(
      '${ApiConstants.estadoPsicologico}/activar-evaluacion-inicial',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario_id': usuarioId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['estado'] == 'pendiente';
    } else {
      throw Exception('Error al verificar evaluación inicial');
    }
  }

  @override
  Future<EstadoPsicologico> evaluarEstadoEmocional(
    String usuarioId,
    List<Map<String, dynamic>> respuestas,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.estadoPsicologico}/evaluar-estado-emocional',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario_id': usuarioId, 'respuestas': respuestas}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EstadoPsicologico.fromMap(data['estado']);
    } else {
      throw Exception('Error al evaluar estado emocional');
    }
  }
}
