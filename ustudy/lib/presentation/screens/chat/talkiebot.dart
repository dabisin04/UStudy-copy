import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ustudy/infrastructure/utils/session.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_bloc.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_event.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_state.dart';

import 'package:ustudy/presentation/blocs/chat/chat_bloc.dart';
import 'package:ustudy/presentation/blocs/chat/chat_event.dart';
import 'package:ustudy/presentation/blocs/chat/chat_state.dart';
import 'package:ustudy/domain/entities/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  String? usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    print('🔍 [ChatScreen] _cargarUsuario() iniciado');

    final session = await SessionService.getUserSession();
    usuarioId = session?['remoteId']; // ✅ Clave correcta desde SessionService

    print('🔍 [ChatScreen] usuarioId: $usuarioId');

    if (usuarioId != null && usuarioId!.isNotEmpty) {
      print('🔍 [ChatScreen] Enviando VerificarEvaluacionInicial');
      context.read<EstadoPsicologicoBloc>().add(
        VerificarEvaluacionInicial(usuarioId!),
      );
      print('🔍 [ChatScreen] Enviando CargarHistorialChat');
      context.read<ChatEmocionalBloc>().add(CargarHistorialChat(usuarioId!));
    } else {
      print('❌ [ChatScreen] usuarioId es null o vacío');
    }
  }

  void _sendMessage(String text) {
    print('🔍 [ChatScreen] _sendMessage() llamado con: "$text"');
    if (text.trim().isEmpty || usuarioId == null) {
      print(
        '❌ [ChatScreen] Texto vacío o usuarioId null. Texto: "${text.trim()}", usuarioId: $usuarioId',
      );
      return;
    }

    final messageText = text.trim();
    print('🔍 [ChatScreen] Añadiendo mensaje del usuario: "$messageText"');
    setState(() {
      _messages.add(_ChatMessage(text: messageText, isUser: true));
      _controller.clear();
    });
    print('🔍 [ChatScreen] Mensajes en UI: ${_messages.length}');

    print('🔍 [ChatScreen] Enviando EnviarMensajeChat al bloc');
    context.read<ChatEmocionalBloc>().add(
      EnviarMensajeChat(usuarioId!, messageText),
    );
  }

  void _manejarRespuesta(String textoIA) {
    print('🔍 [ChatScreen] _manejarRespuesta() llamado con: "$textoIA"');
    setState(() {
      _messages.add(_ChatMessage(text: textoIA, isUser: false));
    });
    print(
      '🔍 [ChatScreen] Respuesta añadida. Total mensajes: ${_messages.length}',
    );
  }

  void _cargarHistorial(List<ChatMessage> historial) {
    print(
      '🔍 [ChatScreen] _cargarHistorial() llamado con ${historial.length} mensajes',
    );
    setState(() {
      _messages.clear();
      for (final msg in historial) {
        _messages.add(_ChatMessage(text: msg.text, isUser: msg.isUser));
      }
    });
    print(
      '🔍 [ChatScreen] Historial cargado. Total mensajes: ${_messages.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EstadoPsicologicoBloc, EstadoPsicologicoState>(
          listener: (context, state) {
            print('🔍 [ChatScreen] EstadoPsicologicoBloc state: $state');
            if (state is EvaluacionPendiente) {
              print(
                '🔍 [ChatScreen] Evaluación pendiente, navegando a formulario',
              );
              Navigator.pushReplacementNamed(
                context,
                '/formulario-psicologico',
              );
            }
          },
        ),
        BlocListener<ChatEmocionalBloc, ChatEmocionalState>(
          listener: (context, state) {
            print('🔍 [ChatScreen] ChatEmocionalBloc state: $state');
            if (state is ChatRespuestaRecibida) {
              print('🔍 [ChatScreen] Respuesta recibida: ${state.respuesta}');
              _manejarRespuesta(state.respuesta);
            }
            if (state is ChatHistorialCargado) {
              print(
                '🔍 [ChatScreen] Historial cargado: ${state.mensajes.length} mensajes',
              );
              _cargarHistorial(state.mensajes);
            }
            if (state is ChatError) {
              print('❌ [ChatScreen] Error en chat: ${state.mensaje}');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.mensaje)));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Chat with TalkieBot'),
          centerTitle: false,
          elevation: 1,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _sendMessage,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: "Type here...",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
