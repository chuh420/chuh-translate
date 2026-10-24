import 'strings.dart';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/gemini.dart';
import 'common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});
  final AppState state;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final keyInput = TextEditingController();
  bool visible = false;
  @override
  void dispose() {
    keyInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    return PageBody(
      children: [
        AppText('make it yours.', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        const AppText('your key, your languages, your device.'),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.key_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      'Gemini API key',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (state.hasKey)
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AppText(
                state.hasKey
                    ? 'a key is saved in secure device storage. enter a new key to replace it.'
                    : 'paste your own key from Google AI Studio. the app does not include a shared key.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                'aistudio.google.com/apikey',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyInput,
                obscureText: !visible,
                enabled: !state.savingKey && !state.busy,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [],
                textCapitalization: TextCapitalization.none,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.tr(
                    state.hasKey ? 'replacement key' : 'API key',
                  ),
                  suffixIcon: IconButton(
                    tooltip: context.tr(visible ? 'hide key' : 'show key'),
                    onPressed: () => setState(() => visible = !visible),
                    icon: Icon(
                      visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    state.savingKey ||
                        state.busy ||
                        keyInput.text.trim().isEmpty
                    ? null
                    : () async {
                        if (await state.saveKey(keyInput.text) && mounted) {
                          keyInput.clear();
                          setState(() => visible = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: AppText(
                                  'API key saved on this device',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: AppText(state.savingKey ? 'saving…' : 'save key'),
              ),
              if (state.hasKey)
                TextButton(
                  onPressed: state.savingKey || state.busy
                      ? null
                      : () async {
                          if (await confirm(
                            context,
                            'remove API key?',
                            'You can keep reading saved translations. Add a key again to process new audio.',
                            'remove key',
                          )) {
                            await state.deleteKey();
                          }
                        },
                  child: const AppText('remove saved key'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText('interface language', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(state.uiLanguage),
                initialValue: state.uiLanguage,
                decoration: InputDecoration(
                  labelText: context.tr('interface language'),
                ),
                items: const [
                  DropdownMenuItem(value: 'ru', child: Text('русский')),
                  DropdownMenuItem(value: 'kk', child: Text('қазақша')),
                  DropdownMenuItem(value: 'en', child: Text('english')),
                ],
                onChanged: (value) {
                  if (value != null) state.setUiLanguage(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText('appearance', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<ThemeMode>(
                key: ValueKey(state.theme),
                initialValue: state.theme,
                decoration: InputDecoration(labelText: context.tr('theme')),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: AppText('follow system'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: AppText('light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: AppText('dark'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) state.setTheme(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('data & privacy', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              const AppText(
                'audio goes from your device to Google Gemini for processing. Google handles it under the terms for your API account. API usage can incur charges.',
              ),
              const SizedBox(height: 12),
              const AppText(
                'history stores text on this device. temporary audio stays in the app cache until you replace or remove it; Android may clear it. the app does not back up your key or history.',
              ),
              const SizedBox(height: 12),
              const AppText(
                'for larger files, the app requests deletion of the uploaded copy after processing. if deletion fails, Google expires Files API uploads after 48 hours.',
              ),
              const SizedBox(height: 16),
              AppText(
                'model: ${GeminiService.model}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('about', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text('chuh translate · 1.0.1'),
              const SizedBox(height: 8),
              SelectableText(
                'Telegram · @chuh420',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
