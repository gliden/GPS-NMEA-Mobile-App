// lib/views/tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tracker_viewmodel.dart';
import '../widgets/status_card.dart';
import '../widgets/history_list.dart';
import 'settings_screen.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  Future<void> _toggleTracking(
      BuildContext context, TrackerViewModel vm) async {
    if (vm.isTracking) {
      await vm.stopTracking();
    } else {
      final error = await vm.startTracking();
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        centerTitle: false,
        title: const _AppTitle(),
        actions: [
          if (vm.history.isNotEmpty)
            IconButton(
              tooltip: 'Verlauf löschen',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: vm.clearHistory,
            ),
          IconButton(
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StatusCard(
              isTracking: vm.isTracking,
              status: vm.transmissionStatus,
              lastSentence: vm.lastSentence,
              lastError: vm.lastError,
            ),
          ),

          // ── Endpunkt-Info ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Icon(Icons.link, size: 14, color: cs.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vm.endpointUrl,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${vm.intervalSeconds}s',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // ── Verlauf ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              'Übertragungsverlauf',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.outline, letterSpacing: 0.8),
            ),
          ),
          Expanded(
            child: HistoryList(history: vm.history),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _toggleTracking(context, vm),
        backgroundColor:
            vm.isTracking ? cs.errorContainer : cs.primaryContainer,
        foregroundColor:
            vm.isTracking ? cs.onErrorContainer : cs.onPrimaryContainer,
        icon: Icon(
            vm.isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded),
        label: Text(vm.isTracking ? 'Stoppen' : 'Tracking starten'),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.satellite_alt_rounded,
            color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        const Text('GPS NMEA Tracker',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
