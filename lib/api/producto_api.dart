import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../models/producto.dart';
import '../services/api_client.dart';

class ProductoApi {
  final ApiClient _api = ApiClient();

  Map<String, String> _formFieldsFromFormulario(ProductoFormulario formulario) {
    final data = <String, dynamic>{
      'Nombre': formulario.nombre,
      'Descripcion': formulario.descripcion,
      'Cantidad': formulario.cantidad,
      'CategoriaID': formulario.categoriaID,
      'UnidadMedidaID': formulario.unidadMedidaID,
      'TipoOferta': formulario.tipoOferta,
      'PrecioReferencial': formulario.precioReferencial,
      'ReemplazarImagenes': formulario.reemplazarImagenes,
    };

    final fields = <String, String>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value != null) {
        fields[entry.key] = value.toString();
      }
    }
    return fields;
  }

  List<File>? _filesFromFormulario(ProductoFormulario formulario) {
    final files = <File>[];

    final xFiles = formulario.imagenesXFiles ?? const <XFile>[];
    for (final xFile in xFiles) {
      if (xFile.path.trim().isNotEmpty) {
        files.add(File(xFile.path));
      }
    }

    final paths = formulario.imagenesArchivos ?? const <String>[];
    for (final path in paths) {
      if (path.trim().isNotEmpty) {
        files.add(File(path));
      }
    }

    if (files.isEmpty) return null;
    return files;
  }

  Future<List<Producto>> listar({
    int? categoriaID,
    int? departamentoID,
    int? municipioID,
    String? tipoOferta,
    String? busqueda,
    String estado = 'Disponible',
  }) async {
    final query = <String, String>{'estado': estado};
    if (categoriaID != null) query['categoriaID'] = '$categoriaID';
    if (departamentoID != null) query['departamentoID'] = '$departamentoID';
    if (municipioID != null) query['municipioID'] = '$municipioID';
    if (tipoOferta != null) query['tipoOferta'] = tipoOferta;
    if (busqueda != null && busqueda.isNotEmpty) query['busqueda'] = busqueda;

    final qs = Uri(queryParameters: query).query;
    final data = await _api.get('/productos?$qs', conAuth: false) as List;
    return data.map((e) => Producto.fromJson(e)).toList();
  }

  Future<Producto> obtener(int id) async {
    final data = await _api.get('/productos/$id', conAuth: false);
    return Producto.fromJson(data);
  }

  Future<List<Producto>> mios() async {
    final data = await _api.get('/productos/mios') as List;
    return data.map((e) => Producto.fromJson(e)).toList();
  }

  Future<Producto> crear(ProductoFormulario formulario) async {
    final data = await _api.postMultipart(
      '/productos',
      fields: _formFieldsFromFormulario(formulario),
      files: _filesFromFormulario(formulario),
      fileFieldName: 'ImagenesArchivos',
    );
    return Producto.fromJson(data);
  }

  Future<void> actualizar(int id, ProductoFormulario formulario) async {
    await _api.putMultipart(
      '/productos/$id',
      fields: _formFieldsFromFormulario(formulario),
      files: _filesFromFormulario(formulario),
      fileFieldName: 'ImagenesArchivos',
    );
  }

  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    await _api.put('/productos/$id/estado', {'estado': nuevoEstado});
  }

  Future<void> eliminar(int id) async {
    await _api.delete('/productos/$id');
  }
}
