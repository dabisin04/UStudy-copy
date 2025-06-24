import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/presentation/blocs/usuario_bloc.dart';
import 'package:ustudy/presentation/blocs/usuario_event.dart';
import 'package:ustudy/presentation/blocs/usuario_state.dart';

class UniversitySelectionScreen extends StatefulWidget {
  final String localId; // requerido para actualizar uId

  const UniversitySelectionScreen({Key? key, required this.localId})
    : super(key: key);

  @override
  State<UniversitySelectionScreen> createState() =>
      _UniversitySelectionScreenState();
}

class _UniversitySelectionScreenState extends State<UniversitySelectionScreen> {
  List<Map<String, dynamic>> universidades = [];
  String? selectedUniversityId;

  @override
  void initState() {
    super.initState();
    loadUniversidades();
  }

  Future<void> loadUniversidades() async {
    final String response = await rootBundle.loadString(
      'assets/data/unis.json',
    );
    final data = jsonDecode(response) as List;
    setState(() {
      universidades = data.cast<Map<String, dynamic>>();
    });
  }

  void _submit() {
    if (selectedUniversityId != null) {
      context.read<UsuarioBloc>().add(
        UpdateUIdRequested(localId: widget.localId, uId: selectedUniversityId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Selecciona tu universidad'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocConsumer<UsuarioBloc, UsuarioState>(
          listener: (context, state) {
            if (state is UsuarioUpdated) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (state is UsuarioError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (universidades.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Universidad',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedUniversityId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                  ),
                  items: universidades.map((u) {
                    return DropdownMenuItem<String>(
                      value: u['id'],
                      child: Text(
                        u['nombre'],
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedUniversityId = value);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selectedUniversityId == null ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: state is UsuarioLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text('Continuar'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text(
                    'Omitir por ahora',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
