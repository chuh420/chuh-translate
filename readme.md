[русский](readme.md) | [қазақша](readme.kk.md) | [english](readme.en.md)

# chuh translate

android-приложение для перевода речи. запишите голос или выберите аудиофайл, и рядом появятся расшифровка и перевод.

запросы идут напрямую в Gemini API с вашим ключом из [google ai studio](https://aistudio.google.com/apikey), расходы на вашей стороне. ключ лежит в защищённом хранилище телефона, история переводов остаётся на устройстве. аудио уходит в Google.

- 16 языков перевода и автоопределение языка записи
- форматы M4A, MP3, WAV, AAC, OGG, FLAC, AIFF, Opus и WebM, до 100 МБ
- история переводов
- интерфейс на русском, казахском и английском

## сборка

нужен Flutter с Dart 3.13.5 или новее.

```
flutter pub get
flutter run
flutter build apk
flutter test
```

тест `test/live_gemini_test.dart` обращается к настоящему API. он запускается, когда заданы `GEMINI_TEST_API_KEY` и `GEMINI_TEST_AUDIO`, иначе пропускается.
