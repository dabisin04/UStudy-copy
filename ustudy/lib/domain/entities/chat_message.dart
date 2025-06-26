class ChatMessage {
  final String text;
  final bool isUser;
  final bool esRecomendacion;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.esRecomendacion = false,
  });

  Map<String, dynamic> toMap() {
    return {'text': text, 'isUser': isUser, 'esRecomendacion': esRecomendacion};
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      esRecomendacion: map['esRecomendacion'] ?? false,
    );
  }
}
