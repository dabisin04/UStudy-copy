import 'package:ustudy/domain/entities/usuario.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Usuario usuario;

  const AuthAuthenticated(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordChanged extends AuthState {}

class AuthPasswordChangeError extends AuthState {
  final String message;

  const AuthPasswordChangeError(this.message);

  @override
  List<Object?> get props => [message];
}
