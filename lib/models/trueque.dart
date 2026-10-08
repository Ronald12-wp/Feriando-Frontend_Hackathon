class Trueque {
  final int truequeID;
  final String estado; // Pendiente | Aceptado | Rechazado | Completado | Cancelado
  final bool yaValore;
  final int productoOfertadoID;
  final String productoOfertadoNombre;
  final int? productoSolicitadoID;
  final String? productoSolicitadoNombre;
  final int usuarioSolicitanteID;
  final String usuarioSolicitanteNombre;
  final int usuarioReceptorID;
  final String usuarioReceptorNombre;
  final double? montoAdicional;
  final String? lugarEncuentro;
  final DateTime fechaSolicitud;
  final DateTime? fechaRespuesta;
  final DateTime? fechaCompletado;

  Trueque({
    required this.truequeID,
    required this.estado,
    this.yaValore = false,
    required this.productoOfertadoID,
    required this.productoOfertadoNombre,
    this.productoSolicitadoID,
    this.productoSolicitadoNombre,
    required this.usuarioSolicitanteID,
    required this.usuarioSolicitanteNombre,
    required this.usuarioReceptorID,
    required this.usuarioReceptorNombre,
    this.montoAdicional,
    this.lugarEncuentro,
    required this.fechaSolicitud,
    this.fechaRespuesta,
    this.fechaCompletado,
  });

  factory Trueque.fromJson(Map<String, dynamic> json) => Trueque(
        truequeID: json['truequeID'],
        estado: json['estado'] ?? 'Pendiente',
        yaValore: json['yaValore'] == true,
        productoOfertadoID: json['productoOfertadoID'],
        productoOfertadoNombre: json['productoOfertadoNombre'] ?? '',
        productoSolicitadoID: json['productoSolicitadoID'],
        productoSolicitadoNombre: json['productoSolicitadoNombre'],
        usuarioSolicitanteID: json['usuarioSolicitanteID'],
        usuarioSolicitanteNombre: json['usuarioSolicitanteNombre'] ?? '',
        usuarioReceptorID: json['usuarioReceptorID'],
        usuarioReceptorNombre: json['usuarioReceptorNombre'] ?? '',
        montoAdicional: json['montoAdicional']?.toDouble(),
        lugarEncuentro: json['lugarEncuentro'],
        fechaSolicitud: DateTime.tryParse(json['fechaSolicitud'] ?? '') ?? DateTime.now(),
        fechaRespuesta: json['fechaRespuesta'] != null ? DateTime.tryParse(json['fechaRespuesta']) : null,
        fechaCompletado: json['fechaCompletado'] != null ? DateTime.tryParse(json['fechaCompletado']) : null,
      );

  /// true si la usuaria actual es quien debe responder (recibió la solicitud)
  bool esReceptor(int usuarioActualID) => usuarioReceptorID == usuarioActualID;
}

class Notificacion {
  final int notificacionID;
  final String titulo;
  final String mensaje;
  final int? truequeID;
  final bool leido;
  final DateTime fechaCreacion;

  Notificacion({
    required this.notificacionID,
    required this.titulo,
    required this.mensaje,
    this.truequeID,
    required this.leido,
    required this.fechaCreacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        notificacionID: json['notificacionID'],
        titulo: json['titulo'] ?? '',
        mensaje: json['mensaje'] ?? '',
        truequeID: json['truequeID'],
        leido: json['leido'] ?? false,
        fechaCreacion: DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime.now(),
      );
}
