import 'package:flutter/material.dart';

extension TranslationContext on BuildContext {
  String tr(String text) {
    final code = Localizations.localeOf(this).languageCode;
    if (code == 'en') return text;
    final index = code == 'kk' ? 1 : 0;
    final exact = _strings[text] ?? _strings[text.toLowerCase()];
    if (exact != null) return exact[index];
    if (text.contains(' → ')) return text.split(' → ').map(tr).join(' → ');
    for (final prefix in ['uploading audio · ', 'recording · ', 'model: ']) {
      if (text.startsWith(prefix)) {
        return '${tr(prefix.split(' · ').first.replaceAll(': ', ''))}${prefix.contains(' · ') ? ' · ' : ': '}${text.substring(prefix.length)}';
      }
    }
    if (text.startsWith('copy ')) {
      return '${tr('copy')} ${tr(text.substring(5))}';
    }
    return text;
  }
}

class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}

const _strings = <String, List<String>>{
  'translate': ['перевод', 'аудару'],
  'history': ['история', 'тарих'],
  'settings': ['настройки', 'баптаулар'],
  'speech, in your words.': ['из аудио в текст.', 'аудиодан мәтінге.'],
  'record or upload audio. get the transcript and a translation together.': [
    'выберите аудиофайл или запишите голос. получите исходный текст и перевод.',
    'аудиофайлды таңдаңыз немесе дауысты жазыңыз. бастапқы мәтін мен аударманы алыңыз.',
  ],
  'bring your Gemini key': ['ваш ключ Gemini', 'сіздің Gemini кілтіңіз'],
  'add your own API key to start. you control the key and your Google API usage.':
      [
        'добавьте личный API-ключ. вы управляете ключом и расходами Google API.',
        'жеке API кілтін қосыңыз. кілт пен Google API шығындарын өзіңіз басқарасыз.',
      ],
  'set up API key': ['добавить API-ключ', 'API кілтін қосу'],
  'spoken language': ['язык аудио', 'аудио тілі'],
  'translate to': ['язык перевода', 'аударма тілі'],
  'detect language': ['авто', 'авто'],
  'english': ['английский', 'ағылшын'],
  'russian': ['русский', 'орыс'],
  'kazakh': ['казахский', 'қазақ'],
  'ukrainian': ['украинский', 'украин'],
  'spanish': ['испанский', 'испан'],
  'french': ['французский', 'француз'],
  'german': ['немецкий', 'неміс'],
  'italian': ['итальянский', 'итальян'],
  'portuguese': ['португальский', 'португал'],
  'turkish': ['турецкий', 'түрік'],
  'arabic': ['арабский', 'араб'],
  'hindi': ['хинди', 'хинди'],
  'chinese': ['китайский', 'қытай'],
  'japanese': ['японский', 'жапон'],
  'korean': ['корейский', 'корей'],
  'uzbek': ['узбекский', 'өзбек'],
  'recording': ['запись', 'жазу'],
  'audio ready': ['аудио готово', 'аудио дайын'],
  'add your audio': ['добавьте аудио', 'аудио қосыңыз'],
  'remove audio': ['удалить аудио', 'аудионы жою'],
  'recording stops after 10 minutes or when you leave the app.': [
    'запись остановится через 10 минут или при сворачивании приложения.',
    'жазу 10 минуттан кейін немесе қолданба жабылғанда тоқтайды.',
  ],
  'use your microphone or choose a file from your device. up to 100 MB.': [
    'выберите файл с устройства или используйте микрофон. до 100 МБ.',
    'құрылғыдан файл таңдаңыз немесе микрофонды қолданыңыз. 100 МБ дейін.',
  ],
  'stop recording': ['остановить запись', 'жазуды тоқтату'],
  'record again': ['записать заново', 'қайта жазу'],
  'record audio': ['записать голос', 'дауысты жазу'],
  'choose file': ['выбрать файл', 'файл таңдау'],
  'cancel processing': ['отменить обработку', 'өңдеуден бас тарту'],
  'transcribe & translate': ['распознать и перевести', 'тану және аудару'],
  'audio is sent to Google Gemini only when you tap translate. internet required. API charges may apply.':
      [
        'аудио отправляется в Google Gemini после нажатия кнопки. нужен интернет. Google может взимать плату за API.',
        'аудио түймені басқаннан кейін Google Gemini қызметіне жіберіледі. интернет қажет. API үшін ақы алынуы мүмкін.',
      ],
  'your result': ['результат', 'нәтиже'],
  'copy both': ['скопировать всё', 'бәрін көшіру'],
  'retry saving to history': ['сохранить в историю', 'тарихқа сақтау'],
  'saved on this device. review names and important details for accuracy.': [
    'сохранено на устройстве. проверьте имена и важные детали.',
    'құрылғыда сақталды. есімдер мен маңызды деректерді тексеріңіз.',
  ],
  'not saved yet. copy this result before leaving.': [
    'ещё не сохранено. скопируйте результат перед выходом.',
    'әлі сақталмады. шығар алдында нәтижені көшіріңіз.',
  ],
  'original': ['оригинал', 'түпнұсқа'],
  'translation': ['перевод', 'аударма'],
  'copy': ['скопировать', 'көшіру'],
  'copied to clipboard': ['скопировано', 'көшірілді'],
  'could not copy text. select it and try again.': [
    'не удалось скопировать текст. выделите его и попробуйте снова.',
    'мәтінді көшіру мүмкін болмады. оны белгілеп, қайталап көріңіз.',
  ],
  'cancel': ['отмена', 'бас тарту'],
  'retry': ['повторить', 'қайталау'],
  'clear history': ['очистить историю', 'тарихты тазалау'],
  'clear history?': ['очистить историю?', 'тарихты тазалау керек пе?'],
  'This deletes all saved transcripts and translations from this device.': [
    'все сохранённые тексты и переводы будут удалены с устройства.',
    'құрылғыдағы сақталған мәтіндер мен аудармалар жойылады.',
  ],
  'delete all': ['удалить всё', 'бәрін жою'],
  'dismiss error': ['закрыть сообщение', 'хабарды жабу'],
  'stop recording or cancel processing before leaving.': [
    'перед выходом остановите запись или отмените обработку.',
    'шығар алдында жазуды тоқтатыңыз немесе өңдеуден бас тартыңыз.',
  ],
  'your words, kept here.': ['ваши переводы здесь.', 'аудармаларыңыз осында.'],
  'completed transcripts and translations appear here. you can read and copy them offline.':
      [
        'здесь появятся готовые тексты и переводы. их можно читать и копировать без интернета.',
        'дайын мәтіндер мен аудармалар осында сақталады. оларды интернетсіз оқып, көшіруге болады.',
      ],
  'saved translation': ['сохранённый перевод', 'сақталған аударма'],
  'delete translation': ['удалить перевод', 'аударманы жою'],
  'delete translation?': ['удалить перевод?', 'аударманы жою керек пе?'],
  'This removes the transcript and translation from your history.': [
    'исходный текст и перевод будут удалены из истории.',
    'бастапқы мәтін мен аударма тарихтан жойылады.',
  ],
  'delete': ['удалить', 'жою'],
  'make it yours.': ['ваши настройки.', 'сіздің баптауларыңыз.'],
  'your key, your languages, your device.': [
    'ключ API, язык и оформление.',
    'API кілті, тіл және көрініс.',
  ],
  'Gemini API key': ['API-ключ Gemini', 'Gemini API кілті'],
  'a key is saved in secure device storage. enter a new key to replace it.': [
    'ключ сохранён в защищённом хранилище. введите новый, чтобы заменить его.',
    'кілт қорғалған қоймада сақталған. оны ауыстыру үшін жаңа кілт енгізіңіз.',
  ],
  'paste your own key from Google AI Studio. the app does not include a shared key.':
      [
        'вставьте личный ключ из Google AI Studio. в приложении нет общего ключа.',
        'Google AI Studio жеке кілтін енгізіңіз. қолданбада ортақ кілт жоқ.',
      ],
  'replacement key': ['новый ключ', 'жаңа кілт'],
  'API key': ['API-ключ', 'API кілті'],
  'hide key': ['скрыть ключ', 'кілтті жасыру'],
  'show key': ['показать ключ', 'кілтті көрсету'],
  'API key saved on this device': [
    'API-ключ сохранён на устройстве',
    'API кілті құрылғыда сақталды',
  ],
  'saving…': ['сохранение…', 'сақталуда…'],
  'save key': ['сохранить ключ', 'кілтті сақтау'],
  'remove saved key': ['удалить сохранённый ключ', 'сақталған кілтті жою'],
  'remove API key?': ['удалить API-ключ?', 'API кілтін жою керек пе?'],
  'You can keep reading saved translations. Add a key again to process new audio.':
      [
        'история останется доступна. для обработки нового аудио потребуется ключ.',
        'тарих қолжетімді болып қалады. жаңа аудионы өңдеу үшін кілт қажет.',
      ],
  'remove key': ['удалить ключ', 'кілтті жою'],
  'appearance': ['оформление', 'көрініс'],
  'theme': ['тема', 'тақырып'],
  'follow system': ['как в системе', 'жүйедегідей'],
  'light': ['светлая', 'ашық'],
  'dark': ['тёмная', 'қараңғы'],
  'interface language': ['язык интерфейса', 'интерфейс тілі'],
  'data & privacy': ['данные и конфиденциальность', 'деректер және құпиялық'],
  'audio goes from your device to Google Gemini for processing. Google handles it under the terms for your API account. API usage can incur charges.':
      [
        'приложение отправляет аудио напрямую в Google Gemini. Google обрабатывает его по условиям вашего API-аккаунта и может взимать плату.',
        'қолданба аудионы тікелей Google Gemini қызметіне жібереді. Google оны API есептік жазбаңыздың шарттарына сай өңдейді және ақы алуы мүмкін.',
      ],
  'history stores text on this device. temporary audio stays in the app cache until you replace or remove it; Android may clear it. the app does not back up your key or history.':
      [
        'история хранит текст на устройстве. временное аудио остаётся в кэше до замены или удаления; Android может очистить кэш. ключ и история не попадают в резервную копию.',
        'тарих мәтінді құрылғыда сақтайды. уақытша аудио ауыстырылғанша немесе жойылғанша кэште қалады; Android кэшті тазалауы мүмкін. кілт пен тарихтың сақтық көшірмесі жасалмайды.',
      ],
  'for larger files, the app requests deletion of the uploaded copy after processing. if deletion fails, Google expires Files API uploads after 48 hours.':
      [
        'после обработки крупных файлов приложение запрашивает удаление копии у Google. при сбое Google удалит загрузку Files API через 48 часов.',
        'үлкен файлдарды өңдегеннен кейін қолданба Google көшірмесін жоюды сұрайды. жою орындалмаса, Google Files API файлын 48 сағаттан кейін жояды.',
      ],
  'model': ['модель', 'модель'],
  'about': ['о приложении', 'қолданба туралы'],
  'connecting to Gemini': ['подключение к Gemini', 'Gemini қызметіне қосылу'],
  'preparing audio': ['подготовка аудио', 'аудионы дайындау'],
  'uploading audio': ['загрузка аудио', 'аудионы жүктеу'],
  'preparing uploaded audio': [
    'подготовка загруженного аудио',
    'жүктелген аудионы дайындау',
  ],
  'transcribing and translating': [
    'распознавание и перевод',
    'тану және аудару',
  ],
  'Could not open local storage. Check available space and retry.': [
    'не удалось открыть хранилище. проверьте свободное место и повторите.',
    'қойманы ашу мүмкін болмады. бос орынды тексеріп, қайталаңыз.',
  ],
  'Could not open secure storage. Try saving your key in settings.': [
    'не удалось открыть защищённое хранилище. сохраните ключ в настройках.',
    'қорғалған қойманы ашу мүмкін болмады. кілтті баптауларда сақтаңыз.',
  ],
  'Something went wrong. Please try again.': [
    'произошла ошибка. попробуйте ещё раз.',
    'қате орын алды. қайталап көріңіз.',
  ],
  'Could not save preferences. Please try again.': [
    'не удалось сохранить настройки. попробуйте ещё раз.',
    'баптауларды сақтау мүмкін болмады. қайталап көріңіз.',
  ],
  'Paste a valid Gemini API key without spaces.': [
    'вставьте корректный API-ключ Gemini без пробелов.',
    'дұрыс Gemini API кілтін бос орынсыз енгізіңіз.',
  ],
  'Could not save the API key in secure storage.': [
    'не удалось сохранить ключ в защищённом хранилище.',
    'кілтті қорғалған қоймада сақтау мүмкін болмады.',
  ],
  'Could not remove the API key. Please try again.': [
    'не удалось удалить ключ. попробуйте ещё раз.',
    'кілтті жою мүмкін болмады. қайталап көріңіз.',
  ],
  'Could not open this file. Choose a file saved on the device.': [
    'не удалось открыть файл. выберите файл, сохранённый на устройстве.',
    'файлды ашу мүмкін болмады. құрылғыда сақталған файлды таңдаңыз.',
  ],
  'Could not read this audio file. Please select it again.': [
    'не удалось прочитать аудиофайл. выберите его ещё раз.',
    'аудиофайлды оқу мүмкін болмады. оны қайта таңдаңыз.',
  ],
  'Microphone access is required. Allow it in Android settings → apps → chuh translate → permissions.':
      [
        'нужен доступ к микрофону. разрешите его в настройках Android → приложения → chuh translate → разрешения.',
        'микрофонға рұқсат қажет. Android баптаулары → қолданбалар → chuh translate → рұқсаттар бөлімінде қосыңыз.',
      ],
  'Recording was interrupted. Review the captured audio before sending.': [
    'запись прервана. проверьте аудио перед отправкой.',
    'жазу үзілді. жібермес бұрын аудионы тексеріңіз.',
  ],
  'The microphone was interrupted. Please try recording again.': [
    'работа микрофона прервана. попробуйте записать заново.',
    'микрофон жұмысы үзілді. қайта жазып көріңіз.',
  ],
  'Could not start the microphone. Check permissions and close other recording apps.':
      [
        'не удалось включить микрофон. проверьте разрешения и закройте другие приложения записи.',
        'микрофонды қосу мүмкін болмады. рұқсаттарды тексеріп, басқа жазу қолданбаларын жабыңыз.',
      ],
  'Recording failed. Please try again.': [
    'не удалось записать аудио. попробуйте ещё раз.',
    'аудионы жазу мүмкін болмады. қайталап көріңіз.',
  ],
  'Add your Gemini API key in settings to continue.': [
    'добавьте свой API-ключ Gemini в настройках.',
    'баптауларда жеке Gemini API кілтін қосыңыз.',
  ],
  'Processing canceled. Your audio is ready to retry.': [
    'обработка отменена. можно отправить аудио снова.',
    'өңдеу тоқтатылды. аудионы қайта жіберуге болады.',
  ],
  'Text is ready, but history could not be saved. Copy your text or retry saving.':
      [
        'текст готов, но сохранить историю не удалось. скопируйте текст или повторите сохранение.',
        'мәтін дайын, бірақ тарих сақталмады. мәтінді көшіріңіз немесе қайта сақтаңыз.',
      ],
  'Could not load history. Please retry.': [
    'не удалось загрузить историю. повторите попытку.',
    'тарихты жүктеу мүмкін болмады. қайталаңыз.',
  ],
  'Could not delete this translation.': [
    'не удалось удалить перевод.',
    'аударманы жою мүмкін болмады.',
  ],
  'Could not clear history.': [
    'не удалось очистить историю.',
    'тарихты тазалау мүмкін болмады.',
  ],
  'Unsupported audio format. Choose M4A, MP3, WAV, AAC, OGG, FLAC, AIFF, Opus or WebM.':
      [
        'формат не поддерживается. выберите M4A, MP3, WAV, AAC, OGG, FLAC, AIFF, Opus или WebM.',
        'пішім қолдау таппайды. M4A, MP3, WAV, AAC, OGG, FLAC, AIFF, Opus немесе WebM таңдаңыз.',
      ],
  'This audio file is empty.': ['аудиофайл пуст.', 'аудиофайл бос.'],
  'Choose an audio file smaller than 100 MB.': [
    'выберите аудиофайл размером до 100 МБ.',
    '100 МБ дейінгі аудиофайлды таңдаңыз.',
  ],
  'Gemini could not start the upload. Please retry.': [
    'Gemini не смог начать загрузку. повторите попытку.',
    'Gemini жүктеуді бастай алмады. қайталаңыз.',
  ],
  'Gemini returned an invalid upload. Please retry.': [
    'Gemini вернул некорректные данные загрузки. повторите попытку.',
    'Gemini қате жүктеу деректерін қайтарды. қайталаңыз.',
  ],
  'Invalid upload status. Please retry.': [
    'не удалось проверить загрузку. повторите попытку.',
    'жүктеу күйін тексеру мүмкін болмады. қайталаңыз.',
  ],
  'Gemini could not read this audio. Try another file.': [
    'Gemini не смог прочитать аудио. попробуйте другой файл.',
    'Gemini аудионы оқи алмады. басқа файлды көріңіз.',
  ],
  'Processing timed out. Try a shorter audio clip.': [
    'время обработки истекло. попробуйте более короткое аудио.',
    'өңдеу уақыты аяқталды. қысқа аудионы көріңіз.',
  ],
  'The Gemini API key is invalid or expired. Replace it in settings.': [
    'API-ключ Gemini недействителен или истёк. замените его в настройках.',
    'Gemini API кілті жарамсыз немесе мерзімі аяқталған. оны баптауларда ауыстырыңыз.',
  ],
  'Google blocked this API key. Create a new key in Google AI Studio.': [
    'Google заблокировал API-ключ. создайте новый в Google AI Studio.',
    'Google API кілтін бұғаттады. Google AI Studio қызметінде жаңа кілт жасаңыз.',
  ],
  'The app sent an unsupported request to Gemini. Please update the app.': [
    'ошибка формата запроса приложения. обновите приложение.',
    'қолданба сұрауының пішімі қате. қолданбаны жаңартыңыз.',
  ],
  'Gemini rejected the audio request. Try another file or a shorter recording.': [
    'Gemini отклонил аудио. попробуйте другой файл или более короткую запись.',
    'Gemini аудионы қабылдамады. басқа файлды немесе қысқа жазбаны көріңіз.',
  ],
  'API access denied. Check your key, project permissions and region.': [
    'доступ к API запрещён. проверьте ключ, разрешения проекта и регион.',
    'API қызметіне рұқсат жоқ. кілтті, жоба рұқсаттарын және аймақты тексеріңіз.',
  ],
  'The Gemini model is unavailable for this project.': [
    'модель Gemini недоступна для этого проекта.',
    'Gemini моделі бұл жобаға қолжетімсіз.',
  ],
  'This audio is too large for Gemini. Try a smaller file.': [
    'аудио слишком большое для Gemini. выберите файл поменьше.',
    'аудио Gemini үшін тым үлкен. кішірек файл таңдаңыз.',
  ],
  'Gemini quota reached. Check your billing or wait before retrying.': [
    'квота Gemini исчерпана. проверьте оплату или повторите позже.',
    'Gemini квотасы таусылды. төлемді тексеріңіз немесе кейін қайталаңыз.',
  ],
  'Gemini is temporarily unavailable. Please try again.': [
    'Gemini временно недоступен. попробуйте ещё раз.',
    'Gemini уақытша қолжетімсіз. қайталап көріңіз.',
  ],
  'Could not reach Gemini. Check your internet connection and try again.': [
    'не удалось связаться с Gemini. проверьте интернет и повторите.',
    'Gemini қызметіне қосылу мүмкін болмады. интернетті тексеріп, қайталаңыз.',
  ],
  'Gemini returned unreadable data. Please retry.': [
    'Gemini вернул нечитаемые данные. повторите попытку.',
    'Gemini оқылмайтын деректерді қайтарды. қайталаңыз.',
  ],
  'Could not read the audio. Select the file again.': [
    'не удалось прочитать аудио. выберите файл снова.',
    'аудионы оқу мүмкін болмады. файлды қайта таңдаңыз.',
  ],
  'Gemini could not process this audio. Try another clip.': [
    'Gemini не смог обработать аудио. попробуйте другой файл.',
    'Gemini аудионы өңдей алмады. басқа файлды көріңіз.',
  ],
  'Gemini did not return a complete result. Try a shorter clip.': [
    'Gemini вернул неполный результат. попробуйте более короткое аудио.',
    'Gemini толық нәтиже қайтармады. қысқа аудионы көріңіз.',
  ],
  'Gemini returned an invalid result. Please retry.': [
    'Gemini вернул некорректный результат. повторите попытку.',
    'Gemini қате нәтиже қайтарды. қайталаңыз.',
  ],
  'No complete transcript received. Try a shorter clip with clear speech.': [
    'не удалось получить полный текст. попробуйте более короткое аудио с чёткой речью.',
    'толық мәтін алынбады. анық сөйленген қысқа аудионы көріңіз.',
  ],
  'No clear speech found. Try another recording.': [
    'разборчивая речь не найдена. попробуйте другое аудио.',
    'анық сөйлеу табылмады. басқа аудионы көріңіз.',
  ],
};
