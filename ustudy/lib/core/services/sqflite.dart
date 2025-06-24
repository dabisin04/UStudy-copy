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
      version: 1,
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
        FOREIGN KEY(usuario_local_id) REFERENCES usuarios(local_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_usuario_local_id ON tareas(usuario_local_id);');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí puedes manejar migraciones en el futuro
    if (oldVersion < newVersion) {
      // migraciones necesarias
    }
  }
}
