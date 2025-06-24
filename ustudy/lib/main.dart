import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ustudy/core/styles/apptheme.dart';

import 'package:ustudy/domain/repositories/usuario.dart';

import 'package:ustudy/infrastructure/adapters/usuario.dart';

import 'package:ustudy/presentation/blocs/auth/auth_bloc.dart';
import 'package:ustudy/presentation/blocs/auth/auth_event.dart';
import 'package:ustudy/presentation/blocs/auth/auth_state.dart';
import 'package:ustudy/presentation/blocs/usuario_bloc.dart';

import 'package:ustudy/presentation/screens/splash.dart';
import 'package:ustudy/presentation/screens/auth/login.dart';
import 'package:ustudy/presentation/screens/auth/register.dart';
import 'package:ustudy/presentation/screens/home.dart';
import 'package:ustudy/presentation/screens/uni/select_u.dart';

void main() {
  runApp(const UStudyApp());
}

class UStudyApp extends StatelessWidget {
  const UStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final usuarioRepository = UsuarioRepositoryImpl();

    return RepositoryProvider<UsuarioRepository>.value(
      value: usuarioRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(usuarioRepository)..add(AuthCheckSession()),
          ),
          BlocProvider<UsuarioBloc>(
            create: (_) => UsuarioBloc(usuarioRepository),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/home': (_) => const HomeScreen(),
            '/select_u': (context) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                return UniversitySelectionScreen(
                  localId: authState.usuario.localId,
                );
              } else {
                return const LoginScreen(); // fallback en caso de no estar logueado
              }
            },
          },
        ),
      ),
    );
  }
}
