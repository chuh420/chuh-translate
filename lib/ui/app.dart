import 'strings.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../app_state.dart';
import 'common.dart';
import 'translate_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
export 'common.dart' show appTheme;

class VoiceTextApp extends StatelessWidget {
  const VoiceTextApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => MaterialApp(
      title: 'chuh translate',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: state.theme,
      locale: Locale(state.uiLanguage),
      supportedLocales: const [Locale('ru'), Locale('kk'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AppShell(state: state),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int tab = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    if (value == AppLifecycleState.paused && widget.state.recording) {
      unawaited(widget.state.stopRecording());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return PopScope(
      canPop: !state.recording && !state.busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AppText(
                'stop recording or cancel processing before leaving.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppText(['chuh translate', 'history', 'settings'][tab]),
          actions: [
            if (tab == 0)
              IconButton(
                tooltip: context.tr('settings'),
                onPressed: () => setState(() => tab = 2),
                icon: const Icon(Icons.tune_rounded),
              ),
            if (tab == 1 && state.history.isNotEmpty)
              IconButton(
                tooltip: context.tr('clear history'),
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () async {
                  if (await confirm(
                    context,
                    'clear history?',
                    'This deletes all saved transcripts and translations from this device.',
                    'delete all',
                  )) {
                    await state.clearHistory();
                  }
                },
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                state.error!,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: context.tr('dismiss error'),
                              onPressed: state.clearError,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: tab,
                  children: [
                    TranslatePage(
                      state: state,
                      openSettings: () => setState(() => tab = 2),
                    ),
                    HistoryPage(state: state),
                    SettingsPage(state: state),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() => tab = value);
            if (value == 1) unawaited(state.refreshHistory());
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.mic_none_rounded),
              selectedIcon: Icon(Icons.mic_rounded),
              label: context.tr('translate'),
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              label: context.tr('history'),
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: context.tr('settings'),
            ),
          ],
        ),
      ),
    );
  }
}
