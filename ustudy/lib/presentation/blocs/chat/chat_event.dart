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
  final int offset;
  final int limit;

  const CargarHistorialChat(this.usuarioId, {this.offset = 0, this.limit = 10});

  @override
  List<Object?> get props => [usuarioId, offset, limit];
}
