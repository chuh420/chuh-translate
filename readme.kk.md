[русский](readme.md) | [қазақша](readme.kk.md) | [english](readme.en.md)

# chuh translate

сөзді аударатын android қосымшасы. дауысыңызды жазыңыз немесе аудиофайлды таңдаңыз, сонда бастапқы мәтін мен аударма қатар шығады.

сұраулар Gemini API-ге тікелей, [google ai studio](https://aistudio.google.com/apikey) сайтынан алған жеке кілтіңізбен кетеді, шығынды өзіңіз көтересіз. кілт телефонның қорғалған қоймасында сақталады, аудару тарихы құрылғыда қалады. аудио Google-ға жіберіледі.

- аударуға арналған 16 тіл және жазбаның тілін анықтау
- M4A, MP3, WAV, AAC, OGG, FLAC, AIFF, Opus және WebM форматтары, 100 МБ дейін
- аудару тарихы
- интерфейс орыс, қазақ және ағылшын тілдерінде

## құрастыру

Dart 3.13.5 немесе одан жаңа нұсқасы бар Flutter қажет.

```
flutter pub get
flutter run
flutter build apk
flutter test
```

`test/live_gemini_test.dart` нақты API-ге жүгінеді. `GEMINI_TEST_API_KEY` және `GEMINI_TEST_AUDIO` берілсе, ол іске қосылады, әйтпесе өткізіп жіберіледі.
