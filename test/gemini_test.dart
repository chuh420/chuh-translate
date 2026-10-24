import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicetext/models/translation.dart';
import 'package:voicetext/services/gemini.dart';

Map<String, dynamic> response({Object? text, String reason = 'STOP'}) => {
  'candidates': [
    {
      'finishReason': reason,
      'content': {
        'parts': [
          {
            'text':
                text ??
                jsonEncode({
                  'hasSpeech': true,
                  'original': 'Привет!',
                  'translated': 'Hello!',
                  'language': 'russian',
                }),
          },
        ],
      },
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File audio;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('voicetext_test');
    audio = await File('${directory.path}/clip.m4a').writeAsBytes([1, 2, 3]);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test('parses complete multilingual result', () {
    final result = GeminiService.parseResponse(response());
    expect(result.original, 'Привет!');
    expect(result.translated, 'Hello!');
  });
  test('rejects invalid, empty, truncated and blocked AI results', () {
    for (final body in [
      null,
      {},
      {'candidates': []},
      {
        'candidates': [null],
      },
      response(text: 'not json'),
      response(reason: 'MAX_TOKENS'),
      response(reason: 'SAFETY'),
      response(text: jsonEncode({'hasSpeech': true, 'original': 42})),
      response(
        text: jsonEncode({
          'hasSpeech': false,
          'original': '',
          'translated': '',
          'language': '',
        }),
      ),
    ]) {
      expect(
        () => GeminiService.parseResponse(body),
        throwsA(isA<AppFailure>()),
      );
    }
  });
  test('ignores thought parts and joins split text', () {
    final text = jsonEncode({
      'hasSpeech': true,
      'original': 'Hello',
      'translated': 'Привет',
      'language': 'english',
    });
    final body = {
      'candidates': [
        {
          'finishReason': 'STOP',
          'content': {
            'parts': [
              {'thought': true, 'text': 'reasoning'},
              {'text': text.substring(0, 20)},
              {'text': text.substring(20)},
            ],
          },
        },
      ],
    };
    expect(GeminiService.parseResponse(body).translated, 'Привет');
  });
  test('rejects empty, unsupported and oversized audio', () async {
    final empty = await File('${directory.path}/empty.mp3').writeAsBytes([]);
    final unsupported = await File('${directory.path}/clip.txt')
        .writeAsString('audio');
    final large = File('${directory.path}/large.wav');
    final handle = await large.open(mode: FileMode.write);
    await handle.truncate(GeminiService.maxBytes + 1);
    await handle.close();
    for (final file in [empty, unsupported, large]) {
      await expectLater(
        GeminiService.validateFile(file),
        throwsA(isA<AppFailure>()),
      );
    }
  });
  test('uses HTTPS, key header, selected languages and structured output', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.uri.scheme, 'https');
          expect(options.uri.queryParameters.containsKey('key'), isFalse);
          expect(options.headers['x-goog-api-key'], 'test-user-key');
          expect(
            options.data['contents'][0]['parts'][0]['text'],
            contains('kazakh'),
          );
          expect(
            options.data['contents'][0]['parts'][0]['text'],
            contains('russian'),
          );
          expect(
            options.data['contents'][0]['parts'][1]['inlineData']['data'],
            base64Encode([1, 2, 3]),
          );
          expect(
            options
                .data['generationConfig']['responseFormat']['text']['mimeType'],
            'APPLICATION_JSON',
          );
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: response(),
            ),
          );
        },
      ),
    );
    final result = await GeminiService(client: dio).transcribe(
      audio: audio,
      apiKey: 'test-user-key',
      source: 'kk',
      target: 'ru',
      cancelToken: CancelToken(),
      onStatus: (_) {},
    );
    expect(result.translated, 'Hello!');
  });
  for (final code in [400, 401, 403, 404, 429, 500]) {
    test(
      'handles API error $code without leaking key or server response',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: code,
                  data: {'error': 'secret-server-data'},
                ),
                type: DioExceptionType.badResponse,
              ),
            ),
          ),
        );
        await expectLater(
          GeminiService(client: dio).transcribe(
            audio: audio,
            apiKey: 'sensitive-test-key',
            source: 'auto',
            target: 'en',
            cancelToken: CancelToken(),
            onStatus: (_) {},
          ),
          throwsA(
            isA<AppFailure>()
                .having(
                  (e) => e.message,
                  'message',
                  isNot(contains('sensitive-test-key')),
                )
                .having(
                  (e) => e.message,
                  'message',
                  isNot(contains('secret-server-data')),
                ),
          ),
        );
      },
    );
  }
  test('cancels before sending audio', () async {
    final token = CancelToken()..cancel('user');
    await expectLater(
      GeminiService().transcribe(
        audio: audio,
        apiKey: 'test-key',
        source: 'auto',
        target: 'en',
        cancelToken: token,
        onStatus: (_) {},
      ),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.message,
          'message',
          contains('canceled'),
        ),
      ),
    );
  });
  test('reports response-format errors as an app problem, without exposing raw errors', () {
    final failure = GeminiService.failureFromResponse(400, {
      'error': {
        'message': "Invalid value at 'generation_config.response_format.text.mime_type': sensitive-test-key",
        'status': 'INVALID_ARGUMENT',
      },
    });
    expect(failure.message, contains('update the app'));
    expect(failure.message, isNot(contains('sensitive-test-key')));
    expect(failure.message, isNot(contains('API key')));
  });
  test(
    'distinguishes invalid or expired keys and leaked keys from bad audio',
    () {
      for (final reason in ['API_KEY_INVALID', 'API_KEY_EXPIRED']) {
        final failure = GeminiService.failureFromResponse(400, {
          'error': {
            'details': [
              {'reason': reason},
            ],
          },
        });
        expect(failure.message, contains('Replace it in settings'));
      }
      expect(
        GeminiService.failureFromResponse(403, {
          'error': {'message': 'Your API key was reported as leaked.'},
        }).message,
        contains('blocked this API key'),
      );
      expect(
        GeminiService.failureFromResponse(400, {
          'error': {'message': 'Unsupported audio'},
        }).message,
        contains('another file'),
      );
    },
  );
  test('uploads large audio, checks readiness, uses file URI and deletes remote copy', () async {
    final large = File('${directory.path}/large.wav');
    final handle = await large.open(mode: FileMode.write);
    await handle.truncate(13 * 1024 * 1024);
    await handle.close();
    final dio = Dio();
    final paths = <String>[];
    final deleted = Completer<void>();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add('${options.method} ${options.path}');
          dynamic data;
          final headers = <String, List<String>>{};
          if (options.path.endsWith('/upload/v1beta/files')) {
            headers['x-goog-upload-url'] = [
              '${GeminiService.host}/upload/session',
            ];
            data = {};
          } else if (options.path.endsWith('/upload/session')) {
            expect(options.data, isA<Stream<List<int>>>());
            data = {
              'file': {
                'name': 'files/test123',
                'state': 'ACTIVE',
                'uri': '${GeminiService.host}/v1beta/files/test123',
              },
            };
          } else if (options.method == 'DELETE') {
            deleted.complete();
            data = {};
          } else {
            expect(
              options.data['contents'][0]['parts'][1]['fileData']['mimeType'],
              'audio/wav',
            );
            data = response();
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: data,
              statusCode: 200,
              headers: Headers.fromMap(headers),
            ),
          );
        },
      ),
    );
    await GeminiService(client: dio).transcribe(
      audio: large,
      apiKey: 'test-key',
      source: 'auto',
      target: 'en',
      cancelToken: CancelToken(),
      onStatus: (_) {},
    );
    await deleted.future.timeout(const Duration(seconds: 3));
    expect(paths.any((path) => path.startsWith('DELETE ')), isTrue);
    expect(paths.length, 4);
  });
}
