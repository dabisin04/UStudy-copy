import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/domain/entities/tareas.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_bloc.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_event.dart';
import 'package:uuid/uuid.dart';

class NuevaTareaScreen extends StatefulWidget {
  final String usuarioId;
  const NuevaTareaScreen({super.key, required this.usuarioId});

  @override
  State<NuevaTareaScreen> createState() => _NuevaTareaScreenState();
}

class _NuevaTareaScreenState extends State<NuevaTareaScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  void _guardarTarea() {
    print('💾 [NUEVA TAREA] Guardando nueva tarea');
    print('💾 [NUEVA TAREA] Título: ${_tituloController.text}');
    print('💾 [NUEVA TAREA] Descripción: ${_descripcionController.text}');

    final tarea = Tarea(
      id: Uuid().v4(),
      usuarioLocalId: widget.usuarioId,
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      completada: false,
      lastModified: DateTime.now().toIso8601String(),
      syncStatus: 'pending',
      prioridad: 'media',
      fechaRecordatorio: null,
      origen: 'usuario',
    );

    print('💾 [NUEVA TAREA] Tarea creada: ${tarea.toMap()}');
    context.read<TareaBloc>().add(AgregarTarea(tarea));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('HomeWork'),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
              decoration: const InputDecoration(
                hintText: 'Add a Title ...',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.black12, height: 1, thickness: 1),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _descripcionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Type a description ...',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarTarea,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Save Task'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
