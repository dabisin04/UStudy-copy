abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String correo;
  final String contrasena;

  AuthLoginRequested({required this.correo, required this.contrasena});
}

class AuthRegisterRequested extends AuthEvent {
  final String nombre;
  final String correo;
  final String contrasena;

  AuthRegisterRequested({
    required this.nombre,
    required this.correo,
    required this.contrasena,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckSession extends AuthEvent {}
