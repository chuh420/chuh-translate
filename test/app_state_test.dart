import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicetext/app_state.dart';
import 'package:voicetext/models/translation.dart';
import 'package:voicetext/services/gemini.dart';
import 'package:voicetext/services/storage.dart';

class FakeDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHistory extends HistoryStore {
  FakeHistory() : super(FakeDatabase());
  bool fail = false;
  final items = <Translation>[];
  @override
  Future<int> add(Translation item) async {
    if (fail) throw StateError('disk full');
    items.add(item);
    return items.length;
  }

  @override
  Future<List<Translation>> list() async => items;
}

class FakeKeys extends KeyStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String key) async {
    if (fail) throw StateError('keystore unavailable');
    value = key;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

class FakeGemini extends GeminiService {
  int calls = 0;
  @override
  Future<SpeechResult> transcribe({
    required File audio,
    required String apiKey,
    required String source,
    required String target,
    required CancelToken cancelToken,
    required void Function(String) onStatus,
  }) async {
    calls++;
    return const SpeechResult(
      original: 'Сәлем',
      translated: 'Hello',
      language: 'kazakh',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (call) async => call.method == 'hasPermission' ? false : null,
      );
  late AppState state;
  late FakeHistory history;
  late FakeKeys keys;
  late FakeGemini gemini;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    history = FakeHistory();
    keys = FakeKeys();
    gemini = FakeGemini();
    state = AppState(
      historyStore: history,
      preferences: Preferences(await SharedPreferences.getInstance()),
      keys: keys,
      gemini: gemini,
    );
    state.audio = File('/not-used-by-fake.m4a');
    state.audioName = 'recording';
  });
  tearDown(() => state.dispose());
  test('requires the user key before contacting Gemini', () async {
    await state.process();
    expect(gemini.calls, 0);
    expect(state.error, contains('API key'));
    expect(state.busy, isFalse);
  });
  test(
    'keeps transcript available if SQLite fails and allows saving again',
    () async {
      keys.value = 'user-key';
      history.fail = true;
      await state.process();
      expect(state.result!.original, 'Сәлем');
      expect(state.unsaved, isNotNull);
      expect(state.error, contains('history could not be saved'));
      expect(state.busy, isFalse);
      history.fail = false;
      await state.saveResult();
      expect(state.unsaved, isNull);
      expect(history.items.length, 1);
      await state.saveResult();
      expect(history.items.length, 1);
    },
  );
  test(
    'saves and removes the user key through secure storage abstraction',
    () async {
      expect(await state.saveKey('short'), isFalse);
      expect(keys.value, isNull);
      expect(
        await state.saveKey('test-user-key-at-least-twenty-characters'),
        isTrue,
      );
      expect(state.hasKey, isTrue);
      await state.deleteKey();
      expect(state.hasKey, isFalse);
      expect(keys.value, isNull);
    },
  );
  test('handles keystore failure without reporting key as saved', () async {
    keys.fail = true;
    expect(
      await state.saveKey('test-user-key-at-least-twenty-characters'),
      isFalse,
    );
    expect(state.hasKey, isFalse);
    expect(state.savingKey, isFalse);
    expect(state.error, contains('secure storage'));
  });
  test(
    'handles microphone permission denial without losing existing audio',
    () async {
      await state.startRecording();
      expect(state.recording, isFalse);
      expect(state.workingWithAudio, isFalse);
      expect(state.audio, isNotNull);
      expect(state.error, contains('Microphone access'));
    },
  );
}
