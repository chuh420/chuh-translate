import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'models/translation.dart';
import 'services/gemini.dart';
import 'services/storage.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.historyStore,
    required this.preferences,
    KeyStore? keys,
    GeminiService? gemini,
  }) : keys = keys ?? const KeyStore(),
       gemini = gemini ?? GeminiService() {
    uiLanguage = preferences.uiLanguage;
    source = preferences.source;
    target = preferences.target;
    theme = switch (preferences.theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
  final HistoryStore historyStore;
  final Preferences preferences;
  final KeyStore keys;
  final GeminiService gemini;
  final _recorder = AudioRecorder();
  late String uiLanguage;
  late String source;
  late String target;
  late ThemeMode theme;
  bool hasKey = false;
  bool recording = false;
  bool busy = false;
  bool workingWithAudio = false;
  bool savingKey = false;
  bool loadingHistory = false;
  bool savingResult = false;
  File? audio;
  String? audioName;
  int audioBytes = 0;
  int recordingSeconds = 0;
  SpeechResult? result;
  String? resultTarget;
  Translation? unsaved;
  String? error;
  String? historyError;
  String status = '';
  List<Translation> history = [];
  Timer? _ticker;
  StreamSubscription<RecordState>? _recordSubscription;
  String? _recordingPath;
  CancelToken? _cancel;
  final _clock = Stopwatch();
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool get locked => busy || workingWithAudio || recording;
  String get durationLabel =>
      '${(recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(recordingSeconds % 60).toString().padLeft(2, '0')}';
  String get sizeLabel => audioBytes < 1024 * 1024
      ? '${(audioBytes / 1024).ceil()} KB'
      : '${(audioBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  Future<void> initialize() async {
    try {
      hasKey = (await keys.read())?.isNotEmpty ?? false;
    } catch (_) {
      error = 'Could not open secure storage. Try saving your key in settings.';
    }
    await refreshHistory();
  }

  String message(Object error) => error is AppFailure
      ? error.message
      : 'Something went wrong. Please try again.';
  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> setLanguage({String? from, String? to}) async {
    if (locked) return;
    try {
      if (from != null && languages.containsKey(from)) {
        await preferences.set('source', from);
        source = from;
      }
      if (to != null && to != 'auto' && languages.containsKey(to)) {
        await preferences.set('target', to);
        target = to;
      }
    } catch (e) {
      error = message(e);
    }
    notifyListeners();
  }

  Future<void> setUiLanguage(String value) async {
    if (!['ru', 'kk', 'en'].contains(value)) return;
    try {
      await preferences.set('ui_language', value);
      uiLanguage = value;
    } catch (e) {
      error = message(e);
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode value) async {
    try {
      await preferences.set('theme', value.name);
      theme = value;
    } catch (e) {
      error = message(e);
    }
    notifyListeners();
  }

  Future<bool> saveKey(String key) async {
    if (savingKey) return false;
    if (key.trim().length < 20 || RegExp(r'\s').hasMatch(key.trim())) {
      error = 'Paste a valid Gemini API key without spaces.';
      notifyListeners();
      return false;
    }
    savingKey = true;
    notifyListeners();
    try {
      await keys.write(key);
      hasKey = true;
      error = null;
      return true;
    } catch (_) {
      error = 'Could not save the API key in secure storage.';
      return false;
    } finally {
      savingKey = false;
      notifyListeners();
    }
  }

  Future<void> deleteKey() async {
    if (savingKey || busy) return;
    savingKey = true;
    notifyListeners();
    try {
      await keys.delete();
      hasKey = false;
    } catch (_) {
      error = 'Could not remove the API key. Please try again.';
    } finally {
      savingKey = false;
      notifyListeners();
    }
  }

  Future<void> _discardAudio() async {
    final old = audio;
    audio = null;
    audioName = null;
    audioBytes = 0;
    if (old != null) {
      try {
        if (await old.exists()) await old.delete();
      } catch (_) {}
    }
  }

  Future<void> clearAudio() async {
    if (locked) return;
    workingWithAudio = true;
    notifyListeners();
    await _discardAudio();
    workingWithAudio = false;
    notifyListeners();
  }

  Future<void> pickAudio() async {
    if (locked) return;
    workingWithAudio = true;
    error = null;
    notifyListeners();
    File? copied;
    try {
      final picked = await FilePicker.pickFile(type: FileType.audio);
      if (picked == null) return;
      final path = picked.path;
      if (path == null) {
        throw const AppFailure(
          'Could not open this file. Choose a file saved on the device.',
        );
      }
      final original = File(path);
      await GeminiService.validateFile(original);
      final temp = await getTemporaryDirectory();
      final directory = await Directory(p.join(temp.path, 'voicetext'))
          .create(recursive: true);
      copied = await original.copy(
        p.join(
          directory.path,
          'import_${DateTime.now().microsecondsSinceEpoch}${p.extension(path).toLowerCase()}',
        ),
      );
      await _discardAudio();
      audio = copied;
      copied = null;
      audioName = picked.name;
      audioBytes = await audio!.length();
      result = null;
      unsaved = null;
    } catch (e) {
      error = e is FileSystemException
          ? 'Could not read this audio file. Please select it again.'
          : message(e);
    } finally {
      if (copied != null) {
        try {
          await copied.delete();
        } catch (_) {}
      }
      workingWithAudio = false;
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (locked) return;
    workingWithAudio = true;
    error = null;
    notifyListeners();
    try {
      if (!await _recorder.hasPermission()) {
        throw const AppFailure(
          'Microphone access is required. Allow it in Android settings → apps → chuh translate → permissions.',
        );
      }
      final temp = await getTemporaryDirectory();
      final directory = await Directory(p.join(temp.path, 'voicetext'))
          .create(recursive: true);
      _recordSubscription ??= _recorder.onStateChanged().listen(
        (value) {
          if (recording && !workingWithAudio && value != RecordState.record) {
            error = 'Recording was interrupted. Review the captured audio before sending.';
            unawaited(stopRecording());
          }
        },
        onError: (Object _) {
          if (recording && !workingWithAudio) {
            error =
                'The microphone was interrupted. Please try recording again.';
            unawaited(stopRecording());
          }
        },
      );
      final path = p.join(
        directory.path,
        'recording_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      _recordingPath = path;
      await _discardAudio();
      result = null;
      unsaved = null;
      recording = true;
      recordingSeconds = 0;
      _clock
        ..reset()
        ..start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingSeconds = _clock.elapsed.inSeconds;
        notifyListeners();
        if (recordingSeconds >= 600) unawaited(stopRecording());
      });
    } catch (e) {
      error = e is AppFailure ? e.message : 'Could not start the microphone. Check permissions and close other recording apps.';
    } finally {
      workingWithAudio = false;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!recording || workingWithAudio) return;
    workingWithAudio = true;
    _ticker?.cancel();
    _clock.stop();
    notifyListeners();
    try {
      final path = await _recorder.stop() ?? _recordingPath;
      if (path == null) {
        throw const AppFailure('Recording failed. Please try again.');
      }
      audio = File(path);
      audioName = 'recording · $durationLabel';
      audioBytes = await audio!.length();
      await GeminiService.validateFile(audio!);
    } catch (e) {
      error = message(e);
      await _discardAudio();
    } finally {
      recording = false;
      _recordingPath = null;
      workingWithAudio = false;
      notifyListeners();
    }
  }

  Future<void> process() async {
    if (locked || audio == null) return;
    busy = true;
    error = null;
    result = null;
    unsaved = null;
    status = 'connecting to Gemini';
    final from = source;
    final to = target;
    _cancel = CancelToken();
    notifyListeners();
    try {
      final key = await keys.read();
      if (key == null || key.isEmpty) {
        hasKey = false;
        throw const AppFailure(
          'Add your Gemini API key in settings to continue.',
        );
      }
      if (_cancel!.isCancelled) throw _cancel!.cancelError!;
      final response = await gemini.transcribe(
        audio: audio!,
        apiKey: key,
        source: from,
        target: to,
        cancelToken: _cancel!,
        onStatus: (value) {
          status = value;
          notifyListeners();
        },
      );
      if (_cancel!.isCancelled) throw _cancel!.cancelError!;
      result = response;
      resultTarget = to;
      unsaved = Translation(
        createdAt: DateTime.now(),
        filename: audioName ?? 'audio',
        source: from,
        target: to,
        result: response,
      );
      await saveResult();
    } catch (e) {
      error = e is DioException && CancelToken.isCancel(e)
          ? 'Processing canceled. Your audio is ready to retry.'
          : message(e);
    } finally {
      busy = false;
      status = '';
      _cancel = null;
      notifyListeners();
    }
  }

  void cancel() => _cancel?.cancel('user');
  Future<void> saveResult() async {
    final item = unsaved;
    if (item == null || savingResult) return;
    savingResult = true;
    notifyListeners();
    try {
      await historyStore.add(item);
      unsaved = null;
      await refreshHistory();
    } catch (_) {
      error = 'Text is ready, but history could not be saved. Copy your text or retry saving.';
    } finally {
      savingResult = false;
    }
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    loadingHistory = true;
    historyError = null;
    notifyListeners();
    try {
      history = await historyStore.list();
    } catch (_) {
      historyError = 'Could not load history. Please retry.';
    } finally {
      loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> removeHistory(int id) async {
    try {
      await historyStore.remove(id);
      await refreshHistory();
    } catch (_) {
      error = 'Could not delete this translation.';
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await historyStore.clear();
      await refreshHistory();
    } catch (_) {
      error = 'Could not clear history.';
      notifyListeners();
    }
  }

  Future<void> _disposeRecorder() async {
    try {
      await _recorder.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _cancel?.cancel('disposed');
    unawaited(_recordSubscription?.cancel());
    unawaited(_disposeRecorder());
    super.dispose();
  }
}
