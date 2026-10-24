import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/translation.dart';

class KeyStore {
  const KeyStore();
  static const _storage = FlutterSecureStorage();
  Future<String?> read() => _storage.read(key: 'gemini_api_key');
  Future<void> write(String key) =>
      _storage.write(key: 'gemini_api_key', value: key.trim());
  Future<void> delete() => _storage.delete(key: 'gemini_api_key');
}

class Preferences {
  Preferences(this.store);
  final SharedPreferences store;
  String get source => languages.containsKey(store.getString('source'))
      ? store.getString('source')!
      : 'auto';
  String get target =>
      languages.containsKey(store.getString('target')) &&
          store.getString('target') != 'auto'
      ? store.getString('target')!
      : 'ru';
  String get uiLanguage =>
      ['ru', 'kk', 'en'].contains(store.getString('ui_language'))
      ? store.getString('ui_language')!
      : 'ru';
  String get theme => store.getString('theme') ?? 'system';
  Future<void> set(String key, String value) async {
    if (!await store.setString(key, value)) {
      throw const AppFailure('Could not save preferences. Please try again.');
    }
  }
}

class HistoryStore {
  HistoryStore(this.db);
  final Database db;
  static Future<HistoryStore> open({String? path}) async {
    final database = await openDatabase(
      path ?? p.join(await getDatabasesPath(), 'voicetext.db'),
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE translations (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at INTEGER NOT NULL, filename TEXT NOT NULL, source TEXT NOT NULL, target TEXT NOT NULL, original TEXT NOT NULL, translated TEXT NOT NULL, language TEXT NOT NULL)',
      ),
    );
    return HistoryStore(database);
  }

  Future<int> add(Translation item) => db.insert('translations', item.toMap());
  Future<List<Translation>> list() async => (await db.query(
    'translations',
    orderBy: 'created_at DESC, id DESC',
  )).map(Translation.fromMap).toList();
  Future<void> remove(int id) async {
    await db.delete('translations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    await db.delete('translations');
  }
}
