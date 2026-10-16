// Bottom-sheet konfirmasi reusable SOVEREIGN (ui.md §4.7).
// Kini vs baru, dampak +/-, biaya, Konfirmasi/Batal >=48dp.
// Murni UI: tanpa mutasi sim; pemanggil yang memanggil controller.
import 'package:flutter/material.dart';

import '../theme.dart';

/// Satu baris perbandingan: nilai kini vs nilai baru.
class ConfirmComparison {
  final String label;
  final String before;
  final String after;
  const ConfirmComparison({
    required this.label,
    required this.before,
    required this.after,
  });
}

/// Satu baris dampak kualitatif (+/-). Tone memakai SovereignStatus
/// agar tidak hanya warna: ikon + label selalu ikut.
class ConfirmImpact {
  final String text;
  final SovereignStatus tone;
  const ConfirmImpact({required this.text, this.tone = SovereignStatus.neutral});
}

/// Tampilkan bottom-sheet konfirmasi. Kembalikan true bila dikonfirmasi.
Future<bool> showSovereignConfirmSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  List<ConfirmComparison> comparisons = const [],
  List<ConfirmImpact> impacts = const [],
  String? costText,
  String confirmLabel = 'Konfirmasi',
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SovereignConfirmSheet(
      title: title,
      subtitle: subtitle,
      comparisons: comparisons,
      impacts: impacts,
      costText: costText,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result == true;
}

/// Isi bottom-sheet; dipakai langsung oleh showSovereignConfirmSheet.
/// Bisa juga dipakai sebagai widget halaman penuh bila konsekuensi banyak.
class SovereignConfirmSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ConfirmComparison> comparisons;
  final List<ConfirmImpact> impacts;
  final String? costText;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const SovereignConfirmSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.comparisons = const [],
    this.impacts = const [],
    this.costText,
    this.confirmLabel = 'Konfirmasi',
    this.cancelLabel = 'Batal',
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasComparison = comparisons.isNotEmpty;
    final hasImpacts = impacts.isNotEmpty;
    final cost = (costText ?? '').trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: destructive
                        ? const Color(0x14F87171)
                        : const Color(0x1436C5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SovereignColors.border),
                  ),
                  child: Icon(
                    destructive
                        ? Icons.warning_amber_rounded
                        : Icons.fact_check_outlined,
                    color: destructive
                        ? SovereignColors.red
                        : SovereignColors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!.trim(),
                          style: const TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!hasComparison && !hasImpacts && cost.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SovereignColors.deepNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SovereignColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: SovereignColors.muted, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tidak ada perubahan tercatat.',
                        style: TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (hasComparison) ...[
              const Text(
                'KINI VS BARU',
                style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              for (final c in comparisons)
                _CompareRow(comparison: c),
            ],
            if (hasImpacts) ...[
              SizedBox(height: hasComparison ? 12 : 0),
              const Text(
                'ESTIMASI DAMPAK',
                style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SovereignColors.deepNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SovereignColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < impacts.length; i++) ...[
                      _ImpactRow(impact: impacts[i]),
                      if (i != impacts.length - 1)
                        const Divider(
                          color: SovereignColors.border,
                          height: 1,
                        ),
                    ],
                  ],
                ),
              ),
            ],
            if (cost.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x0FFBBF24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x33FBBF24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: SovereignColors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biaya langsung & fiskal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cost,
                            style: const TextStyle(
                              color: SovereignColors.muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: SovereignSpacing.processButtonHeight,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: destructive
                      ? SovereignColors.amber
                      : SovereignColors.green,
                  foregroundColor: SovereignColors.deepNavy,
                ),
                child: Text(confirmLabel),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: SovereignSpacing.touchMin,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Konfirmasi mengunci pilihan untuk giliran berikutnya. Batal kembali tanpa mengubah keputusan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SovereignColors.mutedDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final ConfirmComparison comparison;
  const _CompareRow({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final before = comparison.before.trim().isEmpty
        ? '—'
        : comparison.before.trim();
    final after =
        comparison.after.trim().isEmpty ? '—' : comparison.after.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comparison.label.trim().isEmpty ? 'Keputusan' : comparison.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SovereignColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kini',
                      style: TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      before,
                      style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: SovereignColors.mutedDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: SovereignColors.cyan,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Baru',
                      style: TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      after,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final ConfirmImpact impact;
  const _ImpactRow({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(impact.tone.icon, size: 17, color: impact.tone.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              impact.text,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            impact.tone.label,
            style: TextStyle(
              color: impact.tone.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
