import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/domain/entities/tareas.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_bloc.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_event.dart';

class DetalleTareaScreen extends StatefulWidget {
  final Tarea tarea;
  const DetalleTareaScreen({super.key, required this.tarea});

  @override
  State<DetalleTareaScreen> createState() => _DetalleTareaScreenState();
}

class _DetalleTareaScreenState extends State<DetalleTareaScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  bool _modoEdicion = false;
  bool _tareaCompletada = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.tarea.titulo);
    _descripcionController = TextEditingController(
      text: widget.tarea.descripcion ?? '',
    );
    _tareaCompletada = widget.tarea.completada;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _toggleModoEdicion() {
    setState(() {
      _modoEdicion = !_modoEdicion;
    });
  }

  void _guardarCambios() {
    if (!_modoEdicion) return;

    final bloc = context.read<TareaBloc>();

    // Actualizar título si cambió
    if (_tituloController.text != widget.tarea.titulo) {
      bloc.add(
        ActualizarTarea(widget.tarea.id, {
          'titulo': _tituloController.text,
          'usuario_local_id': widget.tarea.usuarioLocalId,
        }),
      );
    }

    // Actualizar descripción si cambió
    if (_descripcionController.text != (widget.tarea.descripcion ?? '')) {
      bloc.add(
        ActualizarTarea(widget.tarea.id, {
          'descripcion': _descripcionController.text,
          'usuario_local_id': widget.tarea.usuarioLocalId,
        }),
      );
    }

    // Actualizar estado de completada si cambió
    if (_tareaCompletada != widget.tarea.completada) {
      bloc.add(CompletarTarea(widget.tarea.id, completada: _tareaCompletada));
    }

    setState(() {
      _modoEdicion = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleCompletada() {
    setState(() {
      _tareaCompletada = !_tareaCompletada;
    });
  }

  void _mostrarModalPrioridad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Text(
              'Cambiar Prioridad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Botones de prioridad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildPrioridadButton('alta', 'Alta Prioridad', Colors.red),
                  const SizedBox(height: 12),
                  _buildPrioridadButton(
                    'media',
                    'Media Prioridad',
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildPrioridadButton('baja', 'Baja Prioridad', Colors.green),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioridadButton(String prioridad, String label, Color color) {
    final isSelected = widget.tarea.prioridad == prioridad;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          final bloc = context.read<TareaBloc>();
          bloc.add(
            ActualizarTarea(widget.tarea.id, {
              'prioridad': prioridad,
              'usuario_local_id': widget.tarea.usuarioLocalId,
            }),
          );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Prioridad cambiada a $label'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_modoEdicion ? 'Edit Task' : 'Task Details'),
        actions: [
          if (_modoEdicion) ...[
            TextButton(onPressed: _guardarCambios, child: const Text('Save')),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleModoEdicion,
              tooltip: 'Edit task',
            ),
          ],
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado de completada
            if (!_modoEdicion) ...[
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleCompletada,
                    child: Icon(
                      _tareaCompletada
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _tareaCompletada ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tareaCompletada ? 'Completed' : 'Pending',
                    style: TextStyle(
                      color: _tareaCompletada ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Título
            if (_modoEdicion) ...[
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
            ] else ...[
              Text(
                'Title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tarea.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Descripción
            if (_modoEdicion) ...[
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
            ] else ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  widget.tarea.descripcion ?? 'No description',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Información adicional
              _buildInfoRow(
                'Created',
                DateTime.parse(
                  widget.tarea.lastModified,
                ).toString().split('.')[0],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _mostrarModalPrioridad,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.tarea.prioridad.toUpperCase(),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Botón de guardar (solo en modo edición)
            if (_modoEdicion)
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
