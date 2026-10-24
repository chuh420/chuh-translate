[русский](readme.md) | [қазақша](readme.kk.md) | [english](readme.en.md)

# chuh translate

an android app for translating speech. record your voice or pick an audio file, and the transcript and translation appear side by side.

requests go straight to the Gemini API with your own key from [google ai studio](https://aistudio.google.com/apikey), so you pay for your own usage. the key sits in the phone's secure storage and the translation history stays on the device. the audio goes to Google.

- 16 target languages and automatic detection of the recording's language
- M4A, MP3, WAV, AAC, OGG, FLAC, AIFF, Opus and WebM files up to 100 MB
- translation history
- interface in Russian, Kazakh and English

## build

you need Flutter with Dart 3.13.5 or newer.

```
flutter pub get
flutter run
flutter build apk
flutter test
```

`test/live_gemini_test.dart` calls the real API. it runs when `GEMINI_TEST_API_KEY` and `GEMINI_TEST_AUDIO` are set and skips otherwise.
