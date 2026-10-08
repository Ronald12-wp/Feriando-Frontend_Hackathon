import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/mensaje_chat.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final int usuarioActualId;
  final String nombreContacto;
  final String? mensajeInicial;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.usuarioActualId,
    required this.nombreContacto,
    this.mensajeInicial,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MensajeChat> _mensajes = [];
  bool _cargando = true;
  bool _conectado = false;

  @override
  void initState() {
    super.initState();
    final mensajeInicial = widget.mensajeInicial?.trim();
    if (mensajeInicial != null && mensajeInicial.isNotEmpty) {
      _mensajeController.text = mensajeInicial;
    }
    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    final historial = await _chatService.obtenerHistorial(widget.chatId);

    if (!mounted) return;

    setState(() {
      _mensajes.addAll(historial);
      _cargando = false;
    });

    try {
      await context.read<ChatProvider>().marcarComoLeida(widget.chatId);
    } catch (_) {}

    try {
      await _chatService.conectarSignalR(widget.chatId, _manejarNuevoMensaje);
      if (!mounted) return;
      setState(() => _conectado = _chatService.isConnected);
      if (_conectado && _mensajeController.text.trim().isNotEmpty) {
        await _enviarMensaje();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _conectado = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollHastaAbajo());
  }

  void _manejarNuevoMensaje(MensajeChat mensaje) {
    if (!mounted) return;
    setState(() {
      _mensajes.add(mensaje);
    });
    if (mensaje.emisorId != widget.usuarioActualId) {
      context.read<ChatProvider>().marcarComoLeida(widget.chatId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollHastaAbajo());
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || !_conectado) return;

    try {
      await _chatService.enviarMensaje(widget.chatId, texto);
      _mensajeController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().translate('chat_send_error'))),
      );
    }
  }

  void _scrollHastaAbajo() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max > 0) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatearFecha(String fecha) {
    final fechaDate = DateTime.tryParse(fecha);
    if (fechaDate == null) return '';
    return DateFormat('HH:mm').format(fechaDate);
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    _chatService.desconectar(widget.chatId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      // AQUÍ SE AGREGA EL FONDO DE PANTALLA
      decoration: const BoxDecoration(
        color: AppColors.superficie, // Color de respaldo
        image: DecorationImage(
          // Cambia la ruta por la imagen de tu carpeta assets
          image: AssetImage('assets/images/fondo_chat.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        // HACEMOS EL SCAFFOLD TRANSPARENTE PARA QUE SE VEA LA IMAGEN DE FONDO
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.verdeMilpaSuave,
                child: Icon(Icons.person, color: AppColors.verdeMilpa),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.nombreContacto,
                  style: AppTextStyles.cuerpoDestacado,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.circle,
                size: 10,
                color: _conectado ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
        body: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.verdeMilpa),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _mensajes.length,
                      itemBuilder: (context, index) {
                        final mensaje = _mensajes[index];
                        final esMio =
                            mensaje.emisorId == widget.usuarioActualId;

                        return Align(
                          alignment: esMio
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: esMio
                                    ? AppColors.verdeMilpa
                                    : AppColors.verdeMilpaSuave,
                                borderRadius: esMio
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                        bottomLeft: Radius.circular(18),
                                        bottomRight: Radius.circular(4),
                                      )
                                    : const BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(18),
                                      ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mensaje.mensaje,
                                    style: AppTextStyles.cuerpo.copyWith(
                                      color: esMio
                                          ? Colors.white
                                          : AppColors.textoPrimario,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatearFecha(mensaje.fechaEnvio),
                                      style: AppTextStyles.caption.copyWith(
                                        color: esMio
                                            ? Colors.white70
                                            : AppColors.textoSecundario,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      decoration: const BoxDecoration(
                        color: AppColors.superficie,
                        border: Border(top: BorderSide(color: AppColors.borde)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mensajeController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: lang.translate('chat_message_hint'),
                                filled: true,
                                fillColor: AppColors.cremaTortilla,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            onPressed: _conectado ? _enviarMensaje : null,
                            backgroundColor: AppColors.mensajeriaAzul,
                            child: const Icon(Icons.send, color: Colors.white),
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
