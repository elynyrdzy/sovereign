// Ekonomi Fase 1 — dashboard ekonomi (ui.md §4.2).
// Tab: Ringkasan • Konsumsi • Investasi • Perdagangan (40–48 dp, geser horizontal).
// Baris indikator 64–80 dp, grafik tren 180–240 dp (fl_chart, history controller),
// kartu penyebab 72–120 dp. Hanya watch/read GameController; tanpa mutasi sim.
// Deep-link: initialTabIndex untuk tap inflasi dari Beranda.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quarter_state.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'format.dart';

/// index tab: 0 Ringkasan, 1 Konsumsi, 2 Investasi, 3 Perdagangan.
class EconomyScreen extends StatefulWidget {
  final int initialTabIndex;
  const EconomyScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _labels = ['Ringkasan', 'Konsumsi', 'Investasi', 'Perdagangan'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    // Seri penuh untuk grafik + delta QoQ: history + kini.
    final series = [...controller.history, s];
    final QuarterState? prev = series.length >= 2 ? series[series.length - 2] : null;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _EconomyHeader(quarter: s.quarter, hasHistory: series.length >= 2),
          // Tab 40–48 dp, geser horizontal.
          Container(
            height: 46,
            decoration: const BoxDecoration(
              color: SovereignColors.deepNavy,
              border: Border(bottom: BorderSide(color: SovereignColors.border)),
            ),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: SovereignColors.cyan,
              indicatorWeight: 2.5,
              labelColor: SovereignColors.cyan,
              unselectedLabelColor: SovereignColors.muted,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: [for (final l in _labels) Tab(text: l, height: 46)],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SummaryTab(current: s, prev: prev, series: series),
                _ConsumptionTab(current: s, prev: prev, series: series),
                _InvestmentTab(current: s, prev: prev, series: series),
                _TradeTab(current: s, prev: prev, series: series),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header 56 dp ────────────────────────────────────────────────────

class _EconomyHeader extends StatelessWidget {
  final int quarter;
  final bool hasHistory;
  const _EconomyHeader({required this.quarter, required this.hasHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SovereignSpacing.headerHeight,
      padding: const EdgeInsets.symmetric(
          horizontal: SovereignSpacing.margin, vertical: 8),
      decoration: const BoxDecoration(
        color: SovereignColors.deepNavy,
        border: Border(bottom: BorderSide(color: SovereignColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('EKONOMI',
                    style: TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                SizedBox(height: 2),
                Text('Mengapa ekonomi berubah',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1436C5F0),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Text(formatQuarter(quarter),
                style: const TextStyle(
                    color: SovereignColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ═════════ Tab 1 — Ringkasan ═════════

class _SummaryTab extends StatelessWidget {
  final QuarterState current;
  final QuarterState? prev;
  final List<QuarterState> series;
  const _SummaryTab({required this.current, required this.prev, required this.series});

  @override
  Widget build(BuildContext context) {
    final growth = prev == null || prev!.gdp == 0
        ? null
        : (current.gdp - prev!.gdp) / prev!.gdp;
    final inflDelta =
        prev == null ? null : current.inflation - prev!.inflation;
    final unempDelta =
        prev == null ? null : current.unemployment - prev!.unemployment;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IndicatorRow(
            label: 'GDP',
            value: formatCompactUsd(current.gdp),
            deltaText: growth == null
                ? 'Kuartal awal'
                : '${growth >= 0 ? '+' : ''}${(growth * 100).toStringAsFixed(1).replaceAll('.', ',')}% QoQ vs K${prev!.quarter}',
            status: growth == null
                ? SovereignStatus.neutral
                : growth >= 0.005
                    ? SovereignStatus.good
                    : growth >= -0.005
                        ? SovereignStatus.neutral
                        : SovereignStatus.bad,
            explain: 'C + I + G + (X−M). Lihat rincian Konsumsi, Investasi, Perdagangan.',
          ),
          const SizedBox(height: 10),
          _IndicatorRow(
            label: 'Inflasi',
            value: formatPercent(current.inflation),
            deltaText: inflDelta == null
                ? 'Kuartal awal'
                : '${inflDelta >= 0 ? '+' : ''}${(inflDelta * 100).toStringAsFixed(1).replaceAll('.', ',')} pp QoQ',
            status: _inflationStatus(current.inflation),
            explain: inflDelta == null
                ? 'Belum ada pembanding kuartal.'
                : inflDelta > 0.002
                    ? 'Naik — cek permintaan & harga impor di kartu penyebab.'
                    : inflDelta < -0.002
                        ? 'Turun — pengetatan / permintaan melemah.'
                        : 'Stabil dibanding kuartal lalu.',
          ),
          const SizedBox(height: 10),
          _IndicatorRow(
            label: 'Pengangguran',
            value: formatPercent(current.unemployment),
            deltaText: unempDelta == null
                ? 'Kuartal awal'
                : '${unempDelta >= 0 ? '+' : ''}${(unempDelta * 100).toStringAsFixed(1).replaceAll('.', ',')} pp QoQ',
            status: _unempStatus(current.unemployment),
            explain: 'Ikut pertumbuhan (Okun): GDP di atas ±2% menekan pengangguran.',
          ),
          const SizedBox(height: 12),
          _TrendChart(
            title: 'Tren GDP',
            unit: 'USD',
            periodLabel: _periodLabel(series),
            values: [for (final q in series) q.gdp],
            quarters: [for (final q in series) q.quarter],
            formatValue: formatCompactUsd,
            lineColor: SovereignColors.cyan,
          ),
          const SizedBox(height: 12),
          _CauseCard(
            icon: Icons.account_balance_rounded,
            title: 'Mengapa GDP bergerak?',
            body:
                'GDP = Konsumsi ${formatCompactUsd(current.consumption)} + Investasi ${formatCompactUsd(current.investment)} + Belanja ${formatCompactUsd(current.govSpending)} + Neto ekspor ${formatCompactUsd(current.exports - current.imports)}. Buka tiap tab untuk menelusuri komponen.',
            status: SovereignStatus.neutral,
          ),
          const SizedBox(height: 10),
          _CauseCard(
            icon: Icons.local_fire_department_outlined,
            title: 'Mengapa inflasi ${formatPercent(current.inflation)}?',
            body: _inflationCause(current, prev),
            status: _inflationStatus(current.inflation),
          ),
        ],
      ),
    );
  }

  String _inflationCause(QuarterState s, QuarterState? p) {
    final bits = <String>[];
    if (p != null) {
      final g = s.gdp != 0 && p.gdp != 0 ? (s.gdp - p.gdp) / p.gdp : 0;
      if (g > 0.02) bits.add('permintaan menguat (GDP +${(g * 100).toStringAsFixed(1).replaceAll('.', ',')}%)');
      if (g < -0.01) bits.add('permintaan melemah');
      if (s.imports > p.imports * 1.05) bits.add('nilai impor naik — tekanan harga impor');
    }
    if (s.interestRate > 0.08) {
      bits.add('suku bunga ${formatPercent(s.interestRate)} mengetat — menahan inflasi, menekan investasi');
    } else if (s.interestRate < 0.045) {
      bits.add('suku bunga ${formatPercent(s.interestRate)} longgar — mendukung permintaan');
    }
    if (bits.isEmpty) return 'Perubahan kecil — pantau energi, permintaan, dan nilai tukar tiap kuartal.';
    return 'Pemicu utama: ${bits.join('; ')}.';
  }
}

// ═════════ Tab 2 — Konsumsi ═════════

class _ConsumptionTab extends StatelessWidget {
  final QuarterState current;
  final QuarterState? prev;
  final List<QuarterState> series;
  const _ConsumptionTab({required this.current, required this.prev, required this.series});

  @override
  Widget build(BuildContext context) {
    final d = prev == null || prev!.consumption == 0
        ? null
        : (current.consumption - prev!.consumption) / prev!.consumption;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IndicatorRow(
            label: 'Konsumsi (C)',
            value: formatCompactUsd(current.consumption),
            deltaText: d == null
                ? 'Kuartal awal'
                : '${d >= 0 ? '+' : ''}${(d * 100).toStringAsFixed(1).replaceAll('.', ',')}% QoQ',
            status: d == null
                ? SovereignStatus.neutral
                : d >= 0
                    ? SovereignStatus.good
                    : SovereignStatus.warn,
            explain:
                'Pajak ${formatPercent(current.taxRate)} menekan daya beli. Inflasi ${formatPercent(current.inflation)} menggerus nilai riil.',
          ),
          const SizedBox(height: 10),
          _IndicatorRow(
            label: 'Pajak berjalan',
            value: formatPercent(current.taxRate),
            deltaText: prev == null
                ? 'Kuartal awal'
                : 'Beban C ≈ −${(current.taxRate * 50).toStringAsFixed(0)}% (rumus sementara)',
            status: current.taxRate > 0.25
                ? SovereignStatus.warn
                : SovereignStatus.neutral,
            explain: 'Pajak tinggi → penerimaan naik, konsumsi tertahan.',
          ),
          const SizedBox(height: 12),
          _TrendChart(
            title: 'Tren Konsumsi',
            unit: 'USD / kuartal',
            periodLabel: _periodLabel(series),
            values: [for (final q in series) q.consumption],
            quarters: [for (final q in series) q.quarter],
            formatValue: formatCompactUsd,
            lineColor: SovereignColors.green,
          ),
          const SizedBox(height: 12),
          _CauseCard(
            icon: Icons.shopping_basket_outlined,
            title: 'Mengapa konsumsi berubah?',
            body:
                'Konsumsi Kuartal ini ${formatCompactUsd(current.consumption)} (${(current.consumption / current.gdp * 100).toStringAsFixed(0)}% dari GDP). Pajak ${formatPercent(current.taxRate)} memotong daya beli ±${(current.taxRate * 50).toStringAsFixed(0)}% (sementara). Inflasi tinggi memperparah daya beli riil.',
            status: SovereignStatus.neutral,
          ),
        ],
      ),
    );
  }
}

// ═════════ Tab 3 — Investasi ═════════

class _InvestmentTab extends StatelessWidget {
  final QuarterState current;
  final QuarterState? prev;
  final List<QuarterState> series;
  const _InvestmentTab({required this.current, required this.prev, required this.series});

  @override
  Widget build(BuildContext context) {
    final d = prev == null || prev!.investment == 0
        ? null
        : (current.investment - prev!.investment) / prev!.investment;
    final rateGap = current.interestRate - 0.06;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IndicatorRow(
            label: 'Investasi (I)',
            value: formatCompactUsd(current.investment),
            deltaText: d == null
                ? 'Kuartal awal'
                : '${d >= 0 ? '+' : ''}${(d * 100).toStringAsFixed(1).replaceAll('.', ',')}% QoQ',
            status: d == null
                ? SovereignStatus.neutral
                : d >= 0
                    ? SovereignStatus.good
                    : SovereignStatus.warn,
            explain:
                'Suku bunga ${formatPercent(current.interestRate)} vs acuan 6,0%. Tinggi → investasi tertekan.',
          ),
          const SizedBox(height: 10),
          _IndicatorRow(
            label: 'Suku bunga berjalan',
            value: formatPercent(current.interestRate),
            deltaText: rateGap == 0
                ? 'Tepat di acuan 6,0%'
                : rateGap > 0
                    ? '+${(rateGap * 100).toStringAsFixed(1).replaceAll('.', ',')} pp di atas acuan'
                    : '${(rateGap * 100).toStringAsFixed(1).replaceAll('.', ',')} pp di bawah acuan',
            status: current.interestRate > 0.10
                ? SovereignStatus.warn
                : SovereignStatus.neutral,
            explain: 'Setiap +1 pp bunga menekan investasi ±2,5% (sementara).',
          ),
          const SizedBox(height: 12),
          _TrendChart(
            title: 'Tren Investasi',
            unit: 'USD / kuartal',
            periodLabel: _periodLabel(series),
            values: [for (final q in series) q.investment],
            quarters: [for (final q in series) q.quarter],
            formatValue: formatCompactUsd,
            lineColor: SovereignColors.amber,
          ),
          const SizedBox(height: 12),
          _CauseCard(
            icon: Icons.factory_outlined,
            title: 'Bunga vs investasi & kerja',
            body:
                'Bunga ${formatPercent(current.interestRate)} ${rateGap > 0 ? 'di atas' : rateGap < 0 ? 'di bawah' : 'tepat di'} acuan. Investasi ${formatCompactUsd(current.investment)} ikut respons ±2,5% per 1 pp. Pengangguran ${formatPercent(current.unemployment)} bergerak berlawanan dengan pertumbuhan (Okun).',
            status: rateGap.abs() > 0.04 ? SovereignStatus.warn : SovereignStatus.neutral,
          ),
        ],
      ),
    );
  }
}

// ═════════ Tab 4 — Perdagangan ═════════

class _TradeTab extends StatelessWidget {
  final QuarterState current;
  final QuarterState? prev;
  final List<QuarterState> series;
  const _TradeTab({required this.current, required this.prev, required this.series});

  @override
  Widget build(BuildContext context) {
    final net = current.exports - current.imports;
    final prevNet = prev == null ? null : prev!.exports - prev!.imports;
    final netDelta = (prevNet == null) ? null : net - prevNet;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IndicatorRow(
            label: 'Ekspor (X)',
            value: formatCompactUsd(current.exports),
            deltaText: prev == null || prev!.exports == 0
                ? 'Kuartal awal'
                : '${current.exports >= prev!.exports ? '+' : ''}${(((current.exports - prev!.exports) / prev!.exports) * 100).toStringAsFixed(1).replaceAll('.', ',')}% QoQ',
            status: SovereignStatus.neutral,
            explain: 'Surplus stok komoditas diekspor; subsidi ekspor menaikkan volume.',
          ),
          const SizedBox(height: 10),
          _IndicatorRow(
            label: 'Impor (M)',
            value: formatCompactUsd(current.imports),
            deltaText: prev == null || prev!.imports == 0
                ? 'Kuartal awal'
                : '${current.imports >= prev!.imports ? '+' : ''}${(((current.imports - prev!.imports) / prev!.imports) * 100).toStringAsFixed(1).replaceAll('.', ',')}% QoQ',
            status: current.imports > current.exports
                ? SovereignStatus.warn
                : SovereignStatus.neutral,
            explain: 'Defisit stok memicu impor darurat; menguras devisa & menekan inflasi impor.',
          ),
          const SizedBox(height: 10),
          _IndicatorRow(
            label: 'Neto (X−M) • Devisa',
            value:
                '${net >= 0 ? '+' : '−'}${formatCompactUsd(net.abs())} • ${formatCompactUsd(current.fxReserves)}',
            deltaText: netDelta == null
                ? 'Kuartal awal'
                : 'Neto ${netDelta >= 0 ? '+' : '−'}${formatCompactUsd(netDelta.abs())} QoQ',
            status: net >= 0 ? SovereignStatus.good : SovereignStatus.warn,
            explain: net >= 0
                ? 'Surplus dagang menopang devisa.'
                : 'Defisit dagang menguras devisa — cek stok Sumber Daya.',
          ),
          const SizedBox(height: 12),
          _DualTrendChart(
            title: 'Tren Ekspor vs Impor',
            unit: 'USD / kuartal',
            periodLabel: _periodLabel(series),
            exports: [for (final q in series) q.exports],
            imports: [for (final q in series) q.imports],
            quarters: [for (final q in series) q.quarter],
          ),
          const SizedBox(height: 12),
          _CauseCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Dari mana neto berasal?',
            body:
                'Ekspor ${formatCompactUsd(current.exports)} vs impor ${formatCompactUsd(current.imports)}. Tiap komoditas di atas stok aman 800 diekspor 50% surplus; di bawah 400 diimpor darurat (bayar tarif + kuras devisa 0,1%). Selisih neto masuk GDP & devisa.',
            status: net >= 0 ? SovereignStatus.good : SovereignStatus.warn,
          ),
        ],
      ),
    );
  }
}

// ── Baris indikator 64–80 dp ────────────────────────────────────────

class _IndicatorRow extends StatelessWidget {
  final String label;
  final String value;
  final String deltaText;
  final SovereignStatus status;
  final String explain;
  const _IndicatorRow({
    required this.label,
    required this.value,
    required this.deltaText,
    required this.status,
    required this.explain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68, maxHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(status.icon, size: 19, color: status.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, height: 1.15)),
                const SizedBox(height: 2),
                Text(deltaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: status == SovereignStatus.neutral
                            ? SovereignColors.muted
                            : status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(explain,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 12,
                        height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(status.label,
                style: TextStyle(
                    color: status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Kartu penyebab 72–120 dp ────────────────────────────────────────

class _CauseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final SovereignStatus status;
  const _CauseCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavySoft,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: status.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text('• ${status.label}',
                        style: TextStyle(
                            color: status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grafik tren tunggal 180–240 dp ─────────────────────────────────

class _TrendChart extends StatelessWidget {
  final String title;
  final String unit;
  final String periodLabel;
  final List<double> values;
  final List<int> quarters;
  final String Function(double) formatValue;
  final Color lineColor;
  const _TrendChart({
    required this.title,
    required this.unit,
    required this.periodLabel,
    required this.values,
    required this.quarters,
    required this.formatValue,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SovereignColors.deepNavy,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SovereignColors.border),
                ),
                child: Text('Satuan: $unit',
                    style: const TextStyle(
                        color: SovereignColors.muted, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1436C5F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(periodLabel,
                    style: const TextStyle(
                        color: SovereignColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(child: _chartBody()),
        ],
      ),
    );
  }

  Widget _chartBody() {
    if (values.length < 2) {
      return const Center(
        child: Text(
          'Butuh ≥2 kuartal untuk tren.\nProses kuartal untuk melihat garis.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: SovereignColors.mutedDim, fontSize: 12, height: 1.5),
        ),
      );
    }
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 1e-9) {
      minY *= 0.95;
      maxY *= 1.05;
      if (minY == maxY) {
        minY -= 1;
        maxY += 1;
      }
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null,
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, meta) {
                // Hanya min, tengah, maks agar tidak berdesakan.
                final mid = (minY + maxY) / 2;
                final candidates = [minY, mid, maxY];
                final closest = candidates.reduce(
                    (a, b) => (v - a).abs() < (v - b).abs() ? a : b);
                if ((v - closest).abs() > (maxY - minY) / 6) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(_shortAxis(closest),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: SovereignColors.mutedDim, fontSize: 10)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: ((spots.length - 1) / 4).clamp(1, 4).toDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= quarters.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('K${quarters[i]}',
                      style: const TextStyle(
                          color: SovereignColors.mutedDim, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: SovereignColors.border),
            bottom: BorderSide(color: SovereignColors.border),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            getTooltipItems: (touched) => [
              for (final s in touched)
                LineTooltipItem(
                  'K${quarters[s.x.round()]}\n${formatValue(s.y)}',
                  const TextStyle(
                      color: SovereignColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  String _shortAxis(double v) {
    final abs = v.abs();
    if (abs >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (abs >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}M';
    if (abs >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}jt';
    if (abs >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}rb';
    if (abs >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

// ── Grafik ganda Ekspor vs Impor ────────────────────────────────────

class _DualTrendChart extends StatelessWidget {
  final String title;
  final String unit;
  final String periodLabel;
  final List<double> exports;
  final List<double> imports;
  final List<int> quarters;
  const _DualTrendChart({
    required this.title,
    required this.unit,
    required this.periodLabel,
    required this.exports,
    required this.imports,
    required this.quarters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 232,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              _Legend(
                  dot: SovereignColors.cyan,
                  label: '— Ekspor',
                  icon: Icons.north_east_rounded),
              const SizedBox(width: 10),
              _Legend(
                  dot: SovereignColors.amber,
                  label: '- - Impor',
                  icon: Icons.south_west_rounded),
              const Spacer(),
              Text('Satuan: $unit • $periodLabel',
                  style: const TextStyle(
                      color: SovereignColors.mutedDim, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (exports.length < 2) {
      return const Center(
        child: Text(
          'Butuh ≥2 kuartal untuk tren.\nProses kuartal untuk melihat garis.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: SovereignColors.mutedDim, fontSize: 12, height: 1.5),
        ),
      );
    }
    final ex = <FlSpot>[
      for (var i = 0; i < exports.length; i++) FlSpot(i.toDouble(), exports[i]),
    ];
    final im = <FlSpot>[
      for (var i = 0; i < imports.length; i++) FlSpot(i.toDouble(), imports[i]),
    ];
    final all = [...exports, ...imports];
    var minY = all.reduce((a, b) => a < b ? a : b);
    var maxY = all.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 1e-9) {
      minY *= 0.95;
      maxY *= 1.05;
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (ex.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(_short(v),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: SovereignColors.mutedDim, fontSize: 10)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= quarters.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('K${quarters[i]}',
                      style: const TextStyle(
                          color: SovereignColors.mutedDim, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: SovereignColors.border),
            bottom: BorderSide(color: SovereignColors.border),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            getTooltipItems: (touched) => [
              for (final s in touched)
                LineTooltipItem(
                  '${s.barIndex == 0 ? 'Ekspor' : 'Impor'} K${quarters[s.x.round()]}\n${formatCompactUsd(s.y)}',
                  const TextStyle(
                      color: SovereignColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: ex,
            isCurved: true,
            color: SovereignColors.cyan,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true,
                color: SovereignColors.cyan.withValues(alpha: 0.10)),
          ),
          LineChartBarData(
            spots: im,
            isCurved: true,
            color: SovereignColors.amber,
            barWidth: 2.5,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  String _short(double v) {
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}M';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}jt';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

class _Legend extends StatelessWidget {
  final Color dot;
  final String label;
  final IconData icon;
  const _Legend({required this.dot, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: dot),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: SovereignColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Util ────────────────────────────────────────────────────────────

String _periodLabel(List<QuarterState> series) {
  if (series.isEmpty) return 'K0';
  if (series.length == 1) return 'K${series.first.quarter}';
  return 'K${series.first.quarter}–K${series.last.quarter}';
}

SovereignStatus _inflationStatus(double v) {
  if (v < 0.04) return SovereignStatus.good;
  if (v < 0.06) return SovereignStatus.warn;
  return SovereignStatus.bad;
}

SovereignStatus _unempStatus(double v) {
  if (v < 0.06) return SovereignStatus.good;
  if (v < 0.08) return SovereignStatus.warn;
  return SovereignStatus.bad;
}
