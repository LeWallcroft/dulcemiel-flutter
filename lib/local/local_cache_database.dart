import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract interface class JsonCacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Caché local SQLite para respuestas públicas que se pueden mostrar offline.
/// No almacena contraseñas, tokens, direcciones ni datos privados de pedidos.
class LocalCacheDatabase implements JsonCacheStore {
  LocalCacheDatabase._();

  static final LocalCacheDatabase instance = LocalCacheDatabase._();
  static const _databaseName = 'dulce_miel_cache.db';
  static const _version = 1;

  Future<Database>? _opening;

  Future<Database> get _database => _opening ??= _open();

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      path.join(directory, _databaseName),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache_json (
            cache_key TEXT PRIMARY KEY,
            json_value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<String?> read(String key) async {
    final rows = await (await _database).query(
      'cache_json',
      columns: const ['json_value'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['json_value'] as String;
  }

  @override
  Future<void> write(String key, String value) async {
    await (await _database).insert('cache_json', {
      'cache_key': key,
      'json_value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
