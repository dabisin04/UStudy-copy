import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ustudy/core/styles/apptheme.dart';

import 'package:ustudy/domain/repositories/usuario.dart';
import 'package:ustudy/domain/repositories/estado_psicologico.dart';
import 'package:ustudy/domain/repositories/tareas.dart';

import 'package:ustudy/infrastructure/adapters/usuario.dart';
import 'package:ustudy/infrastructure/adapters/estado_psicologico.dart';
import 'package:ustudy/infrastructure/adapters/tareas.dart';

import 'package:ustudy/presentation/blocs/auth/auth_bloc.dart';
import 'package:ustudy/presentation/blocs/auth/auth_event.dart';
import 'package:ustudy/presentation/blocs/auth/auth_state.dart';
import 'package:ustudy/presentation/blocs/usuario/usuario_bloc.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_bloc.dart';
import 'package:ustudy/presentation/blocs/chat/chat_bloc.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_bloc.dart';

import 'package:ustudy/core/services/chat_service.dart';
import 'package:ustudy/core/services/sqflite.dart';

import 'package:ustudy/presentation/screens/splash.dart';
import 'package:ustudy/presentation/screens/auth/login.dart';
import 'package:ustudy/presentation/screens/auth/register.dart';
import 'package:ustudy/presentation/screens/home.dart';
import 'package:ustudy/presentation/screens/resources/article_webview.dart';
import 'package:ustudy/presentation/screens/resources/resources.dart';
import 'package:ustudy/presentation/screens/formulario/formulario.dart';
import 'package:ustudy/presentation/screens/uni/select_u.dart';
import 'package:ustudy/presentation/screens/chat/talkiebot.dart';
import 'package:ustudy/presentation/screens/tasks/tasks.dart';
import 'package:ustudy/presentation/screens/announcements/announcements_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final usuarioRepository = UsuarioRepositoryImpl();
  final estadoPsicologicoRepository = EstadoPsicologicoRepositoryImpl();
  final tareaRepository = TareaRepositoryImpl();

  runApp(
    UStudyApp(
      usuarioRepository: usuarioRepository,
      estadoPsicologicoRepository: estadoPsicologicoRepository,
      tareaRepository: tareaRepository,
    ),
  );
}

class UStudyApp extends StatelessWidget {
  final UsuarioRepository usuarioRepository;
  final EstadoPsicologicoRepository estadoPsicologicoRepository;
  final TareaRepository tareaRepository;

  const UStudyApp({
    super.key,
    required this.usuarioRepository,
    required this.estadoPsicologicoRepository,
    required this.tareaRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UsuarioRepository>.value(value: usuarioRepository),
        RepositoryProvider<EstadoPsicologicoRepository>.value(
          value: estadoPsicologicoRepository,
        ),
        RepositoryProvider<TareaRepository>.value(value: tareaRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(usuarioRepository)..add(AuthCheckSession()),
          ),
          BlocProvider<UsuarioBloc>(
            create: (_) => UsuarioBloc(usuarioRepository),
          ),
          BlocProvider<EstadoPsicologicoBloc>(
            create: (_) => EstadoPsicologicoBloc(estadoPsicologicoRepository),
          ),
          BlocProvider<ChatEmocionalBloc>(create: (_) => ChatEmocionalBloc()),
          BlocProvider<TareaBloc>(create: (_) => TareaBloc(tareaRepository)),
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
                return const LoginScreen();
              }
            },
            '/resources': (_) => const ResourcesScreen(),
            '/article_webview': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, String>;
              return ArticleWebViewScreen(
                url: args['url']!,
                title: args['title']!,
              );
            },
            '/formulario-psicologico': (_) => const FormularioPsicologicoPage(),
            '/chat-emocional': (_) => const ChatScreen(),
            '/tasks': (context) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                return TareasScreen(usuarioId: authState.usuario.localId);
              } else {
                return const LoginScreen();
              }
            },
            '/announcements': (_) => const AnnouncementsScreen(),
          },
        ),
      ),
    );
  }
}
