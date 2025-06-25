import 'package:flutter/material.dart';

class PreguntaFormularioWidget extends StatelessWidget {
  final String pregunta;
  final int index;
  final int total;
  final int? respuestaSeleccionada;
  final Function(int) onRespuestaSeleccionada;

  const PreguntaFormularioWidget({
    super.key,
    required this.pregunta,
    required this.index,
    required this.total,
    required this.respuestaSeleccionada,
    required this.onRespuestaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    final opciones = ["Nunca", "A veces", "Frecuentemente", "Siempre"];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pregunta ${index + 1} de $total',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Text(
          pregunta,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        for (int i = 0; i < opciones.length; i++)
          RadioListTile<int>(
            title: Text(opciones[i]),
            value: i,
            groupValue: respuestaSeleccionada,
            onChanged: (val) => onRespuestaSeleccionada(val!),
          ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: (index + 1) / total,
          minHeight: 6,
        ),
      ],
    );
  }
}
