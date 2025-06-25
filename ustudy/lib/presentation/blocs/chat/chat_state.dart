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
  final String respuesta;
  final List<Map<String, dynamic>> tareasGeneradas;

  const ChatRespuestaRecibida(this.respuesta, this.tareasGeneradas);

  @override
  List<Object?> get props => [respuesta, tareasGeneradas];
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

  const ChatHistorialCargado(this.mensajes);

  @override
  List<Object?> get props => [mensajes];
}
