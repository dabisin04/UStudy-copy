import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/presentation/blocs/chat/chat_bloc.dart';
import 'package:ustudy/presentation/blocs/chat/chat_state.dart';
import 'package:ustudy/domain/entities/chat_message.dart';

class ChatSummaryCard extends StatelessWidget {
  const ChatSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatEmocionalBloc, ChatEmocionalState>(
      builder: (context, state) {
        ChatMessage? lastMessage;

        if (state is ChatHistorialCargado && state.mensajes.isNotEmpty) {
          lastMessage = state.mensajes.last;
        } else if (state is ChatRespuestaRecibida) {
          lastMessage = state.mensaje;
        }

        final bool hasLastMessage =
            lastMessage != null && lastMessage.text.trim().isNotEmpty;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/chat-emocional');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasLastMessage
                ? Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lastMessage!.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "Try It!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.chat_outlined),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We have implemented a chatBot with artificial intelligence so you can count on it all day long.",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.chat, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Hello There!",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
