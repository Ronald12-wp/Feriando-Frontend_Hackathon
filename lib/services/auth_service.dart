import 'dart:io';

import '../models/usuario.dart';
import 'api_client.dart';
import 'session_service.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<Usuario> registro({
    required String nombres,
    required String apellidos,
    required String telefono,
    String? correo,
    required String password,
    String? genero,
    required int municipioID, // <--- Actualizado
    required String direccionExacta, // <--- Agregado
    int? idiomaPreferidoID,
    bool esProductora = true,
  }) async {
    final data = await _api.post('/auth/registro', {
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'correo': correo,
      'password': password,
      'genero': genero,
      'municipioID': municipioID, // <--- Actualizado
      'direccionExacta': direccionExacta, // <--- Agregado
      'idiomaPreferidoID': idiomaPreferidoID,
      'esProductora': esProductora,
    }, conAuth: false);

    final usuario = Usuario.fromJson(data['usuario']);
    await SessionService.guardarSesion(data['token'], usuario);
    return usuario;
  }

  Future<Usuario> login({required String telefono, required String password}) async {
    final data = await _api.post('/auth/login', {
      'telefono': telefono,
      'password': password,
    }, conAuth: false);

    final usuario = Usuario.fromJson(data['usuario']);
    await SessionService.guardarSesion(data['token'], usuario);
    return usuario;
  }

  Future<Usuario> actualizarPerfil({
    required String nombres,
    required String apellidos,
    required String telefono,
    String? correo,
    String? genero,
    int? municipioID,
    required String direccionExacta,
    int? idiomaPreferidoID,
    bool? esProductora,
  }) async {
    await _api.put(
      '/usuarios/perfil',
      {
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
        'correo': correo,
        'genero': genero,
        'municipioID': municipioID,
        'direccionExacta': direccionExacta,
        'idiomaPreferidoID': idiomaPreferidoID,
        'esProductora': esProductora,
      },
    );

    return obtenerPerfil();
  }

  Future<Usuario> obtenerPerfil() async {
    final data = await _api.get('/usuarios/perfil');
    final usuario = Usuario.fromJson(data);
    await SessionService.guardarUsuario(usuario);
    return usuario;
  }

  Future<void> actualizarIdiomaPreferido(int idiomaID) async {
    await _api.put(
      '/usuarios/idioma',
      {'idiomaID': idiomaID},
    );
  }

  Future<void> logout() => SessionService.cerrarSesion();

  /// UPDATE — actualizar foto de perfil del usuario
  Future<Usuario> actualizarFotoPerfil(File imagenArchivo) async {
    final fields = <String, String>{};
    final files = [imagenArchivo];
    final data = await _api.putMultipart(
      '/usuarios/fotoPerfil',
      fields: fields,
      files: files,
      fileFieldName: 'fotoPerfil',
    );
    final usuario = Usuario.fromJson(data);
    await SessionService.guardarUsuario(usuario);
    return usuario;
  }
}