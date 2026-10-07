import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _telefono.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context
          .read<AuthProvider>()
          .login(_telefono.text.trim(), _password.text);
    } catch (e) {
      if (mounted) {
        final languageProvider = context.read<LanguageProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e is ApiException
                  ? e.mensaje
                  : languageProvider.translate('login_error'))),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 48),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Bienvendido',
                    style:
                        AppTextStyles.h1.copyWith(color: AppColors.cafeTierra),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  languageProvider.translate('login_subtitle'),
                  style: AppTextStyles.cuerpo
                      .copyWith(color: AppColors.textoSecundario),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AppTextField(
                  etiqueta: languageProvider.translate('login_phone'),
                  controller: _telefono,
                  tipoTeclado: TextInputType.phone,
                  icono: Icons.phone_outlined,
                  validador: (v) => (v == null || v.trim().isEmpty)
                      ? languageProvider.translate('login_phone')
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  etiqueta: languageProvider.translate('login_password'),
                  controller: _password,
                  esPassword: true,
                  icono: Icons.lock_outline,
                  validador: (v) => (v == null || v.length < 6)
                      ? languageProvider.translate('validation_min_length')
                      : null,
                ),
                const SizedBox(height: 24),
                AppButton(
                  texto: languageProvider.translate('login_button'),
                  onPressed: _iniciarSesion,
                  cargando: _cargando,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistroScreen()),
                  ),
                  child: Text(
                    languageProvider.translate('login_no_account'),
                    style: AppTextStyles.cuerpoDestacado
                        .copyWith(color: AppColors.verdeMilpa),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
