// lib/views/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tracker_viewmodel.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late int _interval;

  @override
  void initState() {
    super.initState();
    final vm = context.read<TrackerViewModel>();
    _urlController = TextEditingController(text: vm.endpointUrl);
    _interval = vm.intervalSeconds;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine URL eingeben')),
      );
      return;
    }
    try {
      Uri.parse(url); // Validierung
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültige URL')),
      );
      return;
    }

    await context.read<TrackerViewModel>().saveSettings(
          url: url,
          intervalSeconds: _interval,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: cs.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Endpoint URL ─────────────────────────────────────────────────
          Text('HTTP-Endpunkt', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'http://192.168.1.1:8080/gps',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: 32),

          // ── Sendeintervall ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sendeintervall', style: Theme.of(context).textTheme.labelLarge),
              Chip(
                label: Text('$_interval Sek.'),
                backgroundColor: cs.primaryContainer,
                labelStyle: TextStyle(color: cs.onPrimaryContainer),
              ),
            ],
          ),
          Slider(
            value: _interval.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '$_interval s',
            onChanged: (v) => setState(() => _interval = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 Sek.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
              Text('60 Sek.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
            ],
          ),

          const SizedBox(height: 16),

          // ── Datenschutzrichtlinie ────────────────────────────────────────
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            icon: const Icon(Icons.privacy_tip_rounded),
            label: const Text('Datenschutzrichtlinie'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 32),

          // ── Speichern ────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Speichern'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
