// Placeholder Fase 0 untuk 4 tab non-Beranda (ui.md §3).
// Memberi konteks + rencana Fase 1, dengan jalan kembali yang aman.
import 'package:flutter/material.dart';

import '../theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String headline;
  final String body;
  final List<String> nextUp;
  final VoidCallback onBackToHome;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.headline,
    required this.body,
    required this.nextUp,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SovereignSpacing.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SovereignColors.blueSlate,
                borderRadius: BorderRadius.circular(SovereignSpacing.radius),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0x1436C5F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SovereignColors.border),
                    ),
                    child: Icon(icon, color: SovereignColors.cyan, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(title,
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 4),
                  Text(headline,
                      style: const TextStyle(
                          color: SovereignColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.25)),
                  const SizedBox(height: 8),
                  Text(body,
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 14,
                          height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SovereignColors.blueSlate,
                borderRadius: BorderRadius.circular(SovereignSpacing.radius),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: SovereignColors.amber, size: 18),
                      SizedBox(width: 8),
                      Text('Rencana Fase 1',
                          style: TextStyle(
                              color: SovereignColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final item in nextUp)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.fiber_manual_record,
                                color: SovereignColors.cyan, size: 8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item,
                                style: const TextStyle(
                                    color: SovereignColors.muted,
                                    fontSize: 13,
                                    height: 1.45)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: SovereignSpacing.touchMin,
              child: OutlinedButton.icon(
                onPressed: onBackToHome,
                icon: const Icon(Icons.home_outlined, size: 20),
                label: const Text('Kembali ke Beranda'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Navigasi kembali selalu aman — draf kebijakan tidak hilang saat pindah tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SovereignColors.mutedDim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
