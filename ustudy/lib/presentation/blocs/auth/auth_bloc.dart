import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:ustudy/domain/repositories/usuario.dart';
import 'package:ustudy/domain/entities/usuario.dart';
import 'package:ustudy/infrastructure/utils/session.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UsuarioRepository usuarioRepository;
  Usuario? _usuarioActual;

  AuthBloc(this.usuarioRepository) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckSession>(_onCheckSession);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await usuarioRepository.login(
        event.correo,
        event.contrasena,
      );
      if (user != null) {
        _usuarioActual = user;
        await SessionService.saveUserSession(
          localId: user.localId,
          remoteId: user.remoteId,
          nombre: user.nombre,
          correo: user.correo,
        );
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError("Credenciales incorrectas."));
      }
    } catch (e) {
      emit(AuthError("Error al iniciar sesión: ${e.toString()}"));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await usuarioRepository.saveUser(
        Usuario(
          localId: '', // Se asignará luego tras el login
          remoteId: null,
          nombre: event.nombre,
          correo: event.correo,
          lastModified: DateTime.now(),
          syncStatus: 'pending',
        ),
        event.contrasena,
      );

      // Iniciar sesión automático tras registrar
      final user = await usuarioRepository.login(
        event.correo,
        event.contrasena,
      );
      if (user != null) {
        _usuarioActual = user;
        await SessionService.saveUserSession(
          localId: user.localId,
          remoteId: user.remoteId,
          nombre: user.nombre,
          correo: user.correo,
        );
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError("Error al registrar."));
      }
    } catch (e) {
      emit(AuthError("Error al registrar: ${e.toString()}"));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _usuarioActual = null;
    await SessionService.clearSession();
    await usuarioRepository.deleteAllUsers();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    final session = await SessionService.getUserSession();
    if (session != null) {
      final user = Usuario(
        localId: session['localId']!,
        remoteId: session['remoteId']!.isNotEmpty ? session['remoteId'] : null,
        nombre: session['nombre']!,
        correo: session['correo']!,
        lastModified: DateTime.now(),
        syncStatus: 'synced',
      );
      _usuarioActual = user;
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Usuario? get usuarioActual => _usuarioActual;
}
