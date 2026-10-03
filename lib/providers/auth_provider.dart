import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

enum EstadoSesion { cargando, autenticada, invitada }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  EstadoSesion estado = EstadoSesion.cargando;
  Usuario? usuario;

  Future<void> cargarSesionGuardada() async {
    final token = await SessionService.obtenerToken();
    final usuarioGuardado = await SessionService.obtenerUsuario();
    if (token != null && usuarioGuardado != null) {
      usuario = usuarioGuardado;
      estado = EstadoSesion.autenticada;
    } else {
      estado = EstadoSesion.invitada;
    }
    notifyListeners();
  }

  Future<void> login(String telefono, String password) async {
    usuario = await _authService.login(telefono: telefono, password: password);
    estado = EstadoSesion.autenticada;
    notifyListeners();
  }

  Future<void> registro({
    required String nombres,
    required String apellidos,
    required String telefono,
    String? correo,
    required String password,
    String? genero,
    required int municipioID, // <--- Actualizado de comunidadID
    required String direccionExacta, // <--- Agregado
    int? idiomaPreferidoID, // <--- Agregado
    bool esProductora = true,
  }) async {
    usuario = await _authService.registro(
      nombres: nombres,
      apellidos: apellidos,
      telefono: telefono,
      correo: correo,
      password: password,
      genero: genero,
      municipioID: municipioID, // <--- Actualizado
      direccionExacta: direccionExacta,
      idiomaPreferidoID: idiomaPreferidoID,
      esProductora: esProductora,
    );
    estado = EstadoSesion.autenticada;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    usuario = null;
    estado = EstadoSesion.invitada;
    notifyListeners();
  }

  Future<void> actualizarPerfil({
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
    usuario = await _authService.actualizarPerfil(
      nombres: nombres,
      apellidos: apellidos,
      telefono: telefono,
      correo: correo,
      genero: genero,
      municipioID: municipioID,
      direccionExacta: direccionExacta,
      idiomaPreferidoID: idiomaPreferidoID,
      esProductora: esProductora,
    );
    notifyListeners();
  }

  /// Actualizar la foto de perfil del usuario
  Future<void> actualizarFotoPerfil(String rutaImagen) async {
    final archivo = File(rutaImagen);
    usuario = await _authService.actualizarFotoPerfil(archivo);
    notifyListeners();
  }
}