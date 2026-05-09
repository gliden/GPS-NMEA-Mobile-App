// lib/widgets/status_card.dart

import 'package:flutter/material.dart';
import '../models/nmea_sentence.dart';

class StatusCard extends StatelessWidget {
  final bool isTracking;
  final TransmissionStatus status;
  final GprmcSentence? lastSentence;
  final String? lastError;

  const StatusCard({
    super.key,
    required this.isTracking,
    required this.status,
    this.lastSentence,
    this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _StatusDot(status: status, isTracking: isTracking),
                const SizedBox(width: 10),
                Text(
                  _statusLabel(isTracking, status),
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _statusColor(cs, isTracking, status),
                  ),
                ),
              ],
            ),

            if (lastSentence != null) ...[
              const Divider(height: 24),
              _DataRow(
                icon: Icons.location_on_rounded,
                label: 'Position',
                value:
                    '${lastSentence!.latitude.toStringAsFixed(6)}°, ${lastSentence!.longitude.toStringAsFixed(6)}°',
              ),
              const SizedBox(height: 8),
              _DataRow(
                icon: Icons.speed_rounded,
                label: 'Geschwindigkeit',
                value: '${lastSentence!.speedKnots.toStringAsFixed(2)} kn',
              ),
              const SizedBox(height: 8),
              _DataRow(
                icon: Icons.explore_rounded,
                label: 'Kurs',
                value: '${lastSentence!.courseDegrees.toStringAsFixed(1)}°',
              ),
              const SizedBox(height: 12),
              // Raw NMEA
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  lastSentence!.rawSentence,
                  style: tt.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            if (lastError != null && status == TransmissionStatus.error) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded,
                        size: 16, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastError!,
                        style:
                            tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(bool tracking, TransmissionStatus s) {
    if (!tracking) return 'Inaktiv';
    switch (s) {
      case TransmissionStatus.idle:
        return 'Warte auf GPS…';
      case TransmissionStatus.sending:
        return 'Sende…';
      case TransmissionStatus.success:
        return 'Übertragen';
      case TransmissionStatus.error:
        return 'Fehler';
    }
  }

  Color _statusColor(ColorScheme cs, bool tracking, TransmissionStatus s) {
    if (!tracking) return cs.outline;
    switch (s) {
      case TransmissionStatus.idle:
        return cs.secondary;
      case TransmissionStatus.sending:
        return cs.primary;
      case TransmissionStatus.success:
        return const Color(0xFF34A853);
      case TransmissionStatus.error:
        return cs.error;
    }
  }
}

class _StatusDot extends StatelessWidget {
  final TransmissionStatus status;
  final bool isTracking;
  const _StatusDot({required this.status, required this.isTracking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color color;
    if (!isTracking) {
      color = cs.outline;
    } else if (status == TransmissionStatus.success) {
      color = const Color(0xFF34A853);
    } else if (status == TransmissionStatus.error) {
      color = cs.error;
    } else {
      color = cs.primary;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isTracking
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
            : null,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DataRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: tt.bodySmall?.copyWith(color: cs.outline)),
        Expanded(
          child: Text(value,
              style:
                  tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
