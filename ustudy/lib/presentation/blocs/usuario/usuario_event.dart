import 'package:ustudy/domain/entities/usuario.dart';

abstract class UsuarioEvent {}

class LoadUsuarioById extends UsuarioEvent {
  final String localId;
  LoadUsuarioById(this.localId);
}

class LoadAllUsuarios extends UsuarioEvent {}

class UpdateUsuarioRequested extends UsuarioEvent {
  final Usuario usuario;
  UpdateUsuarioRequested(this.usuario);
}

class DeleteUsuarioRequested extends UsuarioEvent {
  final String localId;
  DeleteUsuarioRequested(this.localId);
}

class DeleteAllUsuariosRequested extends UsuarioEvent {}

class UpdateUIdRequested extends UsuarioEvent {
  final String localId;
  final String uId;
  UpdateUIdRequested({required this.localId, required this.uId});
}

class GetCurrentUIdRequested extends UsuarioEvent {
  final String localId;
  GetCurrentUIdRequested(this.localId);
}
