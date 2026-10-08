import '../api/producto_api.dart';
import '../models/producto.dart';

class ProductoService {
  final ProductoApi _api = ProductoApi();

  /// READ — catálogo público con filtros opcionales
  Future<List<Producto>> listar({
    int? categoriaID,
    int? departamentoID,
    int? municipioID,
    String? tipoOferta,
    String? busqueda,
    String estado = 'Disponible',
  }) {
    return _api.listar(
      categoriaID: categoriaID,
      departamentoID: departamentoID,
      municipioID: municipioID,
      tipoOferta: tipoOferta,
      busqueda: busqueda,
      estado: estado,
    );
  }

  /// READ — detalle de un producto
  Future<Producto> obtener(int id) => _api.obtener(id);

  /// READ — productos publicados por la usuaria autenticada
  Future<List<Producto>> mios() => _api.mios();

  /// CREATE
  Future<Producto> crearProducto(ProductoFormulario formulario) => _api.crear(formulario);

  Future<Producto> crear(ProductoFormulario formulario) => crearProducto(formulario);

  /// UPDATE
  Future<void> actualizarProducto(int id, ProductoFormulario formulario) => _api.actualizar(id, formulario);

  Future<void> actualizar(int id, ProductoFormulario formulario) => actualizarProducto(id, formulario);

  /// Solo permite pausar una publicación o volver a publicarla.
  Future<void> cambiarEstado(int id, String nuevoEstado) => _api.cambiarEstado(id, nuevoEstado);

  /// DELETE
  Future<void> eliminar(int id) => _api.eliminar(id);
}
