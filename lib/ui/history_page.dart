import 'strings.dart';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/translation.dart';
import 'common.dart';

String dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    if (state.loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(state.historyError!),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: state.refreshHistory,
                child: const AppText('retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              AppText(
                'your words, kept here.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const AppText(
                'completed transcripts and translations appear here. you can read and copy them offline.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: RefreshIndicator(
          onRefresh: state.refreshHistory,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: state.history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.history[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryDetail(item: item, state: state),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${item.result.language} → ${languages[item.target] ?? item.target}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.result.translated,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          dateLabel(item.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HistoryDetail extends StatelessWidget {
  const HistoryDetail({super.key, required this.item, required this.state});
  final Translation item;
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const AppText('saved translation'),
      actions: [
        IconButton(
          tooltip: context.tr('delete translation'),
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () async {
            if (await confirm(
              context,
              'delete translation?',
              'This removes the transcript and translation from your history.',
              'delete',
            )) {
              await state.removeHistory(item.id!);
              if (context.mounted &&
                  !state.history.any((value) => value.id == item.id)) {
                Navigator.pop(context);
              }
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: PageBody(
        children: [
          AppText(
            dateLabel(item.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(item.filename),
          const SizedBox(height: 20),
          ResultCards(result: item.result, target: item.target),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => copyText(
              context,
              '${item.result.original}\n\n${item.result.translated}',
            ),
            icon: const Icon(Icons.copy_all_outlined),
            label: const AppText('copy both'),
          ),
        ],
      ),
    ),
  );
}
