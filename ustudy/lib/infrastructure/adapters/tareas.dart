import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ustudy/core/constants/api.dart';
import 'package:ustudy/domain/entities/tareas.dart';
import 'package:ustudy/domain/repositories/tareas.dart';
import 'package:ustudy/core/services/sqflite.dart';

class TareaRepositoryImpl implements TareaRepository {
  final Duration _timeout = const Duration(seconds: 5);

  @override
  Future<List<Tarea>> getTareas(String usuarioId) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.tareas}/$usuarioId'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Tarea.fromMap(e)).toList();
      }
    } catch (_) {}
    return getTareasLocal(usuarioId);
  }

  @override
  Future<List<Tarea>> getTareasLocal(String usuarioLocalId) async {
    final db = await SQLiteService.instance;
    final result = await db.query(
      'tareas',
      where: 'usuario_local_id = ?',
      whereArgs: [usuarioLocalId],
    );
    return result.map((e) => Tarea.fromMap(e)).toList();
  }

  @override
  Future<Tarea?> getTareaById(String tareaId) async {
    final db = await SQLiteService.instance;
    final result = await db.query(
      'tareas',
      where: 'id = ?',
      whereArgs: [tareaId],
      limit: 1,
    );
    if (result.isNotEmpty) return Tarea.fromMap(result.first);
    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.tareas}/$tareaId'))
          .timeout(_timeout);
      if (res.statusCode == 200) return Tarea.fromMap(jsonDecode(res.body));
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Tarea>> filtrarTareas(
    String usuarioId, {
    String? prioridad,
    String? origen,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.tareas}/$usuarioId/filtrar')
          .replace(
            queryParameters: {
              if (prioridad != null) 'prioridad': prioridad,
              if (origen != null) 'origen': origen,
            },
          );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Tarea.fromMap(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<Tarea>> getTareasCompletadas(
    String usuarioId, {
    bool completadas = true,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.tareas}/$usuarioId/completadas?completadas=$completadas',
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Tarea.fromMap(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> addTarea(Tarea tarea) async {
    final db = await SQLiteService.instance;
    await db.insert('tareas', tarea.toMap());

    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.tareas),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(tarea.toMap()),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        await db.update(
          'tareas',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [tarea.id],
        );
      }
    } catch (_) {
      await db.update(
        'tareas',
        {'sync_status': 'pending'},
        where: 'id = ?',
        whereArgs: [tarea.id],
      );
    }
  }

  @override
  Future<void> updateTarea(
    String id,
    Map<String, dynamic> camposActualizados,
  ) async {
    final db = await SQLiteService.instance;
    camposActualizados['sync_status'] = 'pending';
    await db.update(
      'tareas',
      camposActualizados,
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      await http
          .patch(
            Uri.parse('${ApiConstants.tareas}/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(camposActualizados),
          )
          .timeout(_timeout);

      await db.update(
        'tareas',
        {'sync_status': 'synced'},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
  }

  @override
  Future<void> completarTarea(String id, {bool completada = true}) async {
    await updateTarea(id, {'completado': completada ? 1 : 0});
  }

  @override
  Future<void> deleteTarea(String id) async {
    final db = await SQLiteService.instance;
    await db.delete('tareas', where: 'id = ?', whereArgs: [id]);
    try {
      await http
          .delete(Uri.parse('${ApiConstants.tareas}/$id'))
          .timeout(_timeout);
    } catch (_) {}
  }

  @override
  Future<void> syncWithServer() async {
    final db = await SQLiteService.instance;
    final result = await db.query(
      'tareas',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );

    if (result.isEmpty) return;

    final tareas = result.map((e) => Tarea.fromMap(e).toMap()).toList();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.tareas}/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(tareas),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        for (var t in tareas) {
          await db.update(
            'tareas',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [t['id']],
          );
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> clearLocalData() async {
    final db = await SQLiteService.instance;
    await db.delete('tareas');
  }
}
