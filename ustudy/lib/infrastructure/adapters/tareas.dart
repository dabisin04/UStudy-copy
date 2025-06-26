import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ustudy/core/constants/api.dart';
import 'package:ustudy/domain/entities/tareas.dart';
import 'package:ustudy/domain/repositories/tareas.dart';
import 'package:ustudy/core/services/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TareaRepositoryImpl implements TareaRepository {
  final Duration _timeout = const Duration(seconds: 5);

  TareaRepositoryImpl() {
    print('🔧 [TAREAS] Inicializando TareaRepositoryImpl');
    print('🔧 [TAREAS] ApiConstants.tareas: ${ApiConstants.tareas}');
    print('🔧 [TAREAS] ApiConstants.baseUrl: ${ApiConstants.baseUrl}');
  }

  @override
  Future<List<Tarea>> getTareas(String usuarioId) async {
    print('🔍 [TAREAS] Intentando obtener tareas para usuario: $usuarioId');
    try {
      final url = '${ApiConstants.tareas}/usuario/$usuarioId';
      print('🌐 [TAREAS] URL del servidor: $url');

      final res = await http.get(Uri.parse(url)).timeout(_timeout);

      print('📡 [TAREAS] Respuesta del servidor - Status: ${res.statusCode}');
      print('📡 [TAREAS] Respuesta del servidor - Body: ${res.body}');

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        print('✅ [TAREAS] Tareas obtenidas del servidor: ${data.length}');

        final List<Tarea> tareas = [];
        for (int i = 0; i < data.length; i++) {
          try {
            print('🔧 [TAREAS] Procesando tarea $i: ${data[i]}');
            final tarea = Tarea.fromMap(data[i]);
            tareas.add(tarea);
            print('✅ [TAREAS] Tarea $i procesada exitosamente');
          } catch (e) {
            print('💥 [TAREAS] Error procesando tarea $i: $e');
            print('💥 [TAREAS] Datos de la tarea $i: ${data[i]}');
          }
        }

        return tareas;
      } else {
        print('❌ [TAREAS] Error del servidor: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('💥 [TAREAS] Error al obtener tareas del servidor: $e');
    }

    print('🔄 [TAREAS] Fallback a tareas locales');
    // Fallback a tareas locales
    return getTareasLocal(usuarioId);
  }

  @override
  Future<List<Tarea>> getTareasLocal(String usuarioLocalId) async {
    print(
      '🏠 [TAREAS] Obteniendo tareas locales para usuario: $usuarioLocalId',
    );
    try {
      final db = await SQLiteService.instance;
      final result = await db.query(
        'tareas',
        where: 'usuario_local_id = ?',
        whereArgs: [usuarioLocalId],
      );
      print('✅ [TAREAS] Tareas locales encontradas: ${result.length}');
      return result.map((e) => Tarea.fromMap(e)).toList();
    } catch (e) {
      print('💥 [TAREAS] Error al obtener tareas locales: $e');
      return [];
    }
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
      final uri = Uri.parse('${ApiConstants.tareas}/usuario/$usuarioId/filtrar')
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
        '${ApiConstants.tareas}/usuario/$usuarioId/completadas?completadas=$completadas',
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
    print('➕ [TAREAS] Agregando tarea: ${tarea.titulo}');
    print('➕ [TAREAS] Tarea data: ${tarea.toMap()}');

    try {
      final db = await SQLiteService.instance;

      // Verificar si el usuario existe localmente
      final usuarioExists = await db.query(
        'usuarios',
        where: 'local_id = ?',
        whereArgs: [tarea.usuarioLocalId],
        limit: 1,
      );

      if (usuarioExists.isEmpty) {
        print('⚠️ [TAREAS] Usuario no existe localmente, creando...');
        await db.insert('usuarios', {
          'local_id': tarea.usuarioLocalId,
          'remote_id':
              tarea.usuarioLocalId, // Usar el mismo ID como remote_id temporal
          'nombre': 'Usuario', // Nombre temporal
          'correo': 'usuario@temp.com', // Email temporal
          'last_modified': DateTime.now().toIso8601String(),
          'sync_status': 'pending',
          'u_id': 'temp', // U_ID temporal
        });
        print('✅ [TAREAS] Usuario creado localmente');
      }

      await db.insert(
        'tareas',
        tarea.toMapLocal(),
      ); // Usar toMapLocal para BD local
      print('✅ [TAREAS] Tarea guardada localmente');

      final url = ApiConstants.tareas;
      print('🌐 [TAREAS] Enviando al servidor: $url');

      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(tarea.toMap()), // Usar toMap para servidor
          )
          .timeout(_timeout);

      print('📡 [TAREAS] Respuesta del servidor - Status: ${res.statusCode}');
      print('📡 [TAREAS] Respuesta del servidor - Body: ${res.body}');

      if (res.statusCode == 200) {
        await db.update(
          'tareas',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [tarea.id],
        );
        print('✅ [TAREAS] Tarea sincronizada con servidor');
      } else {
        print('❌ [TAREAS] Error del servidor: ${res.statusCode} - ${res.body}');
        await db.update(
          'tareas',
          {'sync_status': 'pending'},
          where: 'id = ?',
          whereArgs: [tarea.id],
        );
        print('⏳ [TAREAS] Tarea marcada como pendiente');
      }
    } catch (e) {
      print('💥 [TAREAS] Error al agregar tarea: $e');
      try {
        final db = await SQLiteService.instance;
        await db.update(
          'tareas',
          {'sync_status': 'pending'},
          where: 'id = ?',
          whereArgs: [tarea.id],
        );
        print('⏳ [TAREAS] Tarea marcada como pendiente por error');
      } catch (dbError) {
        print(
          '💥 [TAREAS] Error al actualizar estado de sincronización: $dbError',
        );
      }
    }
  }

  @override
  Future<void> updateTarea(
    String id,
    Map<String, dynamic> camposActualizados,
  ) async {
    print('🔄 [TAREAS] Actualizando tarea: $id');
    print('🔄 [TAREAS] Campos a actualizar: $camposActualizados');

    final db = await SQLiteService.instance;
    camposActualizados['sync_status'] = 'pending';
    await db.update(
      'tareas',
      camposActualizados,
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      // Convertir campos para el servidor
      final camposServidor = <String, dynamic>{};

      if (camposActualizados.containsKey('completado')) {
        camposServidor['completada'] = camposActualizados['completado'] == 1;
      }
      if (camposActualizados.containsKey('titulo')) {
        camposServidor['titulo'] = camposActualizados['titulo'];
      }
      if (camposActualizados.containsKey('descripcion')) {
        camposServidor['descripcion'] = camposActualizados['descripcion'];
      }
      if (camposActualizados.containsKey('prioridad')) {
        camposServidor['prioridad'] = camposActualizados['prioridad'];
      }
      if (camposActualizados.containsKey('fecha_recordatorio')) {
        camposServidor['fecha_recordatorio'] =
            camposActualizados['fecha_recordatorio'];
      }
      if (camposActualizados.containsKey('origen')) {
        camposServidor['origen'] = camposActualizados['origen'];
      }

      print('🌐 [TAREAS] Enviando PATCH a: ${ApiConstants.tareas}/$id');
      print('🌐 [TAREAS] Datos del servidor: $camposServidor');

      final res = await http
          .patch(
            Uri.parse('${ApiConstants.tareas}/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(camposServidor),
          )
          .timeout(_timeout);

      print('📡 [TAREAS] Respuesta PATCH - Status: ${res.statusCode}');
      print('📡 [TAREAS] Respuesta PATCH - Body: ${res.body}');

      if (res.statusCode == 200) {
        await db.update(
          'tareas',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [id],
        );
        print('✅ [TAREAS] Tarea actualizada en servidor');
      } else {
        print(
          '❌ [TAREAS] Error del servidor en PATCH: ${res.statusCode} - ${res.body}',
        );
      }
    } catch (e) {
      print('💥 [TAREAS] Error al actualizar tarea en servidor: $e');
    }
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

  /// Sincronización completa bidireccional
  Future<void> syncBidireccional(String usuarioId) async {
    print(
      '🔄 [TAREAS] Iniciando sincronización bidireccional para usuario: $usuarioId',
    );

    try {
      // 1. Enviar tareas locales al servidor
      print('📤 [TAREAS] Enviando tareas locales al servidor...');
      await syncWithServer();
      print('✅ [TAREAS] Tareas locales enviadas');
    } catch (e) {
      print('💥 [TAREAS] Error al sincronizar con servidor: $e');
    }

    try {
      // 2. Obtener tareas del servidor
      print('📥 [TAREAS] Obteniendo tareas del servidor...');
      await syncFromServer(usuarioId);
      print('✅ [TAREAS] Tareas del servidor obtenidas');
    } catch (e) {
      print('💥 [TAREAS] Error al sincronizar desde servidor: $e');
    }
  }

  /// Sincroniza tareas desde el servidor hacia el cliente
  Future<List<Tarea>> syncFromServer(String usuarioId) async {
    print('📥 [TAREAS] Sincronizando desde servidor para usuario: $usuarioId');

    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimaSync = prefs.getString('ultima_sync_tareas');

      String url = '${ApiConstants.tareas}/usuario/$usuarioId/sync';
      if (ultimaSync != null) {
        url += '?ultima_sincronizacion=$ultimaSync';
      }

      print('🌐 [TAREAS] URL de sincronización: $url');

      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      print(
        '📡 [TAREAS] Respuesta de sincronización - Status: ${response.statusCode}',
      );
      print('📡 [TAREAS] Respuesta de sincronización - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> tareasData = data['tareas'];

        print(
          '📦 [TAREAS] Tareas recibidas del servidor: ${tareasData.length}',
        );

        final db = await SQLiteService.instance;
        final List<String> tareaIds = [];
        final List<Tarea> tareasProcesadas = [];

        for (int i = 0; i < tareasData.length; i++) {
          try {
            print(
              '🔧 [TAREAS] Procesando tarea de sincronización $i: ${tareasData[i]}',
            );
            final tarea = Tarea.fromMap(tareasData[i]);
            tareaIds.add(tarea.id);
            tareasProcesadas.add(tarea);

            // Verificar si la tarea ya existe localmente
            final existing = await db.query(
              'tareas',
              where: 'id = ?',
              whereArgs: [tarea.id],
              limit: 1,
            );

            if (existing.isEmpty) {
              // Insertar nueva tarea
              await db.insert(
                'tareas',
                tarea.toMapLocal(),
              ); // Usar toMapLocal para BD local
              print('➕ [TAREAS] Nueva tarea insertada: ${tarea.titulo}');
            } else {
              // Actualizar tarea existente
              await db.update(
                'tareas',
                tarea.toMapLocal(), // Usar toMapLocal para BD local
                where: 'id = ?',
                whereArgs: [tarea.id],
              );
              print('🔄 [TAREAS] Tarea actualizada: ${tarea.titulo}');
            }
            print(
              '✅ [TAREAS] Tarea de sincronización $i procesada exitosamente',
            );
          } catch (e) {
            print(
              '💥 [TAREAS] Error procesando tarea de sincronización $i: $e',
            );
            print(
              '💥 [TAREAS] Datos de la tarea de sincronización $i: ${tareasData[i]}',
            );
          }
        }

        // Marcar tareas como sincronizadas en el servidor
        if (tareaIds.isNotEmpty) {
          try {
            await _marcarTareasSincronizadas(usuarioId, tareaIds);
            print('✅ [TAREAS] Tareas marcadas como sincronizadas en servidor');
          } catch (e) {
            print('💥 [TAREAS] Error al marcar tareas como sincronizadas: $e');
          }
        }

        // Actualizar timestamp de última sincronización
        await prefs.setString(
          'ultima_sync_tareas',
          DateTime.now().toIso8601String(),
        );

        return tareasProcesadas;
      } else {
        print('❌ [TAREAS] Error en sincronización: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [TAREAS] Error en syncFromServer: $e');
    }

    return [];
  }

  /// Marca las tareas como sincronizadas en el servidor
  Future<void> _marcarTareasSincronizadas(
    String usuarioId,
    List<String> tareaIds,
  ) async {
    try {
      print('🔧 [TAREAS] Marcando tareas como sincronizadas: $tareaIds');
      final payload = {'tarea_ids': tareaIds};
      print('🔧 [TAREAS] Payload: $payload');

      await http
          .post(
            Uri.parse(
              '${ApiConstants.tareas}/usuario/$usuarioId/marcar-sincronizadas',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      print('✅ [TAREAS] Tareas marcadas como sincronizadas exitosamente');
    } catch (e) {
      print('💥 [TAREAS] Error al marcar tareas como sincronizadas: $e');
    }
  }

  @override
  Future<void> clearLocalData() async {
    final db = await SQLiteService.instance;
    await db.delete('tareas');
  }
}
