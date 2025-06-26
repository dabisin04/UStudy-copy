import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/presentation/blocs/chat/chat_event.dart';
import 'package:ustudy/presentation/blocs/chat/chat_state.dart';
import 'package:ustudy/core/services/chat_service.dart';
import 'package:ustudy/domain/entities/chat_message.dart';

class ChatEmocionalBloc extends Bloc<ChatEmocionalEvent, ChatEmocionalState> {
  List<ChatMessage> _mensajesCargados = [];
  int _totalMensajes = 0;
  int _offset = 0;

  ChatEmocionalBloc() : super(ChatInicial()) {
    on<EnviarMensajeChat>(_onEnviarMensaje);
    on<CargarHistorialChat>(_onCargarHistorial);
  }

  Future<void> _onEnviarMensaje(
    EnviarMensajeChat event,
    Emitter<ChatEmocionalState> emit,
  ) async {
    emit(ChatCargando());

    try {
      final resultado = await ChatEmocionalService.enviarMensaje(
        usuarioId: event.usuarioId,
        mensaje: event.mensaje,
      );

      final mensaje = ChatMessage(
        text: resultado['respuesta'] ?? '',
        isUser: false,
        esRecomendacion: resultado['recomendar_formulario'] ?? false,
      );

      emit(
        ChatRespuestaRecibida(
          mensaje,
          List<Map<String, dynamic>>.from(resultado['tareas_generadas']),
          resultado['recomendar_formulario'] ?? false,
        ),
      );
    } catch (e) {
      emit(ChatError('Ocurrió un error al procesar el mensaje.'));
    }
  }

  Future<void> _onCargarHistorial(
    CargarHistorialChat event,
    Emitter<ChatEmocionalState> emit,
  ) async {
    emit(ChatHistorialCargando());

    try {
      final resultado = await ChatEmocionalService.obtenerHistorial(
        usuarioId: event.usuarioId,
        offset: event.offset,
        limit: event.limit,
      );

      final nuevosMensajes = resultado['mensajes'] as List<ChatMessage>;
      _totalMensajes = resultado['total'] as int;
      final cantidad = resultado['cantidad'] as int;

      // Si es la primera carga (offset = 0), reemplazar todos los mensajes
      if (event.offset == 0) {
        _mensajesCargados = nuevosMensajes;
        _offset = cantidad;
      } else {
        // Para paginación, agregar al inicio (mensajes más antiguos)
        _mensajesCargados.insertAll(0, nuevosMensajes);
        _offset += cantidad;
      }

      emit(ChatHistorialCargado(_mensajesCargados, _totalMensajes));
    } catch (e) {
      emit(ChatError('No se pudo cargar el historial de chat.'));
    }
  }
}
