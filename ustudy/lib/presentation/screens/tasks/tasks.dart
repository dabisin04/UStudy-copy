import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/domain/entities/tareas.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_bloc.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_event.dart';
import 'package:ustudy/presentation/blocs/tasks/tasks_state.dart';
import 'package:ustudy/presentation/screens/tasks/new_task.dart';
import 'package:ustudy/presentation/screens/tasks/task_detail.dart';

class TareasScreen extends StatefulWidget {
  final String usuarioId;

  const TareasScreen({super.key, required this.usuarioId});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen>
    with WidgetsBindingObserver {
  bool _modoBorrado = false;
  Set<String> _tareasSeleccionadas = {};
  bool _yaCargado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print(
      '🎬 [TAREAS SCREEN] Inicializando pantalla de tareas para usuario: ${widget.usuarioId}',
    );
    _cargarYSincronizar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 [TAREAS SCREEN] App resumida, recargando tareas');
      _cargarYSincronizar();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo recargar si ya se ha cargado antes y no está en modo borrado
    if (_yaCargado && !_modoBorrado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🔄 [TAREAS SCREEN] Recargando desde didChangeDependencies');
          _cargarYSincronizar();
        }
      });
    }
  }

  Future<void> _cargarYSincronizar() async {
    print('🔄 [TAREAS SCREEN] Iniciando carga y sincronización');
    _yaCargado = true;
    final bloc = context.read<TareaBloc>();

    // Solo cargar tareas, la sincronización se hará automáticamente
    bloc.add(CargarTareas(widget.usuarioId));
  }

  void _irAPantallaNuevaTarea() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NuevaTareaScreen(usuarioId: widget.usuarioId),
      ),
    );
    // Recargar tareas cuando se vuelve de crear una nueva
    _cargarYSincronizar();
  }

  void _irAPantallaDetallesTarea(Tarea tarea) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleTareaScreen(tarea: tarea)),
    );
    // Recargar tareas cuando se vuelve de ver/editar una tarea
    _cargarYSincronizar();
  }

  void _activarModoBorrado() {
    setState(() {
      _modoBorrado = true;
      _tareasSeleccionadas.clear();
    });
  }

  void _desactivarModoBorrado() {
    setState(() {
      _modoBorrado = false;
      _tareasSeleccionadas.clear();
    });
  }

  void _toggleSeleccionTarea(String tareaId) {
    setState(() {
      if (_tareasSeleccionadas.contains(tareaId)) {
        _tareasSeleccionadas.remove(tareaId);
      } else {
        _tareasSeleccionadas.add(tareaId);
      }
    });
  }

  void _borrarTareasSeleccionadas() {
    if (_tareasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una tarea para borrar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar borrado'),
        content: Text(
          '¿Estás seguro de que quieres borrar ${_tareasSeleccionadas.length} tarea${_tareasSeleccionadas.length > 1 ? 's' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Eliminar todas las tareas seleccionadas
              final bloc = context.read<TareaBloc>();
              for (String tareaId in _tareasSeleccionadas) {
                bloc.add(EliminarTarea(tareaId));
              }

              // Esperar un poco para que se procesen las eliminaciones
              await Future.delayed(const Duration(milliseconds: 500));

              // Recargar tareas una sola vez
              bloc.add(CargarTareas(widget.usuarioId));

              _desactivarModoBorrado();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${_tareasSeleccionadas.length} tarea${_tareasSeleccionadas.length > 1 ? 's' : ''} borrada${_tareasSeleccionadas.length > 1 ? 's' : ''}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  void _marcarTareasCompletadas(bool completada) {
    if (_tareasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una tarea'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bloc = context.read<TareaBloc>();
    for (String tareaId in _tareasSeleccionadas) {
      bloc.add(CompletarTarea(tareaId, completada: completada));
    }

    _desactivarModoBorrado();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_tareasSeleccionadas.length} tarea${_tareasSeleccionadas.length > 1 ? 's' : ''} marcada${_tareasSeleccionadas.length > 1 ? 's' : ''} como ${completada ? 'completada' : 'pendiente'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _modoBorrado
              ? '${_tareasSeleccionadas.length} seleccionada${_tareasSeleccionadas.length != 1 ? 's' : ''}'
              : 'Homeworks',
        ),
        actions: [
          if (_modoBorrado) ...[
            TextButton(
              onPressed: _desactivarModoBorrado,
              child: const Text('Cancelar'),
            ),
            if (_tareasSeleccionadas.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _marcarTareasCompletadas(true),
                tooltip: 'Marcar como completada',
              ),
              IconButton(
                icon: const Icon(Icons.radio_button_unchecked),
                onPressed: () => _marcarTareasCompletadas(false),
                tooltip: 'Marcar como pendiente',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _borrarTareasSeleccionadas,
                tooltip: 'Borrar tareas',
              ),
            ],
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargarYSincronizar,
            ),
          ],
        ],
      ),
      body: BlocBuilder<TareaBloc, TareaState>(
        builder: (context, state) {
          print('🎨 [TAREAS SCREEN] Estado actual: ${state.runtimeType}');
          print('🎨 [TAREAS SCREEN] Estado completo: $state');

          if (state is TareaCargando) {
            print('⏳ [TAREAS SCREEN] Mostrando indicador de carga');
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TareaError) {
            print('❌ [TAREAS SCREEN] Error: ${state.mensaje}');
            return Center(child: Text(state.mensaje));
          }
          if (state is TareasCargadas) {
            print('✅ [TAREAS SCREEN] Mostrando ${state.tareas.length} tareas');
            print(
              '✅ [TAREAS SCREEN] Tareas: ${state.tareas.map((t) => t.titulo).toList()}',
            );

            return Column(
              children: [
                // Botón de agregar tarea
                if (!_modoBorrado)
                  InkWell(
                    onTap: _irAPantallaNuevaTarea,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'Add a Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Divider
                if (!_modoBorrado) const Divider(),

                // Contenido principal
                Expanded(
                  child: state.tareas.isEmpty
                      ? const Center(child: Text('No tasks yet.'))
                      : ListView.builder(
                          itemCount: state.tareas.length,
                          itemBuilder: (context, index) {
                            // Ordenar tareas por prioridad: alta -> media -> baja
                            final tareasOrdenadas = List<Tarea>.from(
                              state.tareas,
                            );
                            tareasOrdenadas.sort((a, b) {
                              final prioridadA = _getPrioridadValue(
                                a.prioridad,
                              );
                              final prioridadB = _getPrioridadValue(
                                b.prioridad,
                              );
                              return prioridadA.compareTo(prioridadB);
                            });

                            final tarea = tareasOrdenadas[index];
                            print(
                              '🔧 [TAREAS SCREEN] Construyendo tarea $index: ${tarea.titulo}',
                            );

                            return GestureDetector(
                              onLongPress: () {
                                if (!_modoBorrado) {
                                  _activarModoBorrado();
                                  _toggleSeleccionTarea(tarea.id);
                                }
                              },
                              onTap: () {
                                if (_modoBorrado) {
                                  _toggleSeleccionTarea(tarea.id);
                                } else {
                                  _irAPantallaDetallesTarea(tarea);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _modoBorrado &&
                                          _tareasSeleccionadas.contains(
                                            tarea.id,
                                          )
                                      ? Colors.grey.withOpacity(0.4)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.05),
                                      spreadRadius: 0,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    if (_modoBorrado)
                                      Checkbox(
                                        value: _tareasSeleccionadas.contains(
                                          tarea.id,
                                        ),
                                        onChanged: (value) =>
                                            _toggleSeleccionTarea(tarea.id),
                                      ),
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tarea.titulo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (tarea.descripcion != null &&
                                              tarea.descripcion!.isNotEmpty)
                                            Text(
                                              tarea.descripcion!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _getTiempoTranscurrido(
                                            tarea.lastModified,
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tarea.completada
                                              ? 'Completada'
                                              : 'En proceso',
                                          style: TextStyle(
                                            color: tarea.completada
                                                ? Colors.green
                                                : Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          if (state is TareasSincronizadas) {
            print(
              '🔄 [TAREAS SCREEN] Tareas sincronizadas: ${state.nuevasTareas.length}',
            );
            // Recargar tareas después de sincronización
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<TareaBloc>().add(CargarTareas(widget.usuarioId));
            });
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TareaSincronizacionCompletada) {
            print('✅ [TAREAS SCREEN] Sincronización completada');
            // Recargar tareas después de sincronización
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<TareaBloc>().add(CargarTareas(widget.usuarioId));
            });
            return const Center(child: CircularProgressIndicator());
          }
          print('❓ [TAREAS SCREEN] Estado no manejado: ${state.runtimeType}');
          return const Center(child: Text('Estado no manejado'));
        },
      ),
    );
  }
}

Color _getPrioridadColor(String prioridad) {
  switch (prioridad) {
    case 'alta':
      return Colors.red;
    case 'media':
      return Colors.orange;
    case 'baja':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String _getTiempoTranscurrido(String lastModified) {
  final fechaCreacion = DateTime.parse(lastModified);
  final now = DateTime.now();
  final difference = now.difference(fechaCreacion);

  if (difference.inDays > 0) {
    if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays == 0) {
      return 'Hoy';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  } else if (difference.inHours > 0) {
    return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
  } else if (difference.inMinutes > 0) {
    return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
  } else {
    return 'Hace unos segundos';
  }
}

String _getPrioridadValue(String prioridad) {
  switch (prioridad) {
    case 'alta':
      return 'a';
    case 'media':
      return 'm';
    case 'baja':
      return 'b';
    default:
      return 'z';
  }
}
