import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_bloc.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_event.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_state.dart';
import 'package:ustudy/presentation/widgets/formulario/pregunta_formulario.dart';

class FormularioPsicologicoPage extends StatefulWidget {
  const FormularioPsicologicoPage({super.key});

  @override
  State<FormularioPsicologicoPage> createState() =>
      _FormularioPsicologicoPageState();
}

class _FormularioPsicologicoPageState extends State<FormularioPsicologicoPage> {
  List<Map<String, dynamic>> preguntas = [];
  int preguntaActual = 0;
  Map<int, int> respuestas = {}; // index => valorRespuesta

  @override
  void initState() {
    super.initState();
    cargarFormulario();
  }

  Future<void> cargarFormulario() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/data/preguntas_ia.json');
    final data = json.decode(jsonString) as List;
    preguntas = data.cast<Map<String, dynamic>>();

    final saved = prefs.getString('respuestas_psicologicas');
    if (saved != null) {
      final Map<String, dynamic> respuestaGuardada = json.decode(saved);
      respuestas = {};
      respuestaGuardada.forEach((preguntaTexto, valor) {
        final index = preguntas.indexWhere(
          (q) => q['pregunta'] == preguntaTexto,
        );
        if (index != -1) respuestas[index] = valor;
      });

      // Buscar la siguiente pregunta no respondida
      final pendiente = respuestas.entries
          .firstWhere(
            (e) => e.value == -1,
            orElse: () => MapEntry(respuestas.length, -1),
          )
          .key;

      setState(() {
        preguntaActual = pendiente < preguntas.length
            ? pendiente
            : respuestas.length;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> guardarRespuesta(int index, int valor) async {
    final prefs = await SharedPreferences.getInstance();
    respuestas[index] = valor;

    final respuestaMap = preguntas.asMap().map(
      (i, q) => MapEntry(q['pregunta'], respuestas[i] ?? -1),
    );

    await prefs.setString('respuestas_psicologicas', json.encode(respuestaMap));
  }

  void siguiente() async {
    if (respuestas[preguntaActual] == null) return;

    if (preguntaActual < preguntas.length - 1) {
      setState(() {
        preguntaActual++;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');

      if (usuarioId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
        return;
      }

      final respuestaMap = preguntas.asMap().entries.map((entry) {
        final pregunta = entry.value['pregunta'];
        final valor = respuestas[entry.key] ?? -1;
        return {"pregunta": pregunta, "valor_respuesta": valor};
      }).toList();

      context.read<EstadoPsicologicoBloc>().add(
        EvaluarEstadoEmocional(usuarioId, respuestaMap),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (preguntas.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocListener<EstadoPsicologicoBloc, EstadoPsicologicoState>(
      listener: (context, state) async {
        if (state is EstadoPsicologicoEvaluado) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('respuestas_psicologicas');

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evaluación enviada correctamente')),
          );
          Navigator.pop(context);
        }

        if (state is EstadoPsicologicoError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.mensaje)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Evaluación emocional'),
          actions: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Omitir evaluación'),
                    content: const Text(
                      '¿Estás seguro de que quieres omitir esta evaluación? Puedes realizarla más tarde.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar diálogo
                          Navigator.pop(context); // Volver a pantalla anterior
                        },
                        child: const Text('Omitir'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Omitir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PreguntaFormularioWidget(
            pregunta: preguntas[preguntaActual]['pregunta'],
            index: preguntaActual,
            total: preguntas.length,
            respuestaSeleccionada: respuestas[preguntaActual],
            onRespuestaSeleccionada: (val) {
              guardarRespuesta(preguntaActual, val);
              setState(() {
                respuestas[preguntaActual] = val;
              });
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: siguiente,
          child: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
