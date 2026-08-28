# Feriando

## Descripción técnica

Feriando es una aplicación móvil Flutter para el intercambio digital de productos con un enfoque de género. Permite a los usuarios registrarse, iniciar sesión, publicar productos, navegar catálogos, enviar solicitudes de trueque y gestionar su perfil.

La aplicación está diseñada para ejecutarse en Android, iOS y web usando Flutter, y emplea `provider` para la gestión del estado, `http` para el consumo de APIs y `shared_preferences` para el almacenamiento local de datos de sesión.

## Tecnologías utilizadas

- Flutter
- Dart
- Provider
- HTTP
- Shared Preferences
- Google Fonts
- Intl
- Image Picker
- Flutter Localizations

## Estructura del proyecto

- `lib/main.dart` - punto de entrada de la aplicación.
- `lib/api/` - definición de endpoints y lógica para llamadas HTTP.
- `lib/models/` - modelos de datos como `usuario`, `producto`, `trueque` y `catalogos`.
- `lib/providers/` - estado de la aplicación y lógica de negocio (`auth`, `producto`, `trueque`, `language`).
- `lib/screens/` - interfaces de usuario para autenticación, catálogo, productos, trueques y perfil.
- `lib/theme/` - tema visual de la aplicación.
- `assets/images/` - recursos de imágenes usados en la app.

## Instalación básica

1. Clona el repositorio:

```bash
git clone https://github.com/<usuario>/<repositorio>.git
cd Feriando-Frontend
```

2. Asegúrate de tener instalado Flutter 3.3 o superior y un SDK de Dart compatible.

3. Recupera las dependencias:

```bash
flutter pub get
```

4. Verifica el entorno:

```bash
flutter doctor
```

## Ejecución del sistema

Ejecuta la aplicación en un dispositivo o emulador:

```bash
flutter run
```

Para Android usa:

```bash
flutter run -d android
```

Para iOS (desde macOS) usa:

```bash
flutter run -d ios
```

Para web usa:

```bash
flutter run -d chrome
```

## Notas adicionales

- La app está configurada para español (`Locale('es')`).
- Los assets se cargan desde `assets/images/logo.jpeg`.
- El nombre del paquete en `pubspec.yaml` es `fereando`.
- Si se requiere cambiar el paquete de Android/iOS, usa la herramienta adecuada para renombrar el paquete.

## Contacto

Para problemas con la instalación o ejecución, ejecuta `flutter doctor` y revisa los mensajes de error que aparezcan.
