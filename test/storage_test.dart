import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voicetext/models/translation.dart';
import 'package:voicetext/services/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  test(
    'SQLite saves Unicode, orders newest first, deletes and clears',
    () async {
      final store = await HistoryStore.open(path: inMemoryDatabasePath);
      Translation item(String text) => Translation(
        createdAt: DateTime(2026),
        filename: 'recording',
        source: 'auto',
        target: 'kk',
        result: SpeechResult(
          original: text,
          translated: 'Сәлем! مرحبا',
          language: 'russian',
        ),
      );
      final first = await store.add(item("Привет ' мир"));
      final second = await store.add(item('second'));
      final rows = await store.list();
      expect(rows.map((item) => item.id), [second, first]);
      expect(rows.last.result.original, "Привет ' мир");
      expect(rows.first.result.translated, 'Сәлем! مرحبا');
      await store.remove(first);
      expect((await store.list()).length, 1);
      await store.clear();
      expect(await store.list(), isEmpty);
      await store.db.close();
    },
  );
  test(
    'preferences retain language and theme and reject invalid saved languages',
    () async {
      SharedPreferences.setMockInitialValues({
        'source': 'bad',
        'target': 'auto',
      });
      final prefs = Preferences(await SharedPreferences.getInstance());
      expect(prefs.source, 'auto');
      expect(prefs.target, 'ru');
      expect(prefs.uiLanguage, 'ru');
      await prefs.set('ui_language', 'kk');
      expect(prefs.uiLanguage, 'kk');
      await prefs.set('target', 'kk');
      await prefs.set('theme', 'dark');
      expect(prefs.target, 'kk');
      expect(prefs.theme, 'dark');
    },
  );
}
