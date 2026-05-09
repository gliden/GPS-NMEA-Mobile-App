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
  late TextEditingController _nameController;
  late int _interval;

  @override
  void initState() {
    super.initState();
    final vm = context.read<TrackerViewModel>();
    _urlController = TextEditingController(text: vm.endpointUrl);
    _nameController = TextEditingController(text: vm.deviceName);
    _interval = vm.intervalSeconds;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Gerätename eingeben')),
      );
      return;
    }

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

    final error = await context.read<TrackerViewModel>().saveSettings(
          url: url,
          intervalSeconds: _interval,
          deviceName: name,
        );

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Einstellungen gespeichert')),
        );
        Navigator.pop(context);
      }
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
          // ── Gerätename ─────────────────────────────────────────────────
          Text('Gerätename', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Mein GPS Tracker',
              prefixIcon: const Icon(Icons.device_thermostat),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: 24),

          // ── Seriennummer (Read-Only) ────────────────────────────────────
          Text('Geräteseriennummer', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Consumer<TrackerViewModel>(
            builder: (context, vm, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vm.serialNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

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
