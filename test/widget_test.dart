import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicetext/models/translation.dart';
import 'package:voicetext/app_state.dart';
import 'package:voicetext/services/storage.dart';
import 'package:voicetext/ui/app.dart';

class EmptyHistory extends HistoryStore {
  EmptyHistory() : super(_UnusedDatabase());
  @override
  Future<List<Translation>> list() async => [];
}

class _UnusedDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (call) async => null,
      );
  testWidgets('small screen navigates to settings and empty offline history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'ui_language': 'en'});
    final history = EmptyHistory();
    final state = AppState(
      historyStore: history,
      preferences: Preferences(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(VoiceTextApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('speech, in your words.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('set up API key'));
    await tester.pumpAndSettle();
    expect(find.text('Gemini API key'), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'save key'),
    );
    expect(save.onPressed, isNull);
    await tester.tap(find.text('history').last);
    await tester.pumpAndSettle();
    expect(find.text('your words, kept here.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('dark theme fits a narrow display', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'theme': 'dark',
      'ui_language': 'en',
    });
    final history = EmptyHistory();
    final state = AppState(
      historyStore: history,
      preferences: Preferences(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(VoiceTextApp(state: state));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Russian is default; Kazakh and English apply without restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = Preferences(await SharedPreferences.getInstance());
    final state = AppState(historyStore: EmptyHistory(), preferences: prefs);
    await tester.pumpWidget(VoiceTextApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('из аудио в текст.'), findsOneWidget);
    expect(find.text('перевод'), findsOneWidget);
    await state.setUiLanguage('kk');
    await tester.pumpAndSettle();
    expect(find.text('аудиодан мәтінге.'), findsOneWidget);
    expect(prefs.uiLanguage, 'kk');
    await state.setUiLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('speech, in your words.'), findsOneWidget);
    expect(prefs.uiLanguage, 'en');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
