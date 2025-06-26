import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/domain/repositories/usuario.dart';
import 'usuario_event.dart';
import 'usuario_state.dart';

class UsuarioBloc extends Bloc<UsuarioEvent, UsuarioState> {
  final UsuarioRepository usuarioRepository;

  UsuarioBloc(this.usuarioRepository) : super(UsuarioInitial()) {
    on<LoadUsuarioById>(_onLoadUsuarioById);
    on<LoadAllUsuarios>(_onLoadAllUsuarios);
    on<UpdateUsuarioRequested>(_onUpdateUsuario);
    on<DeleteUsuarioRequested>(_onDeleteUsuario);
    on<DeleteAllUsuariosRequested>(_onDeleteAllUsuarios);
    on<UpdateUIdRequested>(_onUpdateUId);
    on<GetCurrentUIdRequested>(_onGetCurrentUId);
  }

  // LoadUsuarioById
  Future<void> _onLoadUsuarioById(
    LoadUsuarioById event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      final usuario = await usuarioRepository.getUserById(event.localId);
      if (usuario != null) {
        emit(UsuarioLoaded(usuario));
      } else {
        emit(UsuarioError("Usuario no encontrado."));
      }
    } catch (e) {
      emit(UsuarioError("Error al obtener usuario: ${e.toString()}"));
    }
  }

  // LoadAllUsuarios
  Future<void> _onLoadAllUsuarios(
    LoadAllUsuarios event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      final usuarios = await usuarioRepository.getAllUsers();
      emit(UsuariosListLoaded(usuarios));
    } catch (e) {
      emit(UsuarioError("Error al obtener usuarios: ${e.toString()}"));
    }
  }

  // UpdateUsuarioRequested
  Future<void> _onUpdateUsuario(
    UpdateUsuarioRequested event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      await usuarioRepository.updateUser(event.usuario);
      emit(UsuarioUpdated());
    } catch (e) {
      emit(UsuarioError("Error al actualizar usuario: ${e.toString()}"));
    }
  }

  // DeleteUsuarioRequested
  Future<void> _onDeleteUsuario(
    DeleteUsuarioRequested event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      await usuarioRepository.deleteUser(event.localId);
      emit(UsuarioDeleted());
    } catch (e) {
      emit(UsuarioError("Error al eliminar usuario: ${e.toString()}"));
    }
  }

  // DeleteAllUsuariosRequested
  Future<void> _onDeleteAllUsuarios(
    DeleteAllUsuariosRequested event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      await usuarioRepository.deleteAllUsers();
      emit(AllUsuariosDeleted());
    } catch (e) {
      emit(
        UsuarioError("Error al eliminar todos los usuarios: ${e.toString()}"),
      );
    }
  }

  // UpdateUIdRequested
  Future<void> _onUpdateUId(
    UpdateUIdRequested event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      await usuarioRepository.updateUId(event.localId, event.uId);
      emit(UsuarioUpdated());
    } catch (e) {
      emit(UsuarioError("Error al actualizar universidad: ${e.toString()}"));
    }
  }

  // GetCurrentUIdRequested
  Future<void> _onGetCurrentUId(
    GetCurrentUIdRequested event,
    Emitter<UsuarioState> emit,
  ) async {
    emit(UsuarioLoading());
    try {
      final uId = await usuarioRepository.getCurrentUId(event.localId);
      emit(CurrentUIdLoaded(uId));
    } catch (e) {
      emit(
        UsuarioError("Error al obtener universidad actual: ${e.toString()}"),
      );
    }
  }
}
