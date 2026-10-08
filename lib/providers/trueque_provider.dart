import 'package:flutter/foundation.dart';
import '../models/trueque.dart';
import '../services/trueque_service.dart';

class TruequeProvider extends ChangeNotifier {
  final TruequeService _service = TruequeService();

  List<Trueque> mios = [];
  bool cargando = false;
  String? error;

  List<Trueque> get pendientesRecibidos =>
      mios.where((t) => t.estado == 'Pendiente').toList();

  Future<void> cargarMios() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      mios = await _service.mios();
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> solicitar({
    required int productoOfertadoID,
    int? productoSolicitadoID,
    double? montoAdicional,
    String? lugarEncuentro,
  }) async {
    final nuevo = await _service.solicitar(
      productoOfertadoID: productoOfertadoID,
      productoSolicitadoID: productoSolicitadoID,
      montoAdicional: montoAdicional,
      lugarEncuentro: lugarEncuentro,
    );
    mios.insert(0, nuevo);
    notifyListeners();
  }

  Future<void> responder(int truequeID, {required bool aceptar, String? lugarEncuentro}) async {
    final actualizado = await _service.responder(truequeID, aceptar: aceptar, lugarEncuentro: lugarEncuentro);
    final idx = mios.indexWhere((t) => t.truequeID == truequeID);
    if (idx != -1) mios[idx] = actualizado;
    notifyListeners();
  }

  Future<void> valorar({required int truequeID, required int puntuacion, String? comentario}) async {
    await _service.valorar(truequeID: truequeID, puntuacion: puntuacion, comentario: comentario);
    await cargarMios();
  }
}
