import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoProvider extends ChangeNotifier {
  final ProductoService _service = ProductoService();

  List<Producto> catalogo = [];
  List<Producto> misProductos = [];
  bool cargando = false;
  String? error;

  // Filtros activos del catálogo
  int? filtroCategoriaID;
  int? filtroDepartamentoID; // <--- Agregado para filtrar por departamento
  int? filtroMunicipioID;    // <--- Agregado para filtrar por municipio
  String? filtroBusqueda;

  Future<void> cargarCatalogo({bool limpiarFiltros = false}) async {
    if (limpiarFiltros) {
      filtroCategoriaID = null;
      filtroDepartamentoID = null;
      filtroMunicipioID = null;
      filtroBusqueda = null;
    }
    cargando = true;
    error = null;
    notifyListeners();
    try {
      catalogo = await _service.listar(
        categoriaID: filtroCategoriaID,
        departamentoID: filtroDepartamentoID, // <--- Pasamos al service
        municipioID: filtroMunicipioID,       // <--- Pasamos al service
        busqueda: filtroBusqueda,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarMios() async {
    cargando = true;
    notifyListeners();
    try {
      misProductos = await _service.mios();
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<Producto> crear(ProductoFormulario formulario) async {
    final creado = await _service.crear(formulario);
    misProductos.insert(0, creado);
    notifyListeners();
    await cargarCatalogo();
    return creado;
  }

  Future<void> actualizar(int id, ProductoFormulario formulario) async {
    await _service.actualizar(id, formulario);
    await Future.wait([
      cargarMios(),
      cargarCatalogo(),
    ]);
  }

  Future<void> eliminar(int id) async {
    await _service.eliminar(id);
    misProductos.removeWhere((p) => p.productoID == id);
    notifyListeners();
    await cargarCatalogo();
  }

  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    await _service.cambiarEstado(id, nuevoEstado);
    await Future.wait([
      cargarMios(),
      cargarCatalogo(),
    ]);
  }
}