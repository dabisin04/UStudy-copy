import 'package:equatable/equatable.dart';
import 'package:ustudy/domain/entities/chat_message.dart';

abstract class ChatEmocionalState extends Equatable {
  const ChatEmocionalState();

  @override
  List<Object?> get props => [];
}

class ChatInicial extends ChatEmocionalState {}

class ChatCargando extends ChatEmocionalState {}

class ChatRespuestaRecibida extends ChatEmocionalState {
  final ChatMessage mensaje;
  final List<Map<String, dynamic>> tareasGeneradas;
  final bool recomendarFormulario;

  const ChatRespuestaRecibida(
    this.mensaje,
    this.tareasGeneradas,
    this.recomendarFormulario,
  );

  @override
  List<Object?> get props => [mensaje, tareasGeneradas, recomendarFormulario];
}

class ChatError extends ChatEmocionalState {
  final String mensaje;

  const ChatError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

class ChatHistorialCargando extends ChatEmocionalState {}

class ChatHistorialCargado extends ChatEmocionalState {
  final List<ChatMessage> mensajes;
  final int total;

  const ChatHistorialCargado(this.mensajes, this.total);

  @override
  List<Object?> get props => [mensajes, total];
}
