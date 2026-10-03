import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversacion_chat.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  List<ConversacionChat> conversaciones = [];
  final Set<String> _conversacionesOcultas = {};
  bool cargando = true;
  bool error = false;
  bool _solicitudEnCurso = false;
  int? _usuarioActualId;
  Timer? _actualizador;

  int get mensajesNoLeidos => conversaciones.fold(
        0,
        (total, conversacion) => total + conversacion.mensajesNoLeidos,
      );

  Future<void> cargarConversaciones({
    required int usuarioId,
    bool silencioso = false,
  }) async {
    if (_solicitudEnCurso) return;
    _solicitudEnCurso = true;

    if (_usuarioActualId != usuarioId) {
      _usuarioActualId = usuarioId;
      final prefs = await SharedPreferences.getInstance();
      _conversacionesOcultas
        ..clear()
        ..addAll(
            prefs.getStringList('feriando_chats_ocultos_$usuarioId') ?? []);
    }

    if (!silencioso) {
      cargando = true;
      error = false;
      notifyListeners();
    }

    try {
      final todas = await _service.obtenerConversaciones();
      final llegoMensajeNuevo = todas.any(
        (conversacion) =>
            _conversacionesOcultas.contains(conversacion.chatId) &&
            conversacion.mensajesNoLeidos > 0,
      );
      if (llegoMensajeNuevo) {
        _conversacionesOcultas.removeWhere(
          (chatId) => todas.any(
            (conversacion) =>
                conversacion.chatId == chatId &&
                conversacion.mensajesNoLeidos > 0,
          ),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'feriando_chats_ocultos_$usuarioId',
          _conversacionesOcultas.toList(),
        );
      }
      conversaciones = todas
          .where((conversacion) =>
              !_conversacionesOcultas.contains(conversacion.chatId))
          .toList();
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
    _conversacionesOcultas.add(chatId);
    final usuarioId = _usuarioActualId;
    if (usuarioId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'feriando_chats_ocultos_$usuarioId',
        _conversacionesOcultas.toList(),
      );
    }
    conversaciones.removeWhere((conversacion) => conversacion.chatId == chatId);
    notifyListeners();
  }

  Future<void> restaurarConversacion(String chatId) async {
    if (!_conversacionesOcultas.remove(chatId)) return;
    final usuarioId = _usuarioActualId;
    if (usuarioId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'feriando_chats_ocultos_$usuarioId',
        _conversacionesOcultas.toList(),
      );
    }
    await cargarConversaciones(usuarioId: usuarioId!);
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
