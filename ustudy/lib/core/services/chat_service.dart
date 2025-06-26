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
    final body = jsonEncode({'usuario_id': usuarioId, 'mensaje': mensaje});

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

        final mensaje = data['mensaje'] as Map<String, dynamic>;
        return {
          'respuesta': mensaje['text'] ?? '',
          'tareas_generadas': data['tareas_generadas'] ?? [],
          'recomendar_formulario': mensaje['esRecomendacion'] ?? false,
        };
      } else {
        print('❌ [ChatService] Error HTTP: ${response.statusCode}');
        throw Exception('Error al comunicarse con la IA emocional');
      }
    } catch (e) {
      throw Exception('Error al comunicarse con la IA emocional: $e');
    }
  }

  /// Carga el historial de conversación del usuario con marcas de recomendación
  static Future<Map<String, dynamic>> obtenerHistorial({
    required String usuarioId,
    int offset = 0,
    int limit = 10,
  }) async {
    print('🔍 [ChatService] obtenerHistorial() iniciado');
    print(
      '🔍 [ChatService] usuarioId: $usuarioId, offset: $offset, limit: $limit',
    );

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/chat/ia/historial/$usuarioId?offset=$offset&limit=$limit',
    );
    print('🔍 [ChatService] URL historial: $uri');

    try {
      final response = await http.get(uri);
      print('🔍 [ChatService] Status code historial: ${response.statusCode}');
      print('🔍 [ChatService] Response body historial: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final total = data['total'] as int;
        final cantidad = data['cantidad'] as int;
        print(
          '🔍 [ChatService] Total mensajes: $total, Cantidad recibida: $cantidad',
        );

        final List<ChatMessage> lista = [];

        // Los mensajes ya vienen en orden cronológico correcto desde el backend
        for (final e in data['mensajes'] as List) {
          lista.add(ChatMessage(text: e['mensaje_usuario'], isUser: true));
          lista.add(
            ChatMessage(
              text: e['respuesta_ia'],
              isUser: false,
              esRecomendacion: e['respuesta_ia'].toString().contains(
                'evaluación emocional',
              ),
            ),
          );
        }

        print('🔍 [ChatService] Mensajes procesados: ${lista.length}');
        return {
          'mensajes': lista,
          'total': total,
          'cantidad': cantidad,
          'offset': offset,
        };
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
