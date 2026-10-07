import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalogos.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_client.dart';
import '../../services/catalogo_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _direccionExacta = TextEditingController();
  final _password = TextEditingController();

  final CatalogoService _catalogoService = CatalogoService();

  List<Departamento> _departamentos = [];
  Departamento? _departamentoSeleccionado;

  List<Municipio> _municipiosDisponibles = [];
  Municipio? _municipioSeleccionado;

  String _genero = 'F';
  bool _esProductora = true;
  bool _cargando = false;
  bool _cargandoCatalogos = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogosIniciales();
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _telefono.dispose();
    _correo.dispose();
    _direccionExacta.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogosIniciales() async {
    try {
      final deps = await _catalogoService.departamentos();
      if (!mounted) return;
      setState(() {
        _departamentos = deps;
        _cargandoCatalogos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoCatalogos = false);
    }
  }

  void _onDepartamentoChanged(Departamento? dep) {
    setState(() {
      _departamentoSeleccionado = dep;
      _municipioSeleccionado = null;
      _municipiosDisponibles = dep?.municipios ?? [];
    });
  }

  Future<void> _registrar() async {
    final languageProvider = context.read<LanguageProvider>();
    if (!_formKey.currentState!.validate()) return;
    if (_municipioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(languageProvider.translate('register_select_municipio'))),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().registro(
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            telefono: _telefono.text.trim(),
            correo: _correo.text.trim().isEmpty ? null : _correo.text.trim(),
            password: _password.text,
            genero: _genero,
            municipioID: _municipioSeleccionado!.municipioID,
            direccionExacta: _direccionExacta.text.trim(),
            esProductora: _esProductora,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException
                ? e.mensaje
                : languageProvider.translate('login_error')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.translate('register_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(
                etiqueta: languageProvider.translate('register_names'),
                controller: _nombres,
                validador: (v) => (v == null || v.trim().isEmpty)
                    ? '${languageProvider.translate('register_names')} es requerido'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                etiqueta: languageProvider.translate('register_lastnames'),
                controller: _apellidos,
                validador: (v) => (v == null || v.trim().isEmpty)
                    ? '${languageProvider.translate('register_lastnames')} es requerido'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                etiqueta: languageProvider.translate('register_phone'),
                controller: _telefono,
                tipoTeclado: TextInputType.phone,
                validador: (v) => (v == null || v.trim().isEmpty)
                    ? '${languageProvider.translate('register_phone')} es requerido'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                etiqueta: languageProvider.translate('register_email_optional'),
                controller: _correo,
                tipoTeclado: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppTextField(
                etiqueta: languageProvider.translate('register_password'),
                controller: _password,
                esPassword: true,
                validador: (v) => (v == null || v.length < 6)
                    ? languageProvider.translate('validation_min_length')
                    : null,
              ),
              const SizedBox(height: 14),
              if (_cargandoCatalogos)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(color: AppColors.verdeMilpa),
                )
              else ...[
                // Dropdown 1: Departamento
                DropdownButtonFormField<Departamento>(
                  initialValue: _departamentoSeleccionado,
                  isExpanded: true,
                  menuMaxHeight: 220,
                  decoration: InputDecoration(
                      labelText:
                          languageProvider.translate('register_department')),
                  items: _departamentos
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d.nombre)))
                      .toList(),
                  onChanged: _onDepartamentoChanged,
                  validator: (v) => v == null
                      ? languageProvider.translate('register_select_department')
                      : null,
                ),
                const SizedBox(height: 14),

                // Dropdown 2: Municipio (en cascada)
                DropdownButtonFormField<Municipio>(
                  initialValue: _municipioSeleccionado,
                  isExpanded: true,
                  menuMaxHeight: 220,
                  decoration: InputDecoration(
                      labelText:
                          languageProvider.translate('register_municipality')),
                  items: _municipiosDisponibles
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m.nombre)))
                      .toList(),
                  onChanged: _departamentoSeleccionado == null
                      ? null
                      : (v) => setState(() => _municipioSeleccionado = v),
                  validator: (v) => v == null
                      ? languageProvider.translate('register_select_municipio')
                      : null,
                ),
                const SizedBox(height: 14),

                // Dirección Exacta
                AppTextField(
                  etiqueta:
                      languageProvider.translate('register_exact_address'),
                  controller: _direccionExacta,
                  validador: (v) => (v == null || v.trim().isEmpty)
                      ? '${languageProvider.translate('register_exact_address')} es requerido'
                      : null,
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 14),
              Text(languageProvider.translate('register_gender'),
                  style: AppTextStyles.etiqueta),
              Row(
                children: [
                  ChoiceChip(
                      label:
                          Text(languageProvider.translate('register_female')),
                      selected: _genero == 'F',
                      onSelected: (_) => setState(() => _genero = 'F')),
                  const SizedBox(width: 8),
                  ChoiceChip(
                      label: Text(languageProvider.translate('register_male')),
                      selected: _genero == 'M',
                      onSelected: (_) => setState(() => _genero = 'M')),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _esProductora,
                onChanged: (v) => setState(() => _esProductora = v),
                activeThumbColor: AppColors.verdeMilpa,
                title:
                    Text(languageProvider.translate('register_publish_swap')),
                subtitle: Text(languageProvider
                    .translate('register_publish_swap_subtitle')),
              ),
              const SizedBox(height: 24),
              AppButton(
                  texto: languageProvider.translate('register_create_account'),
                  onPressed: _registrar,
                  cargando: _cargando),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
