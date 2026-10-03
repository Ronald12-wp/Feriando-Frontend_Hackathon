import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/conversacion_chat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _cargarConversaciones());
  }

  Future<void> _cargarConversaciones() async {
    final usuarioId = context.read<AuthProvider>().usuario?.usuarioID;
    if (usuarioId != null) {
      await context
          .read<ChatProvider>()
          .cargarConversaciones(usuarioId: usuarioId);
    }
  }

  Future<void> _abrirConversacion(
      ConversacionChat conversacion, int usuarioActualId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: conversacion.chatId,
          usuarioActualId: usuarioActualId,
          nombreContacto: conversacion.nombreContacto,
        ),
      ),
    );
    if (mounted) await _cargarConversaciones();
  }

  Future<bool> _confirmarOcultar() async {
    final lang = context.read<LanguageProvider>();
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(lang.translate('chat_delete_title')),
            content: Text(lang.translate('chat_delete_message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(lang.translate('chat_delete_cancel')),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.insigniaNoLeido),
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_outline),
                label: Text(lang.translate('chat_delete_action')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final usuarioActualId = context.watch<AuthProvider>().usuario?.usuarioID;
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('chats_title')),
        actions: [
          IconButton(
            tooltip: lang.translate('chats_title'),
            onPressed: _cargarConversaciones,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: usuarioActualId == null
          ? _estado(lang.translate('chats_login_required'), Icons.lock_outline)
          : chatProvider.cargando
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.verdeMilpa))
              : chatProvider.error
                  ? _estado(lang.translate('chats_load_error'),
                      Icons.cloud_off_outlined,
                      reintentar: _cargarConversaciones)
                  : chatProvider.conversaciones.isEmpty
                      ? _estado(
                          lang.translate('chats_empty_title'),
                          Icons.chat_bubble_outline,
                          detalle: lang.translate('chats_empty_message'),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarConversaciones,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: chatProvider.conversaciones.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final conversacion =
                                  chatProvider.conversaciones[index];
                              final inicial =
                                  conversacion.nombreContacto.trim().isEmpty
                                      ? '?'
                                      : conversacion.nombreContacto
                                          .trim()[0]
                                          .toUpperCase();

                              return Dismissible(
                                key: ValueKey(conversacion.chatId),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => _confirmarOcultar(),
                                onDismissed: (_) => context
                                    .read<ChatProvider>()
                                    .ocultarConversacion(conversacion.chatId),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  color: AppColors.insigniaNoLeido,
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.white),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 6),
                                  leading: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              AppColors.verdeMilpaSuave,
                                          child: Text(inicial,
                                              style: AppTextStyles
                                                  .cuerpoDestacado
                                                  .copyWith(
                                                      color: AppColors
                                                          .verdeMilpa)),
                                        ),
                                        if (conversacion.mensajesNoLeidos > 0)
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                  minWidth: 18, minHeight: 18),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              decoration: const BoxDecoration(
                                                  color:
                                                      AppColors.insigniaNoLeido,
                                                  shape: BoxShape.circle),
                                              alignment: Alignment.center,
                                              child: Text(
                                                conversacion.mensajesNoLeidos >
                                                        9
                                                    ? '9+'
                                                    : '${conversacion.mensajesNoLeidos}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  title: Text(conversacion.nombreContacto,
                                      style: AppTextStyles.cuerpoDestacado),
                                  subtitle: Text(
                                    '${conversacion.nombreProducto} · ${conversacion.ultimoMensaje}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption,
                                  ),
                                  trailing: Text(
                                    DateFormat('dd/MM').format(
                                        conversacion.fechaEnvio.toLocal()),
                                    style: AppTextStyles.caption,
                                  ),
                                  onTap: () => _abrirConversacion(
                                      conversacion, usuarioActualId),
                                ),
                              );
                            },
                          ),
                        ),
    );
  }

  Widget _estado(String titulo, IconData icono,
      {String? detalle, VoidCallback? reintentar}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 44, color: AppColors.verdeMilpa),
            const SizedBox(height: 12),
            Text(titulo, textAlign: TextAlign.center, style: AppTextStyles.h3),
            if (detalle != null) ...[
              const SizedBox(height: 8),
              Text(detalle,
                  textAlign: TextAlign.center, style: AppTextStyles.cuerpo),
            ],
            if (reintentar != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: reintentar,
                icon: const Icon(Icons.refresh),
                label: Text(context
                    .watch<LanguageProvider>()
                    .translate('publish_product_retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
