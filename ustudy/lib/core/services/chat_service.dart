import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ustudy/core/constants/api.dart';
import 'package:ustudy/domain/entities/chat_message.dart';

class ChatEmocionalService {
  /// Envía un mensaje al asistente terapéutico
  /// Devuelve un mapa con:
  ///   - 'respuesta': String
  ///   - 'tareas_generadas': List<Map<String, dynamic>>
  static Future<Map<String, dynamic>> enviarMensaje({
    required String usuarioId,
    required String mensaje,
  }) async {
    print('🔍 [ChatService] enviarMensaje() iniciado');
    print('🔍 [ChatService] usuarioId: $usuarioId');
    print('🔍 [ChatService] mensaje: "$mensaje"');

    final uri = Uri.parse('${ApiConstants.baseUrl}/chat/ia');
    print('🔍 [ChatService] URL: $uri');

    final body = jsonEncode({'usuario_id': usuarioId, 'mensaje': mensaje});
    print('🔍 [ChatService] Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('🔍 [ChatService] Status code: ${response.statusCode}');
      print('🔍 [ChatService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [ChatService] Data decodificada: $data');
        return {
          'respuesta': data['respuesta'] ?? '',
          'tareas_generadas': data['tareas_generadas'] ?? [],
        };
      } else {
        print('❌ [ChatService] Error HTTP: ${response.statusCode}');
        throw Exception('Error al comunicarse con la IA emocional');
      }
    } catch (e) {
      print('❌ [ChatService] Excepción: $e');
      throw Exception('Error al comunicarse con la IA emocional: $e');
    }
  }

  /// Carga el historial de conversación del usuario
  static Future<List<ChatMessage>> obtenerHistorial({
    required String usuarioId,
  }) async {
    print('🔍 [ChatService] obtenerHistorial() iniciado');
    print('🔍 [ChatService] usuarioId: $usuarioId');

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/chat/ia/historial/$usuarioId',
    );
    print('🔍 [ChatService] URL historial: $uri');

    try {
      final response = await http.get(uri);
      print('🔍 [ChatService] Status code historial: ${response.statusCode}');
      print('🔍 [ChatService] Response body historial: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('🔍 [ChatService] Data historial: $data');
        final mensajes = data
            .expand<ChatMessage>(
              (e) => [
                ChatMessage(text: e['mensaje_usuario'], isUser: true),
                ChatMessage(text: e['respuesta_ia'], isUser: false),
              ],
            )
            .toList();
        print('🔍 [ChatService] Mensajes procesados: ${mensajes.length}');
        return mensajes;
      } else {
        print('❌ [ChatService] Error HTTP historial: ${response.statusCode}');
        throw Exception('Error al cargar historial de conversación');
      }
    } catch (e) {
      print('❌ [ChatService] Excepción historial: $e');
      throw Exception('Error al cargar historial de conversación: $e');
    }
  }
}
