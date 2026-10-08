# Feriando — Aplicación móvil

Feriando es una aplicación móvil para explorar productos y coordinar intercambios entre personas. Desde la app, los usuarios pueden crear una cuenta, iniciar sesión, consultar el catálogo, publicar productos, proponer trueques, revisar notificaciones y conversar mediante el chat.

Este repositorio contiene el cliente móvil desarrollado con Flutter. Para obtener y guardar los datos, se conecta al backend Feriando API, que administra las cuentas y persiste la información en SQL Server.

## Tecnologías

- **Flutter y Dart:** interfaz y ejecución de la aplicación móvil.
- **Provider:** estado compartido entre pantallas y funcionalidades.
- **HTTP:** comunicación REST con el backend.
- **SignalR:** conexión en tiempo real para el chat.
- **Shared Preferences:** almacenamiento local de preferencias y datos de sesión.
- **Image Picker:** selección de imágenes de productos desde el dispositivo.
- **Flutter Localizations e Intl:** soporte de localización y formato de datos.
- **Google Fonts:** tipografía de la interfaz.

Las dependencias y sus versiones se encuentran declaradas en `pubspec.yaml`; `pubspec.lock` registra las versiones resueltas para este proyecto.

## Organización del código

| Ruta | Contenido |
| --- | --- |
| `lib/main.dart` | Inicializa la aplicación, tema, localización y providers globales. |
| `lib/screens/` | Pantallas agrupadas por función: autenticación, catálogo, productos, trueques, chat, notificaciones y perfil. |
| `lib/services/` | Comunicación con la API y operaciones de sesión, catálogo, productos, trueques, notificaciones y chat. |
| `lib/api/` | Rutas y utilidades relacionadas con la API. |
| `lib/models/` | Modelos Dart que representan usuarios, productos, trueques, mensajes y catálogos. |
| `lib/providers/` | Estado que las pantallas comparten, como autenticación, productos, trueques, idioma y chat. |
| `lib/widgets/` | Componentes reutilizables de interfaz. |
| `lib/theme/` | Colores y estilos visuales. |
| `assets/images/` | Logo e ícono de la aplicación declarados en `pubspec.yaml`. |
| `android/`, `ios/`, `windows/`, `linux/`, `macos/` | Configuración nativa para las plataformas incluidas en el proyecto. |

En general, las pantallas muestran la interfaz y recogen las acciones de la persona; los providers mantienen el estado que necesitan varias pantallas; los servicios preparan las solicitudes y llaman al backend; y los modelos convierten las respuestas JSON en objetos Dart.

## Requisitos

- Flutter instalado, con una versión compatible con Dart `>=3.3.0 <4.0.0` (revisa `flutter --version`).
- Un dispositivo o emulador Android para ejecutar la app en Android. Para compilar y ejecutar en iOS se requiere macOS con Xcode.
- El backend Feriando API en ejecución y accesible desde el dispositivo.

Verifica la instalación y los dispositivos disponibles con:

```bash
flutter doctor
flutter devices
```

## Preparar el proyecto

Desde la carpeta raíz de este repositorio, descarga las dependencias:

```bash
flutter pub get
```

Este comando lee `pubspec.yaml` y prepara los paquetes necesarios. Si cambias dependencias declaradas en ese archivo, vuelve a ejecutarlo.

## Configurar la conexión al backend

La dirección de la API se controla con `API_BASE_URL`. Si no se especifica, el código usa `http://10.114.89.98:5080/api`, una dirección de red local que puede no corresponder con tu computadora. Configura una dirección alcanzable desde el dispositivo y termina la ruta con `/api`.

Ejemplos:

- **Emulador Android:** si el backend corre en la misma computadora, usa `http://10.0.2.2:5080/api`. Android ya transforma una dirección `localhost` o `127.0.0.1` dada para el emulador a `10.0.2.2`.
- **Teléfono Android físico:** usa la IPv4 local de la computadora que ejecuta el backend, por ejemplo `http://192.168.1.25:5080/api`. El teléfono y la computadora deben poder comunicarse en la misma red y el puerto debe estar accesible.
- **iOS Simulator:** normalmente puede usarse `http://localhost:5080/api` cuando el backend corre en la misma Mac.

Pasa el valor al iniciar la aplicación. Por ejemplo, en PowerShell para un teléfono Android:

```powershell
flutter run -d <ID-DEL-DISPOSITIVO> --dart-define=API_BASE_URL=http://192.168.1.25:5080/api
```

En macOS/Linux, el mismo comando puede ejecutarse en una terminal POSIX:

```bash
flutter run -d <ID-DEL-DISPOSITIVO> --dart-define=API_BASE_URL=http://192.168.1.25:5080/api
```

Reemplaza la IP de ejemplo por la dirección real de la computadora. El valor de `--dart-define` se fija al compilar/iniciar la app; si cambia la dirección del backend, reinicia la app con el nuevo valor. El backend debe estar levantado antes de probar operaciones que consultan o envían datos.

## Ejecutar la aplicación

Lista los dispositivos con `flutter devices`, copia el identificador que corresponda y ejecuta:

```bash
flutter run -d <ID-DEL-DISPOSITIVO> --dart-define=API_BASE_URL=http://<HOST-DEL-BACKEND>:5080/api
```

Flutter compila la app para el dispositivo seleccionado, la instala y muestra los registros en la terminal. Para detener la ejecución, presiona `q` o `Ctrl+C` en esa terminal.

Comandos abreviados para seleccionar plataforma:

```bash
flutter run -d android
flutter run -d ios
flutter run -d windows
flutter run -d linux
flutter run -d macos
```

En estos comandos también puedes añadir `--dart-define=API_BASE_URL=...` para definir el backend. La disponibilidad depende del sistema operativo y de los dispositivos configurados. Este repositorio no incluye actualmente una carpeta `web/`, por lo que no se documenta ejecución web.

## Uso de la API y del chat

La app consume endpoints REST del backend y conserva el token de sesión localmente para enviarlo en solicitudes autenticadas. Las imágenes de productos se envían como formularios multipart. El chat usa SignalR y el hub `/chatHub` del backend. Por eso, para probar inicio de sesión, catálogo, publicación, trueques o chat, asegúrate de tener el backend y su base de datos configurados.

## Idioma e imágenes

La interfaz actualmente declara español como idioma disponible. El logo y el ícono usados por la app están en `assets/images/` y registrados bajo `flutter.assets` en `pubspec.yaml`. Si agregas recursos, decláralos allí para que Flutter los incluya en el paquete.

## Solución de problemas

- **La app no conecta con la API:** comprueba que el backend esté activo, que `API_BASE_URL` tenga el host y puerto correctos y que sea accesible desde el dispositivo. En un teléfono físico, `localhost` apunta al propio teléfono, no a la computadora.
- **El emulador Android no llega al backend local:** usa `10.0.2.2` como host en lugar de `localhost`.
- **Cambiaste la dirección de la API y sigue usando la anterior:** detén y vuelve a iniciar la app con el nuevo `--dart-define`.
- **Falla la preparación o compilación:** ejecuta `flutter doctor` y revisa los requisitos de la plataforma que estás compilando.
