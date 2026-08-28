import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/catalogos.dart';
import '../../models/producto.dart';
import '../../providers/language_provider.dart';
import '../../providers/producto_provider.dart';
import '../../services/api_client.dart';
import '../../services/catalogo_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Un solo formulario para las dos operaciones:
/// - productoExistente == null  -> CREATE (POST /api/productos)
/// - productoExistente != null  -> UPDATE (PUT /api/productos/{id})
class PublicarProductoScreen extends StatefulWidget {
  final Producto? productoExistente;
  const PublicarProductoScreen({super.key, this.productoExistente});

  bool get esEdicion => productoExistente != null;

  @override
  State<PublicarProductoScreen> createState() => _PublicarProductoScreenState();
}

class _PublicarProductoScreenState extends State<PublicarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _cantidad = TextEditingController(text: '1');
  final _precio = TextEditingController();
  final _direccionExacta = TextEditingController();

  final CatalogoService _catalogoService = CatalogoService();
  final ImagePicker _picker = ImagePicker();

  List<Categoria> _categorias = [];
  List<UnidadMedida> _unidades = [];
  List<Departamento> _departamentos = [];
  List<Municipio> _municipiosDisponibles = [];
  final List<XFile> _imagenesSeleccionadas = [];
  final List<String> _imagenesActuales = [];
  List<String> _imagenesOriginales = [];

  Categoria? _categoriaSeleccionada;
  UnidadMedida? _unidadSeleccionada;
  Departamento? _departamentoSeleccionado;
  Municipio? _municipioSeleccionado;

  String _tipoOferta = 'Trueque';
  bool _cargandoCatalogos = true;
  String? _errorCargaCatalogos;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _precargarSiEsEdicion();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _cantidad.dispose();
    _precio.dispose();
    _direccionExacta.dispose();
    super.dispose();
  }

  void _precargarSiEsEdicion() {
    final p = widget.productoExistente;
    if (p == null) return;
    _nombre.text = p.nombre;
    _descripcion.text = p.descripcion ?? '';
    _cantidad.text = p.cantidad.toString();
    _precio.text = p.precioReferencial?.toString() ?? '';
    _direccionExacta.text = '';
    _tipoOferta = p.tipoOferta;
    _imagenesOriginales = List<String>.from(p.imagenes);
    _imagenesActuales.addAll(_imagenesOriginales);
  }

  Future<void> _cargarCatalogos() async {
    try {
      final categorias = await _catalogoService.categorias();
      final unidades = await _catalogoService.unidadesMedida();
      final departamentos = await _catalogoService.departamentos();

      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _unidades = unidades;
        _departamentos = departamentos;

        if (widget.productoExistente != null) {
          final p = widget.productoExistente!;
          _categoriaSeleccionada =
              categorias.where((c) => c.nombre == p.categoria).firstOrNull;
          _unidadSeleccionada =
              unidades.where((u) => u.nombre == p.unidadMedida).firstOrNull;

          _departamentoSeleccionado = departamentos
              .where((d) => d.nombre == p.departamento)
              .firstOrNull;
          if (_departamentoSeleccionado != null) {
            _municipiosDisponibles = _departamentoSeleccionado!.municipios;
            _municipioSeleccionado = _municipiosDisponibles
                .where((m) => m.nombre == p.municipio)
                .firstOrNull;
          }
        }
        _cargandoCatalogos = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoCatalogos = false;
          _errorCargaCatalogos = e.toString();
        });
      }
    }
  }

  void _onDepartamentoChanged(Departamento? dep) {
    setState(() {
      _departamentoSeleccionado = dep;
      _municipioSeleccionado = null;
      _municipiosDisponibles = dep?.municipios ?? [];
    });
  }

  Future<void> _seleccionarImagenes() async {
    final resultados =
        await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
    if (resultados.isEmpty) return;
    setState(() {
      _imagenesSeleccionadas.addAll(resultados);
    });
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesSeleccionadas.removeAt(index);
    });
  }

  void _eliminarImagenActual(int index) {
    setState(() {
      _imagenesActuales.removeAt(index);
    });
  }

  Future<void> _guardar() async {
    final lang = context.read<LanguageProvider>();
    if (!_formKey.currentState!.validate()) return;
    if (!widget.esEdicion &&
        (_categoriaSeleccionada == null || _unidadSeleccionada == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(lang.translate('publish_product_select_category_unit'))),
      );
      return;
    }

    if (_departamentoSeleccionado == null || _municipioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang
                .translate('publish_product_select_department_municipality'))),
      );
      return;
    }

    setState(() => _guardando = true);

    final reemplazarImagenes = widget.esEdicion &&
        (_imagenesSeleccionadas.isNotEmpty ||
            _imagenesActuales.length != _imagenesOriginales.length ||
            _imagenesActuales.toSet().length !=
                _imagenesOriginales.toSet().length ||
            _imagenesActuales
                .toSet()
                .difference(_imagenesOriginales.toSet())
                .isNotEmpty ||
            _imagenesOriginales
                .toSet()
                .difference(_imagenesActuales.toSet())
                .isNotEmpty);

    final formulario = ProductoFormulario(
      categoriaID: _categoriaSeleccionada?.categoriaID,
      nombre: _nombre.text.trim(),
      descripcion:
          _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      cantidad: double.tryParse(_cantidad.text) ?? 1,
      unidadMedidaID: _unidadSeleccionada?.unidadMedidaID,
      municipioID: _municipioSeleccionado!.municipioID,
      direccionExacta: _direccionExacta.text.trim().isEmpty
          ? null
          : _direccionExacta.text.trim(),
      tipoOferta: _tipoOferta,
      precioReferencial:
          _precio.text.trim().isEmpty ? null : double.tryParse(_precio.text),
      reemplazarImagenes: reemplazarImagenes,
      imagenesXFiles: _imagenesSeleccionadas.toList(),
    );

    try {
      final provider = context.read<ProductoProvider>();
      if (widget.esEdicion) {
        await provider.actualizar(
            widget.productoExistente!.productoID, formulario);
      } else {
        await provider.crear(formulario);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e is ApiException
                  ? e.mensaje
                  : lang.translate('publish_product_save_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.esEdicion
              ? lang.translate('edit_product_title')
              : lang.translate('publish_product_title'))),
      body: _cargandoCatalogos
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.verdeMilpa))
          : _errorCargaCatalogos != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(lang.translate('publish_product_error_loading'),
                            style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text(
                          _errorCargaCatalogos!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textoSecundario),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _cargandoCatalogos = true;
                              _errorCargaCatalogos = null;
                            });
                            _cargarCatalogos();
                          },
                          child: Text(lang.translate('publish_product_retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        AppTextField(
                          etiqueta: lang.translate('product_name_label'),
                          controller: _nombre,
                          validador: (v) => (v == null || v.trim().isEmpty)
                              ? lang.translate('enter_name')
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          etiqueta: lang.translate('product_description_label'),
                          controller: _descripcion,
                          maxLineas: 3,
                        ),
                        const SizedBox(height: 14),
                        Text(lang.translate('publish_images'),
                            style: AppTextStyles.etiqueta),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _seleccionarImagenes,
                              icon: const Icon(Icons.photo_library),
                              label:
                                  Text(lang.translate('publish_select_images')),
                            ),
                            if (_imagenesSeleccionadas.isNotEmpty)
                              Text(
                                  lang
                                      .translate('publish_images_selected')
                                      .replaceFirst(
                                          '{count}',
                                          _imagenesSeleccionadas.length
                                              .toString()),
                                  style: AppTextStyles.caption),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (widget.esEdicion && _imagenesActuales.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imagenesActuales.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, index) {
                                final imagen = _imagenesActuales[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        Producto.resolverUrl(imagen),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 120,
                                          height: 120,
                                          color: AppColors.borde,
                                          child: const Icon(
                                              Icons.broken_image_outlined),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () =>
                                            _eliminarImagenActual(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black54,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        if (_imagenesSeleccionadas.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imagenesSeleccionadas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, index) {
                                final imagen = _imagenesSeleccionadas[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        File(imagen.path),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => _eliminarImagen(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black54,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 14),
                        if (!widget.esEdicion) ...[
                          DropdownButtonFormField<Categoria>(
                            initialValue: _categoriaSeleccionada,
                            decoration: InputDecoration(
                                labelText: lang.translate('category_label')),
                            items: _categorias
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c.nombre)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _categoriaSeleccionada = v),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                etiqueta: lang.translate('quantity_label'),
                                controller: _cantidad,
                                tipoTeclado: TextInputType.number,
                                validador: (v) =>
                                    (double.tryParse(v ?? '') == null)
                                        ? lang.translate('invalid_quantity')
                                        : null,
                              ),
                            ),
                            if (!widget.esEdicion) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<UnidadMedida>(
                                  initialValue: _unidadSeleccionada,
                                  decoration: InputDecoration(
                                      labelText: lang.translate('unit_label')),
                                  items: _unidades
                                      .map((u) => DropdownMenuItem(
                                          value: u, child: Text(u.nombre)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _unidadSeleccionada = v),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Sección de Ubicación Geográfica
                        Text(lang.translate('publish_location'),
                            style: AppTextStyles.etiqueta),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Departamento>(
                                initialValue: _departamentoSeleccionado,
                                isExpanded: true,
                                menuMaxHeight: 220,
                                decoration: InputDecoration(
                                    labelText:
                                        lang.translate('catalog_department')),
                                items: _departamentos
                                    .map((d) => DropdownMenuItem(
                                        value: d, child: Text(d.nombre)))
                                    .toList(),
                                onChanged: _onDepartamentoChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<Municipio>(
                                initialValue: _municipioSeleccionado,
                                isExpanded: true,
                                menuMaxHeight: 220,
                                decoration: InputDecoration(
                                    labelText:
                                        lang.translate('catalog_municipality')),
                                items: _municipiosDisponibles
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m.nombre)))
                                    .toList(),
                                onChanged: _departamentoSeleccionado == null
                                    ? null
                                    : (v) => setState(
                                        () => _municipioSeleccionado = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          etiqueta: lang.translate('location_exact_optional'),
                          controller: _direccionExacta,
                        ),

                        const SizedBox(height: 18),
                        Text(lang.translate('offer_type'),
                            style: AppTextStyles.etiqueta),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: ['Trueque', 'Venta', 'Ambos']
                              .map((t) => ChoiceChip(
                                    label: Text(_textoOferta(lang, t)),
                                    selected: _tipoOferta == t,
                                    selectedColor: AppColors.verdeMilpaSuave,
                                    onSelected: (_) =>
                                        setState(() => _tipoOferta = t),
                                  ))
                              .toList(),
                        ),
                        if (_tipoOferta != 'Trueque') ...[
                          const SizedBox(height: 14),
                          AppTextField(
                            etiqueta: lang.translate('price_label'),
                            controller: _precio,
                            tipoTeclado: TextInputType.number,
                          ),
                        ],
                        const SizedBox(height: 28),
                        AppButton(
                          texto: widget.esEdicion
                              ? lang.translate('publish_product_save')
                              : lang.translate('publish_product_create'),
                          onPressed: _guardar,
                          cargando: _guardando,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _textoOferta(LanguageProvider lang, String tipo) {
    switch (tipo) {
      case 'Venta':
        return lang.translate('offer_venta');
      case 'Ambos':
        return lang.translate('offer_ambos');
      default:
        return lang.translate('offer_trueque');
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
