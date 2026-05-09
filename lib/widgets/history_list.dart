// lib/widgets/history_list.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/nmea_sentence.dart';

class HistoryList extends StatelessWidget {
  final List<TransmissionResult> history;

  const HistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text('Noch keine Daten übertragen',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final result = history[index];
        return _HistoryTile(result: result);
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransmissionResult result;
  const _HistoryTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSuccess = result.status == TransmissionStatus.success;
    final isError = result.status == TransmissionStatus.error;

    final color = isSuccess
        ? const Color(0xFF34A853)
        : isError
            ? cs.error
            : cs.primary;

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(
            ClipboardData(text: result.sentence.rawSentence));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('In Zwischenablage kopiert')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : isError
                      ? Icons.error_rounded
                      : Icons.sync_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.sentence.rawSentence,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: cs.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isError && result.errorMessage != null)
                    Text(result.errorMessage!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.error)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatTime(result.time),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
