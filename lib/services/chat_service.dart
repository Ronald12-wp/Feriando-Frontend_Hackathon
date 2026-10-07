import 'package:signalr_netcore/signalr_client.dart';
import '../models/conversacion_chat.dart';
import '../models/mensaje_chat.dart';
import 'api_client.dart';

class ChatService {
  static String get baseUrl => ApiClient.baseUrl;

  static String get hubUrl {
    final apiUri = Uri.parse(baseUrl);
    final apiPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    return apiUri
        .replace(path: apiPath)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  final ApiClient _api = ApiClient();
  late HubConnection _hubConnection;
  bool isConnected = false;

  static String crearChatId({
    required int productoId,
    required int productorId,
    required int otroUsuarioId,
  }) {
    final participantes = [productorId, otroUsuarioId]..sort();
    return 'producto_${productoId}_usuarios_${participantes[0]}_${participantes[1]}';
  }

  Future<List<ConversacionChat>> obtenerConversaciones() async {
    final data = await _api.get('/chat/conversaciones') as List<dynamic>;
    return data
        .map((item) => ConversacionChat.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MensajeChat>> obtenerHistorial(String chatId) async {
    final data = await _api
        .get('/chat/historial/${Uri.encodeComponent(chatId)}') as List<dynamic>;
    return data
        .map((item) => MensajeChat.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarComoLeida(String chatId) async {
    await _api
        .post('/chat/conversaciones/${Uri.encodeComponent(chatId)}/leida', {});
  }

  Future<void> conectarSignalR(
      String chatId, Function(MensajeChat) onNuevoMensaje) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl('$hubUrl/chatHub')
        .withAutomaticReconnect()
        .build();

    _hubConnection.on('RecibirMensaje', (arguments) {
      if (arguments != null && arguments.length >= 3) {
        onNuevoMensaje(
          MensajeChat(
            chatId: chatId,
            emisorId: arguments[0] as int,
            mensaje: arguments[1] as String,
            fechaEnvio: arguments[2] as String,
          ),
        );
      }
    });

    await _hubConnection.start();
    isConnected = true;
    await _hubConnection.invoke('UnirseAChat', args: [chatId]);
  }

  Future<void> enviarMensaje(
      String chatId, int emisorId, String mensaje) async {
    if (isConnected) {
      await _hubConnection
          .invoke('EnviarMensaje', args: [chatId, emisorId, mensaje]);
    }
  }

  Future<void> desconectar(String chatId) async {
    if (isConnected) {
      await _hubConnection.invoke('SalirDeChat', args: [chatId]);
      await _hubConnection.stop();
      isConnected = false;
    }
  }
}
