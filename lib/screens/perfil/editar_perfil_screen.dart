import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/catalogos.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/catalogo_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarPerfilScreen({required this.usuario, super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _direccionController;

  final CatalogoService _catalogoService = CatalogoService();
  final ImagePicker _picker = ImagePicker();
  List<Departamento> _departamentos = [];
  List<Municipio> _municipiosDisponibles = [];
  Departamento? _departamentoSeleccionado;
  Municipio? _municipioSeleccionado;
  Idioma? _idiomaSeleccionado;
  String? _generoSeleccionado;
  bool _esProductora = true;
  bool _cargando = false;
  bool _cargandoCatalogos = true;
  String? _errorCargaCatalogos;
  String? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.usuario.nombres);
    _apellidosController =
        TextEditingController(text: widget.usuario.apellidos);
    _telefonoController = TextEditingController(text: widget.usuario.telefono);
    _correoController =
        TextEditingController(text: widget.usuario.correo ?? '');
    _direccionController =
        TextEditingController(text: widget.usuario.direccionExacta ?? '');
    _generoSeleccionado = const {'F', 'M', 'O'}.contains(widget.usuario.genero)
        ? widget.usuario.genero
        : null;
    _esProductora = widget.usuario.esProductora;
    _idiomaSeleccionado = LanguageProvider.supportedLanguages
        .where((idioma) => idioma.idiomaID == widget.usuario.idiomaPreferidoID)
        .firstOrNull;
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final departamentos = await _catalogoService.departamentos();
      if (!mounted) return;

      final municipioID = widget.usuario.municipioID;
      final departamento = departamentos.where((d) {
        return d.municipios.any((m) =>
            m.municipioID == municipioID ||
            (municipioID == null &&
                m.nombre == widget.usuario.municipio &&
                d.nombre == widget.usuario.departamento));
      }).firstOrNull;

      setState(() {
        _departamentos = departamentos;
        _departamentoSeleccionado = departamento;
        _municipiosDisponibles = departamento?.municipios ?? [];
        _municipioSeleccionado = _municipiosDisponibles
            .where((m) =>
                m.municipioID == municipioID ||
                (municipioID == null && m.nombre == widget.usuario.municipio))
            .firstOrNull;
        _idiomaSeleccionado ??= LanguageProvider.supportedLanguages
            .where((idioma) =>
                idioma.idiomaID ==
                context.read<LanguageProvider>().currentIdiomaId)
            .firstOrNull;
        _cargandoCatalogos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoCatalogos = false;
        _errorCargaCatalogos = e.toString();
      });
    }
  }

  void _onDepartamentoChanged(Departamento? departamento) {
    setState(() {
      _departamentoSeleccionado = departamento;
      _municipiosDisponibles = departamento?.municipios ?? [];
      _municipioSeleccionado = null;
    });
  }

  Future<void> _seleccionarFoto() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen != null) {
      setState(() => _imagenSeleccionada = imagen.path);
    }
  }

  Future<void> _guardarCambios() async {
    final lang = context.read<LanguageProvider>();
    if (_nombresController.text.trim().isEmpty ||
        _apellidosController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('edit_profile_error_fields'))),
      );
      return;
    }
    if (_departamentoSeleccionado == null ||
        _municipioSeleccionado == null ||
        _idiomaSeleccionado == null ||
        _direccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.translate('edit_profile_complete_location'))),
      );
      return;
    }

    setState(() => _cargando = true);
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.actualizarPerfil(
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim().isEmpty
            ? null
            : _correoController.text.trim(),
        genero: _generoSeleccionado,
        municipioID: _municipioSeleccionado!.municipioID,
        direccionExacta: _direccionController.text.trim(),
        idiomaPreferidoID: _idiomaSeleccionado!.idiomaID,
        esProductora: _esProductora,
      );
      await context.read<LanguageProvider>().setLanguage(_idiomaSeleccionado!);

      if (_imagenSeleccionada != null) {
        await authProvider.actualizarFotoPerfil(_imagenSeleccionada!);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
            content: Text(context
                .read<LanguageProvider>()
                .translate('edit_profile_saved'))),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                '${context.read<LanguageProvider>().translate('profile_error')}$e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(context
              .watch<LanguageProvider>()
              .translate('edit_profile_title'))),
      body: _cargandoCatalogos
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.verdeMilpa))
          : _errorCargaCatalogos != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${context.watch<LanguageProvider>().translate('profile_error')}${_errorCargaCatalogos!}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _cargandoCatalogos = true;
                              _errorCargaCatalogos = null;
                            });
                            _cargarCatalogos();
                          },
                          child: Text(context
                              .watch<LanguageProvider>()
                              .translate('publish_product_retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          _imagenSeleccionada != null
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundImage: FileImage(
                                    File(_imagenSeleccionada!),
                                  ),
                                )
                              : (widget.usuario.fotoPerfil != null &&
                                      widget.usuario.fotoPerfil!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 50,
                                      backgroundImage: NetworkImage(
                                          widget.usuario.fotoPerfil!),
                                    )
                                  : CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppColors.verdeMilpa,
                                      child: Text(
                                        widget.usuario.iniciales,
                                        style: AppTextStyles.h1
                                            .copyWith(color: Colors.white),
                                      ),
                                    )),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _cargando ? null : _seleccionarFoto,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.verdeMilpa,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nombres
                    _buildTextField(
                      label: context
                          .watch<LanguageProvider>()
                          .translate('edit_profile_names'),
                      controller: _nombresController,
                      enabled: !_cargando,
                    ),
                    const SizedBox(height: 16),

                    // Apellidos
                    _buildTextField(
                      label: context
                          .watch<LanguageProvider>()
                          .translate('edit_profile_lastnames'),
                      controller: _apellidosController,
                      enabled: !_cargando,
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    _buildTextField(
                      label: context
                          .watch<LanguageProvider>()
                          .translate('edit_profile_phone'),
                      controller: _telefonoController,
                      enabled: !_cargando,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    _buildTextField(
                      label: context
                          .watch<LanguageProvider>()
                          .translate('edit_profile_email'),
                      controller: _correoController,
                      enabled: !_cargando,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context
                          .watch<LanguageProvider>()
                          .translate('profile_gender'),
                      style: AppTextStyles.etiqueta,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _generoSeleccionado,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(
                          value: 'F',
                          child: Text(context
                              .watch<LanguageProvider>()
                              .translate('register_female')),
                        ),
                        DropdownMenuItem(
                          value: 'M',
                          child: Text(context
                              .watch<LanguageProvider>()
                              .translate('register_male')),
                        ),
                        DropdownMenuItem(
                          value: 'O',
                          child: Text(context
                              .watch<LanguageProvider>()
                              .translate('profile_gender_other')),
                        ),
                      ],
                      onChanged: _cargando
                          ? null
                          : (value) =>
                              setState(() => _generoSeleccionado = value),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<Departamento>(
                      initialValue: _departamentoSeleccionado,
                      decoration: InputDecoration(
                        labelText: context
                            .watch<LanguageProvider>()
                            .translate('register_department'),
                      ),
                      items: _departamentos
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d.nombre)))
                          .toList(),
                      onChanged: _cargando ? null : _onDepartamentoChanged,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Municipio>(
                      initialValue: _municipioSeleccionado,
                      decoration: InputDecoration(
                        labelText: context
                            .watch<LanguageProvider>()
                            .translate('register_municipality'),
                      ),
                      items: _municipiosDisponibles
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m.nombre)))
                          .toList(),
                      onChanged: _cargando || _departamentoSeleccionado == null
                          ? null
                          : (value) =>
                              setState(() => _municipioSeleccionado = value),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: context
                          .watch<LanguageProvider>()
                          .translate('register_exact_address'),
                      controller: _direccionController,
                      enabled: !_cargando,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<Idioma>(
                      initialValue: _idiomaSeleccionado,
                      decoration: InputDecoration(
                        labelText: context
                            .watch<LanguageProvider>()
                            .translate('profile_language'),
                      ),
                      items: LanguageProvider.supportedLanguages
                          .map((idioma) => DropdownMenuItem(
                                value: idioma,
                                child: Text(idioma.nombre),
                              ))
                          .toList(),
                      onChanged: _cargando
                          ? null
                          : (value) =>
                              setState(() => _idiomaSeleccionado = value),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _esProductora,
                      onChanged: _cargando
                          ? null
                          : (value) => setState(() => _esProductora = value),
                      activeThumbColor: AppColors.verdeMilpa,
                      title: Text(context
                          .watch<LanguageProvider>()
                          .translate('register_publish_swap')),
                      subtitle: Text(context
                          .watch<LanguageProvider>()
                          .translate('register_publish_swap_subtitle')),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    ElevatedButton(
                      onPressed: _cargando ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeMilpa,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(context
                              .watch<LanguageProvider>()
                              .translate('edit_profile_save_changes')),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabled: enabled,
      ),
    );
  }
}
