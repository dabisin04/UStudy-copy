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
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final usuario = await usuarioRepository.login(
        event.email,
        event.password,
      );
      if (usuario != null) {
        _usuarioActual = usuario;
        await SessionService.saveUserSession(
          localId: usuario.localId,
          remoteId: usuario.remoteId,
          nombre: usuario.nombre,
          correo: usuario.correo,
          uId: usuario.uId,
        );
        emit(AuthAuthenticated(usuario));
      } else {
        emit(const AuthError('Credenciales incorrectas'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final usuario = Usuario(
        localId: '',
        remoteId: '',
        nombre: event.name,
        correo: event.email,
        lastModified: DateTime.now(),
        syncStatus: 'pending',
      );
      await usuarioRepository.saveUser(usuario, event.password);

      // Automatically login after successful registration
      final loggedInUsuario = await usuarioRepository.login(
        event.email,
        event.password,
      );

      if (loggedInUsuario != null) {
        _usuarioActual = loggedInUsuario;
        await SessionService.saveUserSession(
          localId: loggedInUsuario.localId,
          remoteId: loggedInUsuario.remoteId,
          nombre: loggedInUsuario.nombre,
          correo: loggedInUsuario.correo,
          uId: loggedInUsuario.uId,
        );
        emit(AuthAuthenticated(loggedInUsuario));
      } else {
        emit(const AuthError('Error al iniciar sesión después del registro'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
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
        uId: session['uId']!.isNotEmpty ? session['uId'] : null,
      );
      _usuarioActual = user;
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_usuarioActual == null) {
      emit(const AuthPasswordChangeError('Usuario no autenticado'));
      return;
    }

    try {
      await usuarioRepository.changePassword(
        _usuarioActual!.localId,
        event.currentPassword,
        event.newPassword,
      );
      emit(AuthPasswordChanged());
    } catch (e) {
      emit(AuthPasswordChangeError(e.toString()));
    }
  }

  Usuario? get usuarioActual => _usuarioActual;
}
