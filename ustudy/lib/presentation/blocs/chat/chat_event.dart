import 'package:equatable/equatable.dart';

abstract class ChatEmocionalEvent extends Equatable {
  const ChatEmocionalEvent();

  @override
  List<Object?> get props => [];
}

class EnviarMensajeChat extends ChatEmocionalEvent {
  final String usuarioId;
  final String mensaje;

  const EnviarMensajeChat(this.usuarioId, this.mensaje);

  @override
  List<Object?> get props => [usuarioId, mensaje];
}

class CargarHistorialChat extends ChatEmocionalEvent {
  final String usuarioId;

  const CargarHistorialChat(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}
