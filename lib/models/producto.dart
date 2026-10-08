import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';

class Producto {
  final int productoID;
  final String nombre;
  final String? descripcion;
  final double cantidad;
  final String unidadMedida;
  final String categoria;
  final String tipoOferta; // Trueque | Venta | Ambos
  final double? precioReferencial;
  final String estado; // Disponible | Reservado | Intercambiado | Inactivo
  final DateTime fechaPublicacion;
  final List<String> imagenes;
  final int usuarioID;
  final String nombreProductora;
  final String municipio;
  final String departamento;

  String get imagenPrincipalUrl => imagenes.isNotEmpty ? imagenUrl(0) : '';

  String imagenUrl(int index) {
    if (imagenes.isEmpty) return '';
    final raw = imagenes[index];
    return resolverUrl(raw);
  }

  static String resolverUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final apiBase = ApiClient.baseUrl;
    final origin = Uri.parse(apiBase).origin;
    if (url.startsWith('/')) {
      return '$origin$url';
    }
    return '$origin/$url';
  }

  Producto({
    required this.productoID,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    required this.unidadMedida,
    required this.categoria,
    required this.tipoOferta,
    this.precioReferencial,
    required this.estado,
    required this.fechaPublicacion,
    required this.imagenes,
    required this.usuarioID,
    required this.nombreProductora,
    required this.municipio,
    required this.departamento,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        productoID: json['productoID'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        cantidad: (json['cantidad'] ?? 0).toDouble(),
        unidadMedida: json['unidadMedida'] ?? '',
        categoria: json['categoria'] ?? '',
        tipoOferta: json['tipoOferta'] ?? 'Trueque',
        precioReferencial: json['precioReferencial']?.toDouble(),
        estado: json['estado'] ?? 'Disponible',
        fechaPublicacion: DateTime.tryParse(json['fechaPublicacion'] ?? '') ??
            DateTime.now(),
        imagenes: (json['imagenes'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        usuarioID: json['usuarioID'],
        nombreProductora: json['nombreProductora'] ?? '',
        municipio: json['municipio'] ?? '',
        departamento: json['departamento'] ?? '',
      );
}

/// Cuerpo para crear/editar un producto (POST/PUT /api/productos)
class ProductoFormulario {
  int? categoriaID;
  String nombre;
  String? descripcion;
  double cantidad;
  int? unidadMedidaID;
  String tipoOferta;
  double? precioReferencial;
  bool reemplazarImagenes;
  List<String>? urlsImagenes;
  List<String>? imagenesArchivos;
  List<XFile>? imagenesXFiles;

  ProductoFormulario({
    this.categoriaID,
    this.nombre = '',
    this.descripcion,
    this.cantidad = 1,
    this.unidadMedidaID,
    this.tipoOferta = 'Trueque',
    this.precioReferencial,
    this.reemplazarImagenes = false,
    this.urlsImagenes,
    this.imagenesArchivos,
    this.imagenesXFiles,
  });

  Map<String, dynamic> toCreateJson() => {
        'CategoriaID': categoriaID,
        'Nombre': nombre,
        'Descripcion': descripcion,
        'Cantidad': cantidad,
        'UnidadMedidaID': unidadMedidaID,
        'TipoOferta': tipoOferta,
        'PrecioReferencial': precioReferencial,
      };

  Map<String, dynamic> toUpdateJson() => {
        'Nombre': nombre,
        'Descripcion': descripcion,
        'Cantidad': cantidad,
        'TipoOferta': tipoOferta,
        'PrecioReferencial': precioReferencial,
      };
}
