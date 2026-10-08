import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto.dart';
import '../../providers/language_provider.dart';
import '../../providers/producto_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/estado_badge.dart';
import 'publicar_producto_screen.dart';

class MisProductosScreen extends StatefulWidget {
  const MisProductosScreen({super.key});

  @override
  State<MisProductosScreen> createState() => _MisProductosScreenState();
}

class _MisProductosScreenState extends State<MisProductosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarMios();
    });
  }

  Future<void> _confirmarEliminar(Producto producto) async {
    final lang = context.read<LanguageProvider>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.translate('confirm_delete_title')),
        content: Text(lang.translate('confirm_delete_message').replaceFirst('{name}', producto.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('delete'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<ProductoProvider>().eliminar(producto.productoID);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('product_deleted'))),
        );
      }
    }
  }

  Future<void> _cambiarEstado(Producto producto) async {
    final lang = context.read<LanguageProvider>();
    final nuevoEstado = producto.estado == 'Disponible' ? 'Inactivo' : 'Disponible';
    try {
      await context.read<ProductoProvider>().cambiarEstado(
            producto.productoID,
            nuevoEstado,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('product_state_updated'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('product_state_error'))),
        );
      }
    }
  }

  String _obtenerUbicacionTexto(Producto producto) {
    if (producto.municipio.isNotEmpty && producto.departamento.isNotEmpty) {
      return '${producto.municipio}, ${producto.departamento}';
    }
    if (producto.municipio.isNotEmpty) {
      return producto.municipio;
    }
    return producto.departamento.isNotEmpty ? producto.departamento : '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.watch<LanguageProvider>().translate('my_products_title'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.achiote,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(context.watch<LanguageProvider>().translate('publish_label'), style: const TextStyle(color: Colors.white)),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PublicarProductoScreen()),
          );
          // ignore: use_build_context_synchronously
          if (mounted) context.read<ProductoProvider>().cargarMios();
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.cargarMios(),
        child: provider.cargando && provider.misProductos.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.verdeMilpa))
            : provider.misProductos.isEmpty
                ? EmptyState(
                    icono: Icons.inventory_2_outlined,
                    titulo: context.watch<LanguageProvider>().translate('my_products_empty_title'),
                    mensaje: context.watch<LanguageProvider>().translate('my_products_empty_message'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: provider.misProductos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final producto = provider.misProductos[i];
                      final ubicacion = _obtenerUbicacionTexto(producto);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(producto.nombre, style: AppTextStyles.h3)),
                                  EstadoBadge(estado: producto.estado),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${producto.cantidad} ${producto.unidadMedida} · ${producto.tipoOferta}',
                                style: AppTextStyles.caption,
                              ),
                              if (ubicacion.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textoSecundario,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        ubicacion,
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textoSecundario),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 4,
                                runSpacing: 0,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: Text(lang.translate('edit_label')),
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PublicarProductoScreen(productoExistente: producto),
                                        ),
                                      );
                                      // ignore: use_build_context_synchronously
                                      if (mounted) context.read<ProductoProvider>().cargarMios();
                                    },
                                  ),
                                  if (producto.estado == 'Disponible' || producto.estado == 'Inactivo')
                                    TextButton.icon(
                                      icon: Icon(
                                        producto.estado == 'Disponible'
                                            ? Icons.visibility_off_outlined
                                            : Icons.publish,
                                        size: 18,
                                      ),
                                      label: Text(lang.translate(
                                        producto.estado == 'Disponible'
                                            ? 'product_deactivate'
                                            : 'product_reactivate',
                                      )),
                                      onPressed: () => _cambiarEstado(producto),
                                    ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    label: Text(lang.translate('delete'), style: const TextStyle(color: AppColors.error)),
                                    onPressed: () => _confirmarEliminar(producto),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
