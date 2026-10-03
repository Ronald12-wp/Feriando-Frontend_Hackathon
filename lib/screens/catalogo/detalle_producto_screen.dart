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
  Producto? _producto;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            children: [
                              AppButton(
                                texto: lang.translate('chat_start'),
                                icono: Icons.chat_bubble_outline,
                                onPressed: usuarioActualID == null
                                    ? null
                                    : () {
                                        final chatId = ChatService.crearChatId(
                                          productoId: _producto!.productoID,
                                          productorId: _producto!.usuarioID,
                                          otroUsuarioId: usuarioActualID,
                                        );
                                        context
                                            .read<ChatProvider>()
                                            .restaurarConversacion(chatId);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              chatId: chatId,
                                              usuarioActualId: usuarioActualID,
                                              nombreContacto:
                                                  _producto!.nombreProductora,
                                            ),
                                          ),
                                        );
                                      },
                              ),
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
}
