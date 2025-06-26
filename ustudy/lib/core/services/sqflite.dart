import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteService {
  static Database? _database;

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db'); // Cambia el nombre si quieres
    return _database!;
  }

  static Future<Database> _initDB(String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite no está disponible en Flutter web.');
    }

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        local_id TEXT PRIMARY KEY,
        remote_id TEXT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL,
        last_modified TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        u_id TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE tareas (
        id TEXT PRIMARY KEY,
        usuario_local_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        completado INTEGER NOT NULL DEFAULT 0,
        last_modified TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        prioridad TEXT DEFAULT 'media',
        fecha_recordatorio TEXT,
        origen TEXT DEFAULT 'usuario',
        FOREIGN KEY(usuario_local_id) REFERENCES usuarios(local_id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_usuario_local_id ON tareas(usuario_local_id);',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migración de versión 1 a 2: agregar columnas faltantes a la tabla tareas
    if (oldVersion < 2) {
      try {
        // Intentar agregar las columnas directamente, SQLite ignorará si ya existen
        await db.execute(
          'ALTER TABLE tareas ADD COLUMN prioridad TEXT DEFAULT "media"',
        );
        await db.execute(
          'ALTER TABLE tareas ADD COLUMN fecha_recordatorio TEXT',
        );
        await db.execute(
          'ALTER TABLE tareas ADD COLUMN origen TEXT DEFAULT "usuario"',
        );
        print('Migración completada exitosamente');
      } catch (e) {
        print('Error durante la migración: $e');
        // Si hay un error crítico, recrear solo la tabla tareas
        try {
          await db.execute('DROP TABLE IF EXISTS tareas');
          await db.execute('''
            CREATE TABLE tareas (
              id TEXT PRIMARY KEY,
              usuario_local_id TEXT NOT NULL,
              titulo TEXT NOT NULL,
              descripcion TEXT,
              completado INTEGER NOT NULL DEFAULT 0,
              last_modified TEXT NOT NULL,
              sync_status TEXT NOT NULL,
              prioridad TEXT DEFAULT 'media',
              fecha_recordatorio TEXT,
              origen TEXT DEFAULT 'usuario',
              FOREIGN KEY(usuario_local_id) REFERENCES usuarios(local_id) ON DELETE CASCADE
            );
          ''');
          await db.execute(
            'CREATE INDEX idx_usuario_local_id ON tareas(usuario_local_id);',
          );
          print('Tabla tareas recreada exitosamente');
        } catch (recreateError) {
          print('Error crítico al recrear la tabla tareas: $recreateError');
        }
      }
    }
  }

  // Método para limpiar la base de datos y empezar desde cero
  static Future<void> clearDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'app.db');

    // Eliminar el archivo de base de datos
    try {
      await databaseFactory.deleteDatabase(path);
      print('Base de datos eliminada exitosamente');
    } catch (e) {
      print('Error al eliminar la base de datos: $e');
    }
  }
}
