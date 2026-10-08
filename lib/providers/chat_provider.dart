import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversacion_chat.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  List<ConversacionChat> conversaciones = [];
  bool cargando = true;
  bool error = false;
  bool _solicitudEnCurso = false;
  int? _usuarioActualId;
  Timer? _actualizador;

  int get chatsNoLeidos => conversaciones
      .where((conversacion) => conversacion.mensajesNoLeidos > 0)
      .map((conversacion) => conversacion.usuarioContactoId)
      .toSet()
      .length;

  Future<void> cargarConversaciones({
    required int usuarioId,
    bool silencioso = false,
  }) async {
    if (_solicitudEnCurso) return;
    _solicitudEnCurso = true;
    _usuarioActualId = usuarioId;

    if (!silencioso) {
      cargando = true;
      error = false;
      notifyListeners();
    }

    try {
      conversaciones = await _service.obtenerConversaciones();
      error = false;
      _actualizador ??= Timer.periodic(
        const Duration(seconds: 12),
        (_) {
          final id = _usuarioActualId;
          if (id != null) cargarConversaciones(usuarioId: id, silencioso: true);
        },
      );
    } catch (_) {
      error = true;
    } finally {
      _solicitudEnCurso = false;
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> ocultarConversacion(String chatId) async {
    final indice = conversaciones.indexWhere((conversacion) => conversacion.chatId == chatId);
    if (indice < 0) return;
    final conversacion = conversaciones.removeAt(indice);
    notifyListeners();

    try {
      await _service.ocultarConversacion(chatId);
    } catch (_) {
      conversaciones.insert(indice.clamp(0, conversaciones.length).toInt(), conversacion);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restaurarConversacion(String chatId) async {
    await _service.restaurarConversacion(chatId);
    final usuarioId = _usuarioActualId;
    if (usuarioId != null) {
      await cargarConversaciones(usuarioId: usuarioId);
    }
  }

  Future<void> marcarComoLeida(String chatId) async {
    await _service.marcarComoLeida(chatId);
    final usuarioId = _usuarioActualId;
    if (usuarioId != null) {
      await cargarConversaciones(usuarioId: usuarioId, silencioso: true);
    }
  }

  @override
  void dispose() {
    _actualizador?.cancel();
    super.dispose();
  }
}
