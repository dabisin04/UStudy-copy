import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/presentation/blocs/auth/auth_bloc.dart';
import 'package:ustudy/presentation/blocs/auth/auth_event.dart';
import 'package:ustudy/presentation/blocs/auth/auth_state.dart';
import 'package:ustudy/presentation/blocs/usuario/usuario_bloc.dart';
import 'package:ustudy/presentation/blocs/usuario/usuario_event.dart';
import 'package:ustudy/presentation/blocs/usuario/usuario_state.dart';
import 'package:ustudy/presentation/screens/auth/login.dart';
import 'package:ustudy/infrastructure/utils/session.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  List<Map<String, dynamic>> universidades = [];
  String? currentUId;
  String? selectedUniversityId;

  @override
  void initState() {
    super.initState();
    loadUniversidades();
    _loadCurrentUId();
  }

  Future<void> loadUniversidades() async {
    final String response = await rootBundle.loadString(
      'assets/data/unis.json',
    );
    final data = jsonDecode(response) as List;
    setState(() {
      universidades = data.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _loadCurrentUId() async {
    final session = await SessionService.getUserSession();
    if (session != null) {
      context.read<UsuarioBloc>().add(
        GetCurrentUIdRequested(session['localId']!),
      );
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Nueva Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearPasswordFields();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _changePassword();
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _changePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthChangePasswordRequested(
        _currentPasswordController.text,
        _newPasswordController.text,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showUniversitySelectionDialog() {
    // Ensure the current value is valid
    String? validValue = selectedUniversityId ?? currentUId;
    if (validValue != null) {
      bool valueExists = universidades.any((u) => u['id'] == validValue);
      if (!valueExists) {
        validValue = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Universidad'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300,
            maxWidth: 400,
            minHeight: 100,
            maxHeight: 300,
          ),
          child: DropdownButtonFormField<String>(
            value: validValue,
            decoration: const InputDecoration(
              labelText: 'Universidad',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: universidades.map((u) {
              return DropdownMenuItem<String>(
                value: u['id'],
                child: Text(
                  u['nombre'],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedUniversityId = value);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => selectedUniversityId = null);
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedUniversityId != null) {
                _updateUniversity();
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _updateUniversity() async {
    final session = await SessionService.getUserSession();
    if (session != null && selectedUniversityId != null) {
      context.read<UsuarioBloc>().add(
        UpdateUIdRequested(
          localId: session['localId']!,
          uId: selectedUniversityId!,
        ),
      );
      Navigator.pop(context);
    }
  }

  String? _getUniversityName(String? uId) {
    if (uId == null || universidades.isEmpty) return null;
    for (var university in universidades) {
      if (university['id'] == uId) {
        return university['nombre'];
      }
    }
    return null;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordChanged) {
          _clearPasswordFields();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña cambiada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthPasswordChangeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocListener<UsuarioBloc, UsuarioState>(
        listener: (context, state) {
          if (state is CurrentUIdLoaded) {
            setState(() {
              currentUId = state.uId;
            });
          } else if (state is UsuarioUpdated) {
            setState(() {
              currentUId = selectedUniversityId;
              selectedUniversityId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Universidad actualizada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is UsuarioError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final usuario = state.usuario;

              return Scaffold(
                backgroundColor: const Color(0xFFF5F5F5),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          'Perfil',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Información del usuario
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usuario.nombre,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          usuario.correo,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Opciones del perfil
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                icon: Icons.lock_outline,
                                title: 'Cambiar Contraseña',
                                subtitle:
                                    'Actualiza tu contraseña de seguridad',
                                onTap: _showChangePasswordDialog,
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildProfileOption(
                                icon: Icons.school_outlined,
                                title: 'Universidad',
                                subtitle:
                                    _getUniversityName(currentUId) ??
                                    'No seleccionada',
                                onTap: _showUniversitySelectionDialog,
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildProfileOption(
                                icon: Icons.info_outline,
                                title: 'Acerca de',
                                subtitle: 'Información de la aplicación',
                                onTap: () {
                                  showAboutDialog(
                                    context: context,
                                    applicationName: 'UStudy',
                                    applicationVersion: '1.0.0',
                                    applicationIcon: const Icon(Icons.school),
                                    children: const [
                                      Text(
                                        'UStudy es una aplicación diseñada para apoyar la salud mental de estudiantes universitarios.',
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildProfileOption(
                                icon: Icons.logout,
                                title: 'Cerrar Sesión',
                                subtitle: 'Salir de la aplicación',
                                onTap: _logout,
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Información adicional
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Información de la Cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('ID de Usuario', usuario.localId),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Última Modificación',
                                usuario.lastModified.toString().split('.')[0],
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Estado', 'Activo'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive ? Colors.red.shade300 : Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
