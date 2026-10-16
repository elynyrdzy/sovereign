// Anggaran rinci SOVEREIGN — read-only dari GameController (ui.md §4.8).
// Baris 44–56dp: belanja (G), penerimaan estimasi, defisit estimasi,
// utang nominal + rasio. Alokasi sektor TIDAK dibuat-buat: sim Fase 0
// hanya mencatat total G, jadi tampilkan total + catatan jujur.
// Penerimaan = tarif pajak × GDP (estimasi UI, bukan ledger sim).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/game_controller.dart';
import '../theme.dart';
import 'format.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final history = controller.history;

    final revenue = s.taxRate * s.gdp;
    final deficit = s.govSpending - revenue;
    final isDeficit = deficit >= 0;
    final debtNominal = s.debtToGdp * s.gdp;
    final gShare = s.gdp == 0 ? 0.0 : s.govSpending / s.gdp;

    final series = [...history, s];
    final recent = series.length <= 6
        ? series.reversed.toList()
        : series.sublist(series.length - 6).reversed.toList();

    return Scaffold(
      backgroundColor: SovereignColors.deepNavy,
      appBar: AppBar(
        backgroundColor: SovereignColors.deepNavy,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anggaran rinci',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Penerimaan vs belanja • read-only',
                style: TextStyle(color: SovereignColors.muted, fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              SovereignSpacing.margin, 12, SovereignSpacing.margin, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SovereignColors.blueSlate,
                borderRadius:
                    BorderRadius.circular(SovereignSpacing.radius),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x1436C5F0),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: SovereignColors.border),
                        ),
                        child: Text(formatQuarter(s.quarter),
                            style: const TextStyle(
                                color: SovereignColors.cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isDeficit
                              ? 'Defisit ${formatCompactUsd(deficit)}'
                              : 'Surplus ${formatCompactUsd(deficit.abs())}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDeficit
                                ? SovereignColors.red
                                : SovereignColors.green,
                          ),
                        ),
                      ),
                      Icon(
                        isDeficit
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        color: isDeficit
                            ? SovereignColors.red
                            : SovereignColors.green,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Belanja ${formatCompactUsd(s.govSpending)} vs penerimaan estimasi ${formatCompactUsd(revenue)}. '
                    'Belanja = ${(gShare * 100).toStringAsFixed(1).replaceAll('.', ',')}% dari GDP.',
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'BARIS ANGGARAN • 44–56 DP',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            _BudgetRow(
              label: 'Belanja negara (G)',
              value: formatCompactUsd(s.govSpending),
              sub:
                  '${(gShare * 100).toStringAsFixed(1).replaceAll('.', ',')}% dari GDP • komponen G',
            ),
            _BudgetRow(
              label: 'Penerimaan pajak (estimasi)',
              value: formatCompactUsd(revenue),
              sub:
                  'Pajak ${formatPercent(s.taxRate)} × GDP — estimasi UI, bukan ledger sim',
            ),
            _BudgetRow(
              label: isDeficit ? 'Defisit (estimasi)' : 'Surplus (estimasi)',
              value:
                  '${isDeficit ? '−' : '+'}${formatCompactUsd(deficit.abs())}',
              sub: 'Belanja − penerimaan • bertambah ke utang bila defisit',
              tone: isDeficit
                  ? SovereignStatus.bad
                  : SovereignStatus.good,
            ),
            _BudgetRow(
              label: 'Utang nominal (estimasi)',
              value: formatCompactUsd(debtNominal),
              sub: 'Rasio × GDP • bukan kas terpisah',
            ),
            _BudgetRow(
              label: 'Rasio utang / GDP',
              value: formatDebtRatio(s.debtToGdp),
              sub: s.debtToGdp < 0.45
                  ? 'Ringan • di bawah 45%'
                  : s.debtToGdp < 0.6
                      ? 'Waspada • 45–60%'
                      : 'Berat • di atas 60%',
              tone: s.debtToGdp < 0.45
                  ? SovereignStatus.good
                  : s.debtToGdp < 0.6
                      ? SovereignStatus.warn
                      : SovereignStatus.bad,
            ),
            _BudgetRow(
              label: 'Tarif pajak aktual',
              value: formatPercent(s.taxRate),
              sub: 'Menekan konsumsi, menaikkan penerimaan',
            ),
            const SizedBox(height: 14),
            const Text(
              'ALOKASI SEKTOR • READ-ONLY',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SovereignColors.deepNavySoft,
                borderRadius:
                    BorderRadius.circular(SovereignSpacing.radius),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0x1436C5F0),
                          borderRadius: BorderRadius.circular(11),
                          border:
                              Border.all(color: SovereignColors.border),
                        ),
                        child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: SovereignColors.cyan,
                            size: 20),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total belanja negara',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${formatCompactUsd(s.govSpending)} • ${formatQuarter(s.quarter)}',
                              style: const TextStyle(
                                  color: SovereignColors.muted,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFBBF24),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0x33FBBF24)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: SovereignColors.amber, size: 17),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rincian sektor (pendidikan, kesehatan, infrastruktur, dll) belum ada di sim — sim Fase 0 hanya mencatat total G. Angka sektor tidak dibuat-buat agar tidak menipu.',
                            style: TextStyle(
                                color: SovereignColors.muted,
                                fontSize: 12,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'TREN • DARI HISTORY',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SovereignColors.blueSlate,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SovereignColors.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.timeline_rounded,
                        color: SovereignColors.muted, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kuartal awal — tren muncul setelah Proses Kuartal pertama. Defisit tiap baris dihitung sama: belanja − (pajak × GDP).',
                        style: TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final q in recent)
                _BudgetRow(
                  label: q.quarter == s.quarter
                      ? 'K${q.quarter} • berjalan'
                      : 'K${q.quarter}',
                  value: formatCompactUsd(q.govSpending),
                  sub:
                      'Defisit ${_signedMoney(q.govSpending - q.taxRate * q.gdp)} • utang ${formatDebtRatio(q.debtToGdp)}',
                  dense: true,
                ),
            const SizedBox(height: 12),
            const Text(
              'Metode jujur: penerimaan & defisit adalah estimasi UI (pajak × GDP). Sim tidak punya ledger penerimaan/defisit terpisah — utang bergerak via rasio utang/GDP. Layar ini read-only, tidak mengubah sim.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 12,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  static String _signedMoney(double d) {
    if (d == 0) return 'impas';
    final sign = d >= 0 ? '−' : '+';
    return '$sign${formatCompactUsd(d.abs())}';
  }
}

/// Baris anggaran 44–56dp: label + nilai, sub-metode satu baris.
class _BudgetRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final SovereignStatus? tone;
  final bool dense;
  const _BudgetRow({
    required this.label,
    required this.value,
    this.sub = '',
    this.tone,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = tone;
    return Container(
      constraints: const BoxConstraints(minHeight: 44, maxHeight: 56),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        children: [
          if (t != null) ...[
            Icon(t.icon, size: 16, color: t.color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: dense
                            ? SovereignColors.ink
                            : SovereignColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (sub.trim().isNotEmpty)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t?.color ?? SovereignColors.mutedDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
