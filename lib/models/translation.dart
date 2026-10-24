class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

const languages = <String, String>{
  'auto': 'detect language',
  'en': 'english',
  'ru': 'russian',
  'kk': 'kazakh',
  'uk': 'ukrainian',
  'es': 'spanish',
  'fr': 'french',
  'de': 'german',
  'it': 'italian',
  'pt': 'portuguese',
  'tr': 'turkish',
  'ar': 'arabic',
  'hi': 'hindi',
  'zh': 'chinese',
  'ja': 'japanese',
  'ko': 'korean',
  'uz': 'uzbek',
};

class SpeechResult {
  const SpeechResult({
    required this.original,
    required this.translated,
    required this.language,
  });
  final String original;
  final String translated;
  final String language;
  factory SpeechResult.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const AppFailure(
        'Gemini returned an invalid result. Please try again.',
      );
    }
    String field(String key) {
      final text = value[key];
      if (text is! String || text.trim().isEmpty || text.length > 200000) {
        throw const AppFailure(
          'No complete transcript received. Try a shorter clip with clear speech.',
        );
      }
      return text.trim();
    }

    if (value['hasSpeech'] != true) {
      throw const AppFailure('No clear speech found. Try another recording.');
    }
    return SpeechResult(
      original: field('original'),
      translated: field('translated'),
      language: field('language'),
    );
  }
}

class Translation {
  const Translation({
    this.id,
    required this.createdAt,
    required this.filename,
    required this.source,
    required this.target,
    required this.result,
  });
  final int? id;
  final DateTime createdAt;
  final String filename;
  final String source;
  final String target;
  final SpeechResult result;
  Map<String, Object?> toMap() => {
    'created_at': createdAt.millisecondsSinceEpoch,
    'filename': filename,
    'source': source,
    'target': target,
    'original': result.original,
    'translated': result.translated,
    'language': result.language,
  };
  factory Translation.fromMap(Map<String, Object?> row) => Translation(
    id: row['id'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    filename: row['filename'] as String,
    source: row['source'] as String,
    target: row['target'] as String,
    result: SpeechResult(
      original: row['original'] as String,
      translated: row['translated'] as String,
      language: row['language'] as String,
    ),
  );
}
