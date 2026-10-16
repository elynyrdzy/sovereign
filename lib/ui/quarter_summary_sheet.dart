// Ringkasan akhir kuartal SOVEREIGN (ui.md §4.8).
// Baris indikator 44–56dp sebelum→sesudah, kartu kejadian + penyebab,
// tombol Lanjutkan 52dp. Dipakai dashboard setelah Proses Kuartal.
// Defensif: lookup event/commodity dinamis, fallback bila field kosong
// (sim boleh tambah negara/komoditas/event secara aditif).
import 'package:flutter/material.dart';

import '../models/game_event.dart';
import '../models/result.dart';
import '../theme.dart';
import 'format.dart';

/// Tampilkan ringkasan akhir kuartal sebagai modal bottom-sheet.
/// [allEvents] untuk memetakan id → nama + penyebab; bila kosong/tak cocok,
/// tampilkan id cantik + catatan defensif (bukan crash).
Future<void> showQuarterSummarySheet(
  BuildContext context,
  QuarterResult result, {
  List<GameEvent> allEvents = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => QuarterSummarySheet(
      result: result,
      allEvents: allEvents,
    ),
  );
}

class QuarterSummarySheet extends StatelessWidget {
  final QuarterResult result;
  final List<GameEvent> allEvents;
  const QuarterSummarySheet({
    super.key,
    required this.result,
    this.allEvents = const [],
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final byId = {for (final e in allEvents) e.id: e};

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1422C55E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'K${r.prev.quarter} → K${r.next.quarter}',
                    style: const TextStyle(
                      color: SovereignColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ringkasan akhir kuartal',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Perubahan sebelum → sesudah simulasi, bukan ulangan dashboard.',
              style: TextStyle(
                color: SovereignColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'INDIKATOR • SEBELUM → SESUDAH',
              style: TextStyle(
                color: SovereignColors.mutedDim,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'GDP',
              before: formatCompactUsd(r.prev.gdp),
              after: formatCompactUsd(r.next.gdp),
              sub: _gdpSub(r.prev.gdp, r.next.gdp),
            ),
            _SummaryRow(
              label: 'Inflasi',
              before: formatPercent(r.prev.inflation),
              after: formatPercent(r.next.inflation),
              sub: _ppSub(r.next.inflation - r.prev.inflation),
              tone: _inflationTone(r.next.inflation),
            ),
            _SummaryRow(
              label: 'Pengangguran',
              before: formatPercent(r.prev.unemployment),
              after: formatPercent(r.next.unemployment),
              sub: _ppSub(r.next.unemployment - r.prev.unemployment),
              tone: _unempTone(r.next.unemployment),
            ),
            _SummaryRow(
              label: 'Devisa',
              before: formatCompactUsd(r.prev.fxReserves),
              after: formatCompactUsd(r.next.fxReserves),
              sub: _moneySub(r.next.fxReserves - r.prev.fxReserves),
              tone: _fxTone(r.next.fxReserves),
            ),
            _SummaryRow(
              label: 'Utang / GDP',
              before: formatDebtRatio(r.prev.debtToGdp),
              after: formatDebtRatio(r.next.debtToGdp),
              sub: _ppSub(r.next.debtToGdp - r.prev.debtToGdp),
              tone: _debtTone(r.next.debtToGdp),
            ),
            _SummaryRow(
              label: 'Konsumsi',
              before: formatCompactUsd(r.prev.consumption),
              after: formatCompactUsd(r.next.consumption),
              sub: _moneySub(r.next.consumption - r.prev.consumption),
            ),
            _SummaryRow(
              label: 'Investasi',
              before: formatCompactUsd(r.prev.investment),
              after: formatCompactUsd(r.next.investment),
              sub: _moneySub(r.next.investment - r.prev.investment),
            ),
            if (r.triggeredEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'KEJADIAN & PENYEBAB',
                style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              for (final id in r.triggeredEvents)
                _EventCauseCard(
                  eventId: id,
                  event: byId[id],
                ),
            ],
            if (r.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x0FFBBF24),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0x33FBBF24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: SovereignColors.amber, size: 17),
                        SizedBox(width: 8),
                        Text(
                          'Perhatian kuartal ini',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final w in r.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(Icons.fiber_manual_record,
                                  color: SovereignColors.amber,
                                  size: 7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w.trim().isEmpty ? '—' : w,
                                style: const TextStyle(
                                  color: SovereignColors.muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (r.triggeredEvents.isEmpty && r.warnings.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x0F22C55E),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0x3322C55E)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: SovereignColors.green, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kuartal tenang — tidak ada kejadian atau peringatan.',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _gdpSub(double prev, double next) {
    if (prev == 0) return 'Kuartal awal';
    final g = (next - prev) / prev;
    final sign = g >= 0 ? '+' : '';
    return '$sign${(g * 100).toStringAsFixed(1).replaceAll('.', ',')}% pertumbuhan';
  }

  static String _ppSub(double d) {
    final sign = d >= 0 ? '+' : '';
    return '$sign${(d * 100).toStringAsFixed(1).replaceAll('.', ',')} pp';
  }

  static String _moneySub(double d) {
    if (d == 0) return 'Tidak berubah';
    final sign = d >= 0 ? '+' : '−';
    return '$sign${formatCompactUsd(d.abs())} QoQ';
  }

  static SovereignStatus _inflationTone(double v) {
    if (v < 0.04) return SovereignStatus.good;
    if (v < 0.06) return SovereignStatus.warn;
    return SovereignStatus.bad;
  }

  static SovereignStatus _unempTone(double v) {
    if (v < 0.06) return SovereignStatus.good;
    if (v < 0.08) return SovereignStatus.warn;
    return SovereignStatus.bad;
  }

  static SovereignStatus _fxTone(double v) {
    if (v >= 100e9) return SovereignStatus.good;
    if (v >= 50e9) return SovereignStatus.warn;
    return SovereignStatus.bad;
  }

  static SovereignStatus _debtTone(double v) {
    if (v < 0.45) return SovereignStatus.good;
    if (v < 0.6) return SovereignStatus.warn;
    return SovereignStatus.bad;
  }
}

/// Baris indikator 44–56dp: label + sebelum → sesudah + sub-delta.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String before;
  final String after;
  final String sub;
  final SovereignStatus? tone;
  const _SummaryRow({
    required this.label,
    required this.before,
    required this.after,
    this.sub = '',
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final t = tone;
    return Container(
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 56),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
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
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SovereignColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.trim().isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t?.color ?? SovereignColors.mutedDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            before,
            style: const TextStyle(
              color: SovereignColors.muted,
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              decorationColor: SovereignColors.mutedDim,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 13, color: SovereignColors.cyan),
          ),
          Text(
            after,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Kartu kejadian + penyebab. Fallback jujur bila id tak dikenal
/// (sim tambah event aditif → jangan crash, jangan kosong misterius).
class _EventCauseCard extends StatelessWidget {
  final String eventId;
  final GameEvent? event;
  const _EventCauseCard({required this.eventId, required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;
    final title = e?.name.trim().isNotEmpty == true
        ? e!.name.trim()
        : _prettyId(eventId);
    final desc = e?.description.trim().isNotEmpty == true
        ? e!.description.trim()
        : 'Deskripsi belum tersedia untuk kejadian ini (sim menambah event baru — UI defensif).';
    final effects = e == null
        ? 'Dampak rinci belum dipetakan.'
        : _effectsText(e);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x22FBBF24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: SovereignColors.amber, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: SovereignColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  effects,
                  style: const TextStyle(
                    color: SovereignColors.mutedDim,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _effectsText(GameEvent e) {
    final bits = <String>[];
    for (final entry in e.priceEffects.entries) {
      final pct = (entry.value * 100).toStringAsFixed(0);
      final sign = entry.value >= 0 ? '+' : '';
      bits.add('Harga ${_prettyId(entry.key)} $sign$pct%');
    }
    for (final entry in e.productionEffects.entries) {
      final pct = (entry.value * 100).toStringAsFixed(0);
      final sign = entry.value >= 0 ? '+' : '';
      bits.add('Produksi ${_prettyId(entry.key)} $sign$pct%');
    }
    if (bits.isEmpty) return 'Dampak kuantitatif belum dirinci.';
    return 'Dampak: ${bits.join(' • ')}.';
  }

  static String _prettyId(String id) {
    final s = id.replaceAll('_', ' ').trim();
    if (s.isEmpty) return id;
    return s
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
