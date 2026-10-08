import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/perfil/idioma_selector_screen.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _cargandoFoto = false;

  Future<void> _cambiarFoto() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen != null) {
      setState(() => _cargandoFoto = true);
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final languageProvider = context.read<LanguageProvider>();
      try {
        await authProvider.actualizarFotoPerfil(imagen.path);
        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content:
                  Text(languageProvider.translate('profile_photo_updated'))),
        );
      } catch (e) {
        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content:
                  Text('${languageProvider.translate('profile_error')}$e')),
        );
      } finally {
        if (mounted) setState(() => _cargandoFoto = false);
      }
    }
  }

  /// Formatea la URL devuelta por la API para convertir rutas relativas a absolutas
  String? _obtenerUrlFotoPerfil(String? fotoPerfil) {
    if (fotoPerfil == null || fotoPerfil.isEmpty) return null;
    if (fotoPerfil.startsWith('http://') || fotoPerfil.startsWith('https://')) {
      return fotoPerfil;
    }
    final hostBase = ApiClient.baseUrl.replaceAll('/api', '');
    return '$hostBase$fotoPerfil';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final languageProvider = context.watch<LanguageProvider>();

    String ubicacionGeografica = '';
    if (usuario?.municipio != null && usuario?.departamento != null) {
      ubicacionGeografica = '${usuario!.municipio}, ${usuario.departamento}';
    } else if (usuario?.departamento != null) {
      ubicacionGeografica = usuario!.departamento!;
    }

    final urlFoto = _obtenerUrlFotoPerfil(usuario?.fotoPerfil);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              context.watch<LanguageProvider>().translate('profile_title'))),
      body: usuario == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          urlFoto != null
                              ? CircleAvatar(
                                  radius: 44,
                                  backgroundImage: NetworkImage(urlFoto),
                                  onBackgroundImageError: (_, __) {
                                    // Maneja silenciosamente errores si la URL no responde
                                  },
                                )
                              : CircleAvatar(
                                  radius: 44,
                                  backgroundColor: AppColors.verdeMilpa,
                                  child: Text(
                                    usuario.iniciales,
                                    style: AppTextStyles.h1
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _cargandoFoto ? null : _cambiarFoto,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.verdeMilpa,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: _cargandoFoto
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(usuario.nombreCompleto, style: AppTextStyles.h2),
                      if (ubicacionGeografica.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textoSecundario,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ubicacionGeografica,
                              style: AppTextStyles.cuerpo
                                  .copyWith(color: AppColors.textoSecundario),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.achiote, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            usuario.promedioValoracion.toStringAsFixed(1),
                            style: AppTextStyles.cuerpoDestacado,
                          ),
                          Text(
                              '${usuario.promedioValoracion.toStringAsFixed(1)}${languageProvider.translate('profile_trust')}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _filaInfo(
                    Icons.phone_outlined,
                    languageProvider.translate('profile_phone'),
                    usuario.telefono),
                if (usuario.cedula != null && usuario.cedula!.isNotEmpty)
                  _filaInfo(Icons.badge_outlined,
                      languageProvider.translate('profile_cedula'), usuario.cedula!),
                if (usuario.correo != null && usuario.correo!.isNotEmpty)
                  _filaInfo(
                      Icons.mail_outline,
                      languageProvider.translate('profile_email'),
                      usuario.correo!),
                if (usuario.genero != null && usuario.genero!.isNotEmpty)
                  _filaInfo(
                    Icons.person_outline,
                    languageProvider.translate('profile_gender'),
                    usuario.genero == 'F'
                        ? languageProvider.translate('register_female')
                        : usuario.genero == 'M'
                            ? languageProvider.translate('register_male')
                            : languageProvider
                                .translate('profile_gender_other'),
                  ),
                if (usuario.departamento != null)
                  _filaInfo(
                      Icons.map_outlined,
                      languageProvider.translate('profile_department'),
                      usuario.departamento!),
                if (usuario.municipio != null)
                  _filaInfo(
                      Icons.location_city_outlined,
                      languageProvider.translate('profile_municipality'),
                      usuario.municipio!),
                if (usuario.direccionExacta != null &&
                    usuario.direccionExacta!.isNotEmpty)
                  _filaInfo(
                    Icons.home_outlined,
                    languageProvider.translate('register_exact_address'),
                    usuario.direccionExacta!,
                  ),
                if (usuario.idiomaPreferidoID != null)
                  _filaInfo(
                    Icons.language,
                    languageProvider.translate('profile_language'),
                    LanguageProvider.supportedLanguages
                            .where((idioma) =>
                                idioma.idiomaID == usuario.idiomaPreferidoID)
                            .firstOrNull
                            ?.nombre ??
                        languageProvider.selectedLanguage.nombre,
                  ),
                _filaInfo(
                  Icons.storefront_outlined,
                  languageProvider.translate('profile_edit'),
                  usuario.esProductora
                      ? languageProvider.translate('profile_role_productora')
                      : languageProvider.translate('profile_role_compradora'),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarPerfilScreen(usuario: usuario),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: Text(context
                      .watch<LanguageProvider>()
                      .translate('profile_edit')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.verdeMilpa,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IdiomaSelectorScreen()),
                  ),
                  icon: const Icon(Icons.language),
                  label: Text(context
                      .watch<LanguageProvider>()
                      .translate('profile_language')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.verdeMilpa,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: Text(
                      context
                          .watch<LanguageProvider>()
                          .translate('profile_logout'),
                      style: const TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppColors.textoSecundario, size: 20),
          const SizedBox(width: 12),
          Text(etiqueta, style: AppTextStyles.etiqueta),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: AppTextStyles.cuerpoDestacado,
            ),
          ),
        ],
      ),
    );
  }
}
