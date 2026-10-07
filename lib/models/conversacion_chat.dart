class ConversacionChat {
  final String chatId;
  final int productoId;
  final String nombreProducto;
  final int usuarioContactoId;
  final String nombreContacto;
  final String ultimoMensaje;
  final DateTime fechaEnvio;
  final int emisorId;
  final int mensajesNoLeidos;

  const ConversacionChat({
    required this.chatId,
    required this.productoId,
    required this.nombreProducto,
    required this.usuarioContactoId,
    required this.nombreContacto,
    required this.ultimoMensaje,
    required this.fechaEnvio,
    required this.emisorId,
    required this.mensajesNoLeidos,
  });

  factory ConversacionChat.fromJson(Map<String, dynamic> json) {
    return ConversacionChat(
      chatId: json['chatId'] as String? ?? '',
      productoId: json['productoId'] as int? ?? 0,
      nombreProducto: json['nombreProducto'] as String? ?? '',
      usuarioContactoId: json['usuarioContactoId'] as int? ?? 0,
      nombreContacto: json['nombreContacto'] as String? ?? '',
      ultimoMensaje: json['ultimoMensaje'] as String? ?? '',
      fechaEnvio: DateTime.tryParse(json['fechaEnvio'] as String? ?? '') ??
          DateTime.now(),
      emisorId: json['emisorId'] as int? ?? 0,
      mensajesNoLeidos: json['mensajesNoLeidos'] as int? ?? 0,
    );
  }
}
