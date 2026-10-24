import 'strings.dart';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/translation.dart';
import 'common.dart';

class TranslatePage extends StatelessWidget {
  const TranslatePage({
    super.key,
    required this.state,
    required this.openSettings,
  });
  final AppState state;
  final VoidCallback openSettings;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageBody(
      children: [
        AppText(
          'speech, in your words.',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        AppText(
          'record or upload audio. get the transcript and a translation together.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (!state.hasKey) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'bring your Gemini key',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const AppText(
                  'add your own API key to start. you control the key and your Google API usage.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: openSettings,
                  icon: const Icon(Icons.key_outlined),
                  label: const AppText('set up API key'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              LanguageField(
                label: 'spoken language',
                value: state.source,
                automatic: true,
                enabled: !state.locked,
                onChanged: (v) => state.setLanguage(from: v),
              ),
              LanguageField(
                label: 'translate to',
                value: state.target,
                automatic: false,
                enabled: !state.locked,
                onChanged: (v) => state.setLanguage(to: v),
              ),
            ];
            if (constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(16) > 23) {
              return Column(
                children: [fields[0], const SizedBox(height: 12), fields[1]],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 12),
                Expanded(child: fields[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    state.recording
                        ? Icons.mic_rounded
                        : Icons.audio_file_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      state.recording
                          ? 'recording'
                          : state.audio != null
                          ? 'audio ready'
                          : 'add your audio',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (state.audio != null && !state.locked)
                    IconButton(
                      tooltip: context.tr('remove audio'),
                      onPressed: state.clearAudio,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (state.recording) ...[
                AppText(
                  state.durationLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                const AppText(
                  'recording stops after 10 minutes or when you leave the app.',
                  textAlign: TextAlign.center,
                ),
              ] else if (state.audio != null) ...[
                Text(
                  state.audioName!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AppText(
                  state.sizeLabel,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ] else
                const AppText(
                  'use your microphone or choose a file from your device. up to 100 MB.',
                ),
              const SizedBox(height: 20),
              if (state.recording)
                FilledButton.icon(
                  onPressed: state.workingWithAudio
                      ? null
                      : state.stopRecording,
                  icon: const Icon(Icons.stop_rounded),
                  label: const AppText('stop recording'),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: state.locked ? null : state.pickAudio,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const AppText('choose file'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.locked ? null : state.startRecording,
                      icon: const Icon(Icons.mic_rounded),
                      label: AppText(
                        state.audio != null ? 'record again' : 'record audio',
                      ),
                    ),
                  ],
                ),
              if (state.workingWithAudio) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (state.busy)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                AppText(state.status, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: state.cancel,
                  child: const AppText('cancel processing'),
                ),
              ],
            ),
          )
        else
          FilledButton.icon(
            onPressed: state.audio != null && !state.locked && state.hasKey
                ? state.process
                : null,
            icon: const Icon(Icons.translate_rounded),
            label: const AppText('transcribe & translate'),
          ),
        const SizedBox(height: 10),
        AppText(
          'audio is sent to Google Gemini only when you tap translate. internet required. API charges may apply.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.result != null) ...[
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: AppText(
                  'your result',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () => copyText(
                  context,
                  '${state.result!.original}\n\n${state.result!.translated}',
                ),
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const AppText('copy both'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultCards(
            result: state.result!,
            target: state.resultTarget ?? state.target,
          ),
          if (state.unsaved != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: state.savingResult ? null : state.saveResult,
                icon: const Icon(Icons.save_outlined),
                label: const AppText('retry saving to history'),
              ),
            ),
          const SizedBox(height: 12),
          AppText(
            state.unsaved == null
                ? 'saved on this device. review names and important details for accuracy.'
                : 'not saved yet. copy this result before leaving.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class LanguageField extends StatelessWidget {
  const LanguageField({
    super.key,
    required this.label,
    required this.value,
    required this.automatic,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final String value;
  final bool automatic;
  final bool enabled;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.tr(label)),
    items: languages.entries
        .where((entry) => automatic || entry.key != 'auto')
        .map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: AppText(entry.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: enabled
        ? (value) {
            if (value != null) onChanged(value);
          }
        : null,
  );
}
