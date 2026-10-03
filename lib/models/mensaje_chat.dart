class MensajeChat {
  final int? id;
  final String chatId;
  final int emisorId;
  final String mensaje;
  final String fechaEnvio;
  final bool leido;

  MensajeChat({
    this.id,
    required this.chatId,
    required this.emisorId,
    required this.mensaje,
    required this.fechaEnvio,
    this.leido = false,
  });

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'],
      chatId: json['chatId'] ?? '',
      emisorId: json['emisorId'] ?? 0,
      mensaje: json['mensaje'] ?? '',
      fechaEnvio: json['fechaEnvio'] ?? '',
      leido: json['leido'] ?? false,
    );
  }
}