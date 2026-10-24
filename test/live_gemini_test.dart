import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicetext/services/gemini.dart';

void main() {
  final key = Platform.environment['GEMINI_TEST_API_KEY'];
  final sample = Platform.environment['GEMINI_TEST_AUDIO'];
  final samples = [
    sample,
    if (Platform.environment['GEMINI_TEST_AUDIO_M4A'] != null)
      Platform.environment['GEMINI_TEST_AUDIO_M4A'],
  ];
  for (final audioPath in samples) {
    test(
      'transcribes real ${audioPath?.split('.').last} audio and translates through the Gemini API',
      () async {
        HttpOverrides.global = null;
        final result = await GeminiService().transcribe(
          audio: File(audioPath!),
          apiKey: key!,
          source: 'en',
          target: 'ru',
          cancelToken: CancelToken(),
          onStatus: (_) {},
        );
        expect(result.original.toLowerCase(), contains('brooklyn'));
        expect(result.translated, matches(RegExp('[А-Яа-яЁё]')));
        expect(result.language.toLowerCase(), contains('english'));
        stdout.writeln('live transcript: ${result.original}');
        stdout.writeln('live translation: ${result.translated}');
      },
      skip: key == null || sample == null,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
