import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/presentation/blocs/chat/chat_event.dart';
import 'package:ustudy/presentation/blocs/chat/chat_state.dart';
import 'package:ustudy/core/services/chat_service.dart';

class ChatEmocionalBloc extends Bloc<ChatEmocionalEvent, ChatEmocionalState> {
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

      emit(
        ChatRespuestaRecibida(
          resultado['respuesta'],
          List<Map<String, dynamic>>.from(resultado['tareas_generadas']),
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
      final lista = await ChatEmocionalService.obtenerHistorial(
        usuarioId: event.usuarioId,
      );

      emit(ChatHistorialCargado(lista));
    } catch (e) {
      emit(ChatError('No se pudo cargar el historial de chat.'));
    }
  }
}
