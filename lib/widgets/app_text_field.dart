import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String etiqueta;
  final String? pista;
  final TextEditingController controller;
  final bool esPassword;
  final TextInputType tipoTeclado;
  final String? Function(String?)? validador;
  final int maxLineas;
  final IconData? icono;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.pista,
    this.esPassword = false,
    this.tipoTeclado = TextInputType.text,
    this.validador,
    this.maxLineas = 1,
    this.icono,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: esPassword,
      keyboardType: tipoTeclado,
      textCapitalization: textCapitalization,
      maxLines: esPassword ? 1 : maxLineas,
      validator: validador,
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: pista,
        prefixIcon: icono != null ? Icon(icono) : null,
      ),
    );
  }
}
