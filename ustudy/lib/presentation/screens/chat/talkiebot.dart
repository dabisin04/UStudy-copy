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

import 'package:ustudy/presentation/blocs/tasks/tasks_bloc.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_event.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  String? usuarioId;
  int _offset = 0;
  final int _limit = 10;
  int _total = 0;
  bool _isLoadingMore = false;
  bool _mostrarBotonFormulario = false;
  bool _mostrarTarjetaRecomendacion = false;
  String _respuestaUsuario = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final session = await SessionService.getUserSession();
    usuarioId = session?['remoteId'];

    if (usuarioId != null && usuarioId!.isNotEmpty) {
      context.read<EstadoPsicologicoBloc>().add(
        VerificarEvaluacionInicial(usuarioId!),
      );
      // Cargar los mensajes más recientes primero
      context.read<ChatEmocionalBloc>().add(
        CargarHistorialChat(usuarioId!, offset: 0, limit: _limit),
      );
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _messages.length < _total) {
      _isLoadingMore = true;
      context.read<ChatEmocionalBloc>().add(
        CargarHistorialChat(
          usuarioId!,
          offset: _messages.length,
          limit: _limit,
        ),
      );
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || usuarioId == null) return;

    final messageText = text.trim();
    setState(() {
      _messages.add(_ChatMessage(text: messageText, isUser: true));
      _controller.clear();
    });

    context.read<ChatEmocionalBloc>().add(
      EnviarMensajeChat(usuarioId!, messageText),
    );

    // Scroll automático al final tras enviar mensaje
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _manejarRespuesta(ChatMessage mensajeIA) {
    setState(() {
      _messages.add(_ChatMessage(text: mensajeIA.text, isUser: false));

      // Si es una recomendación de formulario, mostrar la tarjeta
      if (mensajeIA.esRecomendacion ?? false) {
        _mostrarTarjetaRecomendacion = true;
      }
    });

    // Scroll automático al final tras recibir respuesta
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _actualizarMensajes(List<ChatMessage> nuevosMensajes) {
    setState(() {
      _messages.clear();
      for (final msg in nuevosMensajes) {
        _messages.add(_ChatMessage(text: msg.text, isUser: msg.isUser));
      }
      _isLoadingMore = false;
    });
  }

  void _aceptarFormulario() {
    setState(() {
      _mostrarTarjetaRecomendacion = false;
      _respuestaUsuario = 'Acepté realizar la evaluación psicológica';
    });

    // Agregar la respuesta del usuario como un mensaje
    _messages.add(
      _ChatMessage(
        text: _respuestaUsuario,
        isUser: true,
        isRespuestaFormulario: true,
      ),
    );

    // Navegar al formulario
    Navigator.pushNamed(context, '/formulario-psicologico');
  }

  void _ignorarFormulario() {
    setState(() {
      _mostrarTarjetaRecomendacion = false;
      _respuestaUsuario = 'Prefiero no hacerlo por el momento';
    });

    // Agregar la respuesta del usuario como un mensaje
    _messages.add(
      _ChatMessage(
        text: _respuestaUsuario,
        isUser: true,
        isRespuestaFormulario: true,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EstadoPsicologicoBloc, EstadoPsicologicoState>(
          listener: (context, state) {
            if (state is EvaluacionPendiente) {
              Navigator.pushReplacementNamed(
                context,
                '/formulario-psicologico',
              );
            }
          },
        ),
        BlocListener<ChatEmocionalBloc, ChatEmocionalState>(
          listener: (context, state) {
            if (state is ChatRespuestaRecibida) {
              _manejarRespuesta(state.mensaje);

              // Si hay tareas generadas, sincronizar
              if (state.tareasGeneradas.isNotEmpty && usuarioId != null) {
                // Sincronizar tareas después de un breve delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  context.read<TareaBloc>().add(
                    SincronizacionBidireccional(usuarioId!),
                  );
                });
              }
            }
            if (state is ChatHistorialCargado) {
              _total = state.total;
              _actualizarMensajes(state.mensajes);
            }
            if (state is ChatError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.mensaje)));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          leading: const BackButton(),
          title: const Text(
            'Chat with TalkieBot',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.assignment, color: Colors.white),
              onPressed: () =>
                  Navigator.pushNamed(context, '/formulario-psicologico'),
              tooltip: 'Realizar evaluación psicológica',
              style: IconButton.styleFrom(backgroundColor: Colors.black),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    _messages.length + (_mostrarTarjetaRecomendacion ? 1 : 0),
                itemBuilder: (context, index) {
                  // Si es el último índice y hay tarjeta de recomendación, mostrarla
                  if (_mostrarTarjetaRecomendacion &&
                      index == _messages.length) {
                    return _buildTarjetaRecomendacion();
                  }

                  final msg = _messages[index];
                  final isUser = msg.isUser;

                  return Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.chat_bubble_outline, size: 20),
                        ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg.isRespuestaFormulario
                                ? Colors.blue.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: msg.isRespuestaFormulario
                                  ? Colors.blue.shade300
                                  : Colors.black,
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontStyle: msg.isRespuestaFormulario
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                      if (isUser)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.person_outline, size: 20),
                        ),
                    ],
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
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

  Widget _buildTarjetaRecomendacion() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Evaluación Psicológica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '¿Te gustaría realizar una breve evaluación emocional para que pueda acompañarte mejor?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _aceptarFormulario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sí, acepto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _ignorarFormulario,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ahora no',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
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
  final bool isRespuestaFormulario;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isRespuestaFormulario = false,
  });
}
