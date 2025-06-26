import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_bloc.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_event.dart';
import 'package:ustudy/presentation/blocs/estado_psicologico/estado_psicologico_state.dart';
import 'package:ustudy/presentation/widgets/formulario/pregunta_formulario.dart';
import 'package:ustudy/infrastructure/utils/session.dart';

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
      int pendiente = 0;
      for (int i = 0; i < preguntas.length; i++) {
        if (respuestas[i] == null || respuestas[i] == -1) {
          pendiente = i;
          break;
        }
      }

      setState(() {
        preguntaActual = pendiente;
      });
    } else {
      setState(() {
        preguntaActual = 0;
      });
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
      // Verificar que todas las preguntas estén respondidas
      bool todasRespondidas = true;
      for (int i = 0; i < preguntas.length; i++) {
        if (respuestas[i] == null || respuestas[i] == -1) {
          todasRespondidas = false;
          break;
        }
      }

      if (!todasRespondidas) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor responde todas las preguntas'),
          ),
        );
        return;
      }

      // Obtener el usuario_id usando SessionService
      final session = await SessionService.getUserSession();
      final usuarioId = session?['remoteId'];

      if (usuarioId == null || usuarioId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario no encontrado. Por favor, inicia sesión nuevamente.',
            ),
          ),
        );
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

    // Validar que preguntaActual esté dentro del rango válido
    if (preguntaActual >= preguntas.length) {
      preguntaActual = 0;
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
