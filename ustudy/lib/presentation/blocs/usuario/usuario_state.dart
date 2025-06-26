import 'package:ustudy/domain/entities/usuario.dart';

abstract class UsuarioState {}

class UsuarioInitial extends UsuarioState {}

class UsuarioLoading extends UsuarioState {}

class UsuarioLoaded extends UsuarioState {
  final Usuario usuario;
  UsuarioLoaded(this.usuario);
}

class UsuariosListLoaded extends UsuarioState {
  final List<Usuario> usuarios;
  UsuariosListLoaded(this.usuarios);
}

class UsuarioUpdated extends UsuarioState {}

class UsuarioDeleted extends UsuarioState {}

class AllUsuariosDeleted extends UsuarioState {}

class CurrentUIdLoaded extends UsuarioState {
  final String? uId;
  CurrentUIdLoaded(this.uId);
}

class UsuarioError extends UsuarioState {
  final String message;
  UsuarioError(this.message);
}
