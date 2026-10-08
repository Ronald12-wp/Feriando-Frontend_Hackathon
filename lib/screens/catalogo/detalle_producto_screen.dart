import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/chat_service.dart';
import '../../services/producto_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/estado_badge.dart';
import '../chat/chat_screen.dart';
import '../trueques/solicitar_trueque_screen.dart';

class DetalleProductoScreen extends StatefulWidget {
  final int productoID;
  const DetalleProductoScreen({super.key, required this.productoID});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final ProductoService _service = ProductoService();
  final TextEditingController _mensajeRapidoController = TextEditingController(
    text: 'Hola. ¿Sigue estando disponible?',
  );
  Producto? _producto;
  bool _cargando = true;
  bool _enviandoMensaje = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _mensajeRapidoController.dispose();
    super.dispose();
  }

  Future<void> _enviarConsulta(int usuarioActualID) async {
    final mensaje = _mensajeRapidoController.text.trim();
    if (mensaje.isEmpty || _producto == null || _enviandoMensaje) return;

    setState(() => _enviandoMensaje = true);
    final lang = context.read<LanguageProvider>();
    final chatId = ChatService.crearChatId(
      productoId: _producto!.productoID,
      productorId: _producto!.usuarioID,
      otroUsuarioId: usuarioActualID,
    );

    try {
      await context.read<ChatProvider>().restaurarConversacion(chatId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            usuarioActualId: usuarioActualID,
            nombreContacto: _producto!.nombreProductora,
            mensajeInicial: mensaje,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('product_quick_message_error'))),
      );
    } finally {
      if (mounted) setState(() => _enviandoMensaje = false);
    }
  }

  Future<void> _cargar() async {
    try {
      final producto = await _service.obtener(widget.productoID);
      if (!mounted) return;
      setState(() {
        _producto = producto;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActualID = context.read<AuthProvider>().usuario?.usuarioID;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('product_detail_title'))),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.verdeMilpa))
          : _producto == null
              ? Center(child: Text(lang.translate('product_not_found')))
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_producto!.imagenes.isNotEmpty)
                              SizedBox(
                                height: 220,
                                child: PageView.builder(
                                  itemCount: _producto!.imagenes.length,
                                  itemBuilder: (context, index) {
                                    final url = _producto!.imagenUrl(index);
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.verdeMilpaSuave,
                                          child: const Icon(Icons.broken_image_outlined, size: 64, color: AppColors.verdeMilpa),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 180,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.verdeMilpaSuave,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.storefront, size: 64, color: AppColors.verdeMilpa),
                              ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Text(_producto!.nombre, style: AppTextStyles.h1)),
                                EstadoBadge(estado: _producto!.estado),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_producto!.cantidad} ${_producto!.unidadMedida} · ${_producto!.categoria}',
                              style: AppTextStyles.cuerpoDestacado.copyWith(color: AppColors.textoSecundario),
                            ),
                            const SizedBox(height: 16),
                            if (_producto!.descripcion != null && _producto!.descripcion!.isNotEmpty) ...[
                              Text(lang.translate('product_description'), style: AppTextStyles.etiqueta),
                              const SizedBox(height: 4),
                              Text(_producto!.descripcion!, style: AppTextStyles.cuerpo),
                              const SizedBox(height: 16),
                            ],
                            
                            // Tarjeta de Información del Productor y Ubicación
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.superficie,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borde),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.anil,
                                        child: Icon(Icons.person, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_producto!.nombreProductora, style: AppTextStyles.cuerpoDestacado),
                                            Text(lang.translate('product_seller'), style: AppTextStyles.caption),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 20, color: AppColors.verdeMilpa),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_producto!.municipio}, ${_producto!.departamento}',
                                              style: AppTextStyles.cuerpoDestacado,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(label: Text('${lang.translate('product_offer')} ${_producto!.tipoOferta}')),
                                if (_producto!.precioReferencial != null)
                                  Chip(label: Text('C\$ ${_producto!.precioReferencial!.toStringAsFixed(0)}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_producto!.estado == 'Disponible' && _producto!.usuarioID != usuarioActualID)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _crearAccesoMensaje(lang, usuarioActualID),
                              const SizedBox(height: 12),
                              AppButton(
                                texto: lang.translate('request_swap'),
                                icono: Icons.sync_alt,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SolicitarTruequeScreen(productoDeseado: _producto!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _crearAccesoMensaje(LanguageProvider lang, int? usuarioActualID) {
    final puedeEnviar = usuarioActualID != null && !_enviandoMensaje;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.verdeMilpa, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.translate('product_quick_message_title'),
                  style: AppTextStyles.etiqueta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _mensajeRapidoController,
                  enabled: puedeEnviar,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 4000,
                  decoration: InputDecoration(
                    hintText: lang.translate('product_quick_message_hint'),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.cremaTortilla,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.borde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.borde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppColors.verdeMilpa, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: puedeEnviar
                      ? () => _enviarConsulta(usuarioActualID!)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.verdeMilpa,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _enviandoMensaje
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(lang.translate('send')),
                ),
              ),
            ],
          ),
          if (usuarioActualID == null) ...[
            const SizedBox(height: 6),
            Text(
              lang.translate('product_quick_message_login'),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}
