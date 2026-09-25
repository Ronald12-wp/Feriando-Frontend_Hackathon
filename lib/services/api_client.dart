import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'session_service.dart';

/// Excepción de la API con un mensaje listo para mostrar a la usuaria.
class ApiException implements Exception {
  final String mensaje;
  final int? codigo;

  ApiException(this.mensaje, [this.codigo]);

  @override
  String toString() => mensaje;
}

class ApiClient {
  /// Dirección de la API.
  ///
  /// Para usar otra red sin editar código, ejecuta Flutter con:
  /// `--dart-define=API_BASE_URL=http://TU_IP:5080/api`
  /// La IP por defecto corresponde a la red configurada actualmente.
  static String get baseUrl {
    const env = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.100.10:5080/api',
    );
    // Si estamos en un emulador Android y la URL apunta a localhost,
    // reescribimos el host a 10.0.2.2. No debemos cambiar IPs de la LAN
    // porque un dispositivo físico puede acceder a ellas directamente.
    try {
      final uri = Uri.parse(env);
      if (Platform.isAndroid &&
          (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return '${uri.scheme}://10.0.2.2:${uri.port}${uri.path}';
      }
    } catch (_) {
      // Si algo falla, devolvemos la URL tal cual
    }
    if (kDebugMode) {
      try {
        // ignore: avoid_print
        print('[ApiClient] baseUrl resolved to: $env');
      } catch (_) {}
    }
    return env;
  }

  Future<Map<String, String>> _headers(
      {bool conAuth = true, bool multipart = false}) async {
    final headers = <String, String>{};
    if (!multipart) {
      headers['Content-Type'] = 'application/json';
    }

    final idiomaPreferido = await SessionService.obtenerIdiomaPreferidoID();
    if (idiomaPreferido != null) {
      headers['X-Idioma-Id'] = idiomaPreferido.toString();
    } else {
      headers['X-Idioma-Id'] = '1';
    }

    if (conAuth) {
      final token = await SessionService.obtenerToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String ruta) => Uri.parse('$baseUrl$ruta');

  Uri _debugUri(String ruta) {
    final uri = _uri(ruta);
    if (kDebugMode) {
      try {
        // ignore: avoid_print
        print('[ApiClient] Request URI: $uri');
      } catch (_) {}
    }
    return uri;
  }

  Future<dynamic> get(String ruta, {bool conAuth = true}) async {
    try {
      final res = await http.get(_debugUri(ruta),
          headers: await _headers(conAuth: conAuth));
      return _procesar(res);
    } on SocketException {
      throw ApiException(
          'No se pudo conectar a la API. Verifica tu red y que el backend esté activo.');
    } on HttpException {
      throw ApiException('Error HTTP al intentar conectar con la API.');
    }
  }

  Future<dynamic> post(String ruta, Map<String, dynamic> body,
      {bool conAuth = true}) async {
    try {
      final res = await http.post(
        _debugUri(ruta),
        headers: await _headers(conAuth: conAuth),
        body: jsonEncode(body),
      );
      return _procesar(res);
    } on SocketException {
      throw ApiException(
          'No se pudo conectar a la API. Verifica tu red y que el backend esté activo.');
    } on HttpException {
      throw ApiException('Error HTTP al intentar conectar con la API.');
    }
  }

  Future<dynamic> put(String ruta, Map<String, dynamic> body,
      {bool conAuth = true}) async {
    try {
      final res = await http.put(
        _debugUri(ruta),
        headers: await _headers(conAuth: conAuth),
        body: jsonEncode(body),
      );
      return _procesar(res);
    } on SocketException {
      throw ApiException(
          'No se pudo conectar a la API. Verifica tu red y que el backend esté activo.');
    } on HttpException {
      throw ApiException('Error HTTP al intentar conectar con la API.');
    }
  }

  Future<dynamic> postMultipart(
    String ruta, {
    Map<String, String>? fields,
    List<File>? files,
    String fileFieldName = 'imagenes',
    bool conAuth = true,
  }) async {
    try {
      final uri = _debugUri(ruta);
      final request = http.MultipartRequest('POST', uri);
      final requestHeaders = await _headers(conAuth: conAuth, multipart: true);
      request.headers.addAll(requestHeaders);
      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        for (var file in files) {
          final multipartFile =
              await http.MultipartFile.fromPath(fileFieldName, file.path);
          request.files.add(multipartFile);
        }
      }
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      return _procesar(res);
    } on SocketException {
      throw ApiException(
          'No se pudo conectar a la API. Verifica tu red y que el backend esté activo.');
    } on HttpException {
      throw ApiException('Error HTTP al intentar conectar con la API.');
    }
  }

  Future<dynamic> putMultipart(
    String ruta, {
    Map<String, String>? fields,
    List<File>? files,
    String fileFieldName = 'imagenes',
    bool conAuth = true,
  }) async {
    try {
      final uri = _debugUri(ruta);
      final request = http.MultipartRequest('PUT', uri);
      final requestHeaders = await _headers(conAuth: conAuth, multipart: true);
      request.headers.addAll(requestHeaders);
      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        for (var file in files) {
          final multipartFile =
              await http.MultipartFile.fromPath(fileFieldName, file.path);
          request.files.add(multipartFile);
        }
      }
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      return _procesar(res);
    } on SocketException {
      throw ApiException(
          'No se pudo conectar a la API. Verifica tu red y que el backend esté activo.');
    } on HttpException {
      throw ApiException('Error HTTP al intentar conectar con la API.');
    }
  }

  Future<dynamic> delete(String ruta, {bool conAuth = true}) async {
    final res = await http.delete(_debugUri(ruta),
        headers: await _headers(conAuth: conAuth));
    return _procesar(res);
  }

  dynamic _procesar(http.Response res) {
    dynamic cuerpo;
    if (res.bodyBytes.isNotEmpty) {
      try {
        cuerpo = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        cuerpo = null;
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final mensaje = cuerpo is Map && cuerpo['mensaje'] != null
          ? cuerpo['mensaje'].toString()
          : 'Ocurrió un problema (código ${res.statusCode}). Intenta de nuevo.';
      throw ApiException(mensaje, res.statusCode);
    }
    return cuerpo;
  }
}
