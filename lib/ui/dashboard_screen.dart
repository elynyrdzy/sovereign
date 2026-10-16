// Beranda Fase 0 — dashboard negara (ui.md §4.1).
// Membaca state aktual via GameController; draf tak-konfirmasi tidak mutasi sim.
// Header 60dp, KPI 3-kolom 88dp, peta 188dp, grid 2-kolom 84dp, sentuh min 48dp.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../models/policy.dart';
import '../models/result.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'format.dart';
import 'quarter_summary_sheet.dart';

class DashboardScreen extends StatelessWidget {
  final Country country;
  // Deep-link ke tab Ekonomi: 0 Ringkasan, 1 Konsumsi, 2 Investasi, 3 Perdagangan.
  final ValueChanged<int>? onOpenEconomy;
  // Deep-link ke tab Diplomasi dari bottom-sheet peta (pratinjau).
  final VoidCallback? onOpenDiplomacy;
  const DashboardScreen(
      {super.key,
      required this.country,
      this.onOpenEconomy,
      this.onOpenDiplomacy});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final proposed = controller.proposed;
    final confirmed = controller.confirmed;

    final bungaDef = _defOf(controller, 'bunga');
    final pajakDef = _defOf(controller, 'pajak');
    final bungaUsulan = proposed.values['bunga'] ?? s.interestRate;
    final pajakUsulan = proposed.values['pajak'] ?? s.taxRate;
    final isDirty = _isDirty(proposed, confirmed);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _CountryHeader(
            countryName: country.name,
            incomeGroup: country.incomeGroup,
            population: country.population,
            quarter: s.quarter,
            prosperity: s.prosperity,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                SovereignSpacing.margin,
                12,
                SovereignSpacing.margin,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _KpiRow(
                    gdp: s.gdp,
                    inflation: s.inflation,
                    unemployment: s.unemployment,
                    simulated: controller.simulated,
                    onInflationTap: () => _showInflationSheet(context),
                  ),
                  const SizedBox(height: SovereignSpacing.gap),
                  _WorldMapCard(onTap: () => _showWorldSheet(context)),
                  const SizedBox(height: SovereignSpacing.gap),
                  _FxDebtRow(
                    fx: s.fxReserves,
                    debtRatio: s.debtToGdp,
                  ),
                  const SizedBox(height: SovereignSpacing.gap),
                  _CrisisBanner(
                    inflation: s.inflation,
                    unemployment: s.unemployment,
                    debtRatio: s.debtToGdp,
                    fx: s.fxReserves,
                  ),
                  const SizedBox(height: SovereignSpacing.gap),
                  _PolicySection(
                    interestRateActual: s.interestRate,
                    taxRateActual: s.taxRate,
                    bungaDef: bungaDef,
                    pajakDef: pajakDef,
                    bungaUsulan: bungaUsulan,
                    pajakUsulan: pajakUsulan,
                    isDirty: isDirty,
                  ),
                  const SizedBox(height: SovereignSpacing.gap),
                  _ProcessSection(isDirty: isDirty),
                  const SizedBox(height: 8),
                  const Text(
                    'Draf tersimpan saat pindah tab (IndexedStack). Batal butuh konfirmasi bila ada perubahan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: SovereignColors.mutedDim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static PolicyDefinition? _defOf(GameController c, String id) {
    try {
      return c.policyDefs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  static bool _isDirty(PolicySet proposed, PolicySet confirmed) {
    final p = proposed.values;
    final q = confirmed.values;
    if (p.length != q.length) return true;
    for (final e in p.entries) {
      final other = q[e.key];
      if (other == null) return true;
      if ((e.value - other).abs() > 1e-9) return true;
    }
    return false;
  }

  void _showInflationSheet(BuildContext context) {
    final controller = context.read<GameController>();
    final s = controller.current;
    final status = _inflationStatus(s.inflation);
    final goEco = onOpenEconomy;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(status.icon, color: status.color, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Inflasi ${formatPercent(s.inflation)} • ${status.label}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Penyebab (energi, permintaan, nilai tukar) + grafik tren ada di Ekonomi → Ringkasan. Respons cepat di bawah tetap berlaku.',
                style: TextStyle(
                    color: SovereignColors.muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SovereignColors.deepNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SovereignColors.border),
                ),
                child: const Text(
                  'Respons cepat: naikkan Suku Bunga Acuan di kartu kebijakan di bawah, lalu Konfirmasi → Proses Kuartal. Pantau investasi & pengangguran ikut berubah.',
                  style: TextStyle(
                      color: SovereignColors.muted, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: SovereignSpacing.touchMin,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Deep-link ke Ekonomi → Ringkasan (tab 0) bila tersedia.
                    goEco?.call(0);
                    if (goEco == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Buka tab Ekonomi → Ringkasan untuk tren & penyebab inflasi.',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SovereignColors.cyan,
                  ),
                  child: const Text('Buka Detail Ekonomi'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: SovereignSpacing.touchMin,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom-sheet mini peta (pengganti snackbar): daftar negara + outlook
  /// sim + tombol ke Diplomasi. Tetap tanpa peta vektor penuh — jujur
  /// disebut pratinjau. Read-only; tidak memutasi sim.
  void _showWorldSheet(BuildContext context) {
    final controller = context.read<GameController>();
    final countries = controller.allCountries;
    final goDiplo = onOpenDiplomacy;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
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
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x1436C5F0),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: SovereignColors.border),
                    ),
                    child: const Text('PETA DUNIA • PRATINJAU',
                        style: TextStyle(
                            color: SovereignColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6)),
                  ),
                  const Spacer(),
                  Text(formatQuarter(controller.current.quarter),
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Jelajah mitra dagang',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Tanpa peta vektor penuh. Daftar + outlook sim di bawah — detail & negosiasi tetap di Diplomasi.',
                style: TextStyle(
                    color: SovereignColors.muted,
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 12),
              if (countries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: SovereignColors.deepNavy,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: SovereignColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.storage_rounded,
                          color: SovereignColors.muted, size: 18),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Daftar negara kosong — config allCountries belum termuat. Buka Diplomasi untuk catatan fallback jujur.',
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
                for (final c in countries)
                  _WorldRow(
                    name: c.name,
                    code: c.id,
                    gdp: formatCompactUsd(c.gdp),
                    outlook: _shortOutlook(
                        controller.outlookFor(c.id)),
                  ),
              const SizedBox(height: 12),
              SizedBox(
                height: SovereignSpacing.touchMin,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (goDiplo != null) {
                      goDiplo();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Buka tab Diplomasi untuk profil & negosiasi.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.public_rounded, size: 19),
                  label: const Text('Buka Diplomasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SovereignColors.cyan,
                    foregroundColor: SovereignColors.deepNavy,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: SovereignSpacing.touchMin,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ringkas outlook sim jadi satu baris jujur: "Surplus: a, b • Butuh: c".
  static String _shortOutlook(Map<String, String> outlook) {
    if (outlook.isEmpty) return 'Outlook belum tersedia';
    final surplus = <String>[];
    final need = <String>[];
    outlook.forEach((k, v) {
      if (v == 'surplus') {
        surplus.add(_prettyId(k));
      } else if (v == 'defisit') {
        need.add(_prettyId(k));
      }
    });
    final bits = <String>[];
    if (surplus.isNotEmpty) {
      bits.add('Surplus: ${surplus.take(2).join(', ')}${surplus.length > 2 ? ' +${surplus.length - 2}' : ''}');
    }
    if (need.isNotEmpty) {
      bits.add('Butuh: ${need.take(2).join(', ')}${need.length > 2 ? ' +${need.length - 2}' : ''}');
    }
    if (bits.isEmpty) return 'Netral — tak ada surplus/butuh menonjol';
    return bits.join(' • ');
  }

  static String _prettyId(String id) {
    final s = id.replaceAll('_', ' ').trim();
    if (s.isEmpty) return id;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ── Header negara + kuartal (56–64 dp) ──────────────────────────────

class _CountryHeader extends StatelessWidget {
  final String countryName;
  final String incomeGroup;
  final int population;
  final int quarter;
  final double prosperity;

  const _CountryHeader({
    required this.countryName,
    required this.incomeGroup,
    required this.population,
    required this.quarter,
    required this.prosperity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minHeight: SovereignSpacing.headerHeight),
      padding: const EdgeInsets.symmetric(
          horizontal: SovereignSpacing.margin, vertical: 8),
      decoration: const BoxDecoration(
        color: SovereignColors.deepNavy,
        border: Border(bottom: BorderSide(color: SovereignColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SovereignColors.border),
            ),
            child: const Center(
              child: Text('ID',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SovereignColors.deepNavy)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(countryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${_prettyIncome(incomeGroup)} • ${formatPopulation(population)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SovereignColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa_outlined,
                      size: 12, color: _prosperColor(prosperity)),
                  const SizedBox(width: 4),
                  Text('Makmur ${prosperity.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: SovereignColors.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _prettyIncome(String raw) {
    final s = raw.replaceAll('_', ' ');
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static Color _prosperColor(double v) {
    if (v >= 60) return SovereignColors.green;
    if (v >= 40) return SovereignColors.amber;
    return SovereignColors.red;
  }
}

// ── KPI 3 kolom (76–88 dp) ──────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final double gdp;
  final double inflation;
  final double unemployment;
  final QuarterResult? simulated;
  final VoidCallback onInflationTap;

  const _KpiRow({
    required this.gdp,
    required this.inflation,
    required this.unemployment,
    required this.simulated,
    required this.onInflationTap,
  });

  @override
  Widget build(BuildContext context) {
    String deltaFor(String kind) {
      final r = simulated;
      if (r == null) return 'Kuartal awal';
      double d;
      if (kind == 'gdp') {
        if (r.prev.gdp == 0) return '—';
        d = (r.next.gdp - r.prev.gdp) / r.prev.gdp;
        final sign = d >= 0 ? '+' : '';
        return '$sign${(d * 100).toStringAsFixed(1).replaceAll('.', ',')}% vs K${r.prev.quarter}';
      }
      if (kind == 'infl') {
        d = (r.next.inflation - r.prev.inflation) * 100;
        final sign = d >= 0 ? '+' : '';
        return '$sign${d.toStringAsFixed(1).replaceAll('.', ',')} pp vs K${r.prev.quarter}';
      }
      d = (r.next.unemployment - r.prev.unemployment) * 100;
      final sign = d >= 0 ? '+' : '';
      return '$sign${d.toStringAsFixed(1).replaceAll('.', ',')} pp vs K${r.prev.quarter}';
    }

    return LayoutBuilder(
      builder: (ctx, c) {
        // Layar sempit <360dp: 3 kolom terlalu padat → tumpuk 1 kolom.
        // Pola sama seperti resources_screen (fallback 1 kolom).
        if (c.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KpiCard(
                label: 'GDP',
                value: formatCompactUsd(gdp),
                sub: deltaFor('gdp'),
                status: SovereignStatus.neutral,
                semantic:
                    'Produk domestik bruto ${formatCompactUsd(gdp)}',
              ),
              const SizedBox(height: 10),
              _KpiCard(
                label: 'Inflasi',
                value: formatPercent(inflation),
                sub: deltaFor('infl'),
                status: _inflationStatus(inflation),
                onTap: onInflationTap,
                semantic:
                    'Inflasi ${formatPercent(inflation)}, status ${_inflationStatus(inflation).label}. Ketuk untuk detail.',
              ),
              const SizedBox(height: 10),
              _KpiCard(
                label: 'Pengangguran',
                value: formatPercent(unemployment),
                sub: deltaFor('unemp'),
                status: _unempStatus(unemployment),
                semantic:
                    'Pengangguran ${formatPercent(unemployment)}, status ${_unempStatus(unemployment).label}',
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'GDP',
                value: formatCompactUsd(gdp),
                sub: deltaFor('gdp'),
                status: SovereignStatus.neutral,
                semantic:
                    'Produk domestik bruto ${formatCompactUsd(gdp)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Inflasi',
                value: formatPercent(inflation),
                sub: deltaFor('infl'),
                status: _inflationStatus(inflation),
                onTap: onInflationTap,
                semantic:
                    'Inflasi ${formatPercent(inflation)}, status ${_inflationStatus(inflation).label}. Ketuk untuk detail.',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Pengangguran',
                value: formatPercent(unemployment),
                sub: deltaFor('unemp'),
                status: _unempStatus(unemployment),
                semantic:
                    'Pengangguran ${formatPercent(unemployment)}, status ${_unempStatus(unemployment).label}',
              ),
            ),
          ],
        );
      },
    );
  }
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

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final SovereignStatus status;
  final VoidCallback? onTap;
  final String semantic;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.status,
    this.onTap,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints:
          const BoxConstraints(minHeight: SovereignSpacing.kpiHeight),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              Icon(status.icon, size: 14, color: status.color),
            ],
          ),
          const SizedBox(height: 4),
          // Angka: FittedBox scaleDown agar layar sempit / font besar
          // tidak overflow — menyusut, bukan terpotong.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, height: 1.1)),
          ),
          const SizedBox(height: 3),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                  color: status == SovereignStatus.neutral
                      ? SovereignColors.muted
                      : status.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semantic,
      child: onTap == null
          ? card
          : InkWell(
              onTap: onTap,
              borderRadius:
                  BorderRadius.circular(SovereignSpacing.radius),
              child: card,
            ),
    );
  }
}

// ── Peta dunia placeholder (170–210 dp, 16:9) ───────────────────────

class _WorldMapCard extends StatelessWidget {
  final VoidCallback onTap;
  const _WorldMapCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Peta dunia pratinjau. Ketuk untuk daftar negara dan outlook.',
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SovereignSpacing.radius),
      child: Ink(
        height: SovereignSpacing.mapHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SovereignSpacing.radius),
          border: Border.all(color: SovereignColors.border),
          gradient: const LinearGradient(
            colors: [Color(0xFF0C2236), Color(0xFF102C43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1436C5F0),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: SovereignColors.border),
                      ),
                      child: const Text('PETA DUNIA',
                          style: TextStyle(
                              color: SovereignColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x22FBBF24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Pratinjau • Sheet',
                          style: TextStyle(
                              color: SovereignColors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Spacer(),
                const Row(
                  children: [
                    Icon(Icons.public_rounded,
                        color: SovereignColors.cyan, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jelajah mitra dagang',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text(
                              'Ketuk untuk daftar negara + outlook + jalan ke Diplomasi.',
                              style: TextStyle(
                                  color: SovereignColors.muted,
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: SovereignColors.muted),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Baris negara di bottom-sheet peta: 52–64dp, inisial + outlook satu baris.
class _WorldRow extends StatelessWidget {
  final String name;
  final String code;
  final String gdp;
  final String outlook;
  const _WorldRow({
    required this.name,
    required this.code,
    required this.gdp,
    required this.outlook,
  });

  @override
  Widget build(BuildContext context) {
    final initials = code.trim().isEmpty
        ? '?'
        : code.trim().substring(0, code.trim().length >= 2 ? 2 : 1).toUpperCase();
    return Container(
      constraints: const BoxConstraints(minHeight: 52, maxHeight: 64),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x1436C5F0),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: SovereignColors.cyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(outlook,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(gdp,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1636C5F0);
    const gap = 14.0;
    for (var x = 8.0; x < size.width; x += gap) {
      for (var y = 8.0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Devisa + utang (grid 2 kolom, 68–84 dp) ─────────────────────────

class _FxDebtRow extends StatelessWidget {
  final double fx;
  final double debtRatio;
  const _FxDebtRow({required this.fx, required this.debtRatio});

  @override
  Widget build(BuildContext context) {
    final fxStatus =
        fx >= 100e9 ? SovereignStatus.good : fx >= 50e9 ? SovereignStatus.warn : SovereignStatus.bad;
    final debtStatus = debtRatio < 0.45
        ? SovereignStatus.good
        : debtRatio < 0.6
            ? SovereignStatus.warn
            : SovereignStatus.bad;
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'Devisa',
            value: formatCompactUsd(fx),
            tag: fxStatus.label,
            status: fxStatus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniCard(
            label: 'Utang / GDP',
            value: formatDebtRatio(debtRatio),
            tag: debtStatus.label,
            status: debtStatus,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String tag;
  final SovereignStatus status;
  const _MiniCard(
      {required this.label,
      required this.value,
      required this.tag,
      required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SovereignSpacing.miniCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: SovereignColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(status.icon, size: 13, color: status.color),
              const SizedBox(width: 4),
              Text(tag,
                  style: TextStyle(
                      color: status.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Peringatan krisis (penuh lebar, hanya saat relevan) ─────────────

class _CrisisBanner extends StatelessWidget {
  final double inflation;
  final double unemployment;
  final double debtRatio;
  final double fx;
  const _CrisisBanner(
      {required this.inflation,
      required this.unemployment,
      required this.debtRatio,
      required this.fx});

  @override
  Widget build(BuildContext context) {
    final alerts = <({String title, String desc, SovereignStatus st})>[];
    if (inflation >= 0.06) {
      alerts.add((
        title: 'Inflasi tinggi ${formatPercent(inflation)}',
        desc: 'Pertimbangkan naikkan suku bunga, lalu konfirmasi.',
        st: SovereignStatus.bad
      ));
    } else if (inflation >= 0.04) {
      alerts.add((
        title: 'Inflasi menghangat ${formatPercent(inflation)}',
        desc: 'Pantau energi & permintaan sebelum mengetatkan.',
        st: SovereignStatus.warn
      ));
    }
    if (unemployment >= 0.08) {
      alerts.add((
        title: 'Pengangguran ${formatPercent(unemployment)} tinggi',
        desc: 'Bunga terlalu ketat bisa menekan investasi.',
        st: SovereignStatus.bad
      ));
    }
    if (debtRatio >= 0.6) {
      alerts.add((
        title: 'Utang ${formatDebtRatio(debtRatio)} berat',
        desc: 'Jaga belanja & penerimaan pajak.',
        st: SovereignStatus.bad
      ));
    }
    if (fx < 50e9) {
      alerts.add((
        title: 'Devisa menipis ${formatCompactUsd(fx)}',
        desc: 'Impor darurat menguras cadangan.',
        st: SovereignStatus.warn
      ));
    }
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x0F22C55E),
          borderRadius: BorderRadius.circular(SovereignSpacing.radius),
          border: Border.all(color: const Color(0x3322C55E)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: SovereignColors.green, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kondisi stabil • Baik',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('Tidak ada peringatan krisis kuartal ini.',
                      style: TextStyle(
                          color: SovereignColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final a = alerts.first;
    final bg = a.st == SovereignStatus.bad
        ? const Color(0x14F87171)
        : const Color(0x14FBBF24);
    final edge = a.st == SovereignStatus.bad
        ? const Color(0x44F87171)
        : const Color(0x44FBBF24);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: edge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(a.st.icon, color: a.st.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${a.title} • ${a.st.label}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(a.desc,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        height: 1.4)),
                if (alerts.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${alerts.length - 1} peringatan lain — buka Menu di Fase 1 untuk semua.',
                        style: const TextStyle(
                            color: SovereignColors.mutedDim,
                            fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slot kebijakan bunga/pajak (draf vs terkonfirmasi) ──────────────

class _PolicySection extends StatelessWidget {
  final double interestRateActual;
  final double taxRateActual;
  final PolicyDefinition? bungaDef;
  final PolicyDefinition? pajakDef;
  final double bungaUsulan;
  final double pajakUsulan;
  final bool isDirty;

  const _PolicySection({
    required this.interestRateActual,
    required this.taxRateActual,
    required this.bungaDef,
    required this.pajakDef,
    required this.bungaUsulan,
    required this.pajakUsulan,
    required this.isDirty,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kebijakan kuartal berikut',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text(
                        'Usulan tidak mengubah simulasi sebelum dikonfirmasi.',
                        style: TextStyle(
                            color: SovereignColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDirty
                      ? const Color(0x22FBBF24)
                      : const Color(0x1422C55E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isDirty
                            ? Icons.edit_outlined
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: isDirty
                            ? SovereignColors.amber
                            : SovereignColors.green),
                    const SizedBox(width: 4),
                    Text(isDirty ? 'DRAF' : 'SIAP',
                        style: TextStyle(
                            color: isDirty
                                ? SovereignColors.amber
                                : SovereignColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (bungaDef != null)
            _PolicySlider(
              title: bungaDef!.name,
              actual: interestRateActual,
              proposal: bungaUsulan,
              min: bungaDef!.min,
              max: bungaDef!.max,
              hint: 'Bunga tinggi → inflasi turun, investasi tertekan.',
              onChanged: (v) => controller.proposePolicy('bunga', v),
            ),
          if (bungaDef != null && pajakDef != null)
            const SizedBox(height: 14),
          if (pajakDef != null)
            _PolicySlider(
              title: pajakDef!.name,
              actual: taxRateActual,
              proposal: pajakUsulan,
              min: pajakDef!.min,
              max: pajakDef!.max,
              hint: 'Pajak tinggi → penerimaan naik, konsumsi tertahan.',
              onChanged: (v) => controller.proposePolicy('pajak', v),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: SovereignSpacing.touchMin,
                  child: ElevatedButton.icon(
                    onPressed: isDirty
                        ? () {
                            try {
                              controller.confirmPolicies();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Usulan dikonfirmasi — dipakai saat Proses Kuartal.'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal konfirmasi: $e')),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: const Text('Konfirmasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SovereignColors.cyan,
                      foregroundColor: SovereignColors.deepNavy,
                      disabledBackgroundColor: SovereignColors.border,
                      disabledForegroundColor: SovereignColors.mutedDim,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: SovereignSpacing.touchMin,
                  child: OutlinedButton.icon(
                    onPressed: isDirty
                        ? () => _confirmDiscard(context)
                        : null,
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Batalkan'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final controller = context.read<GameController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang draf usulan?'),
        content: const Text(
          'Nilai kembali ke yang terkonfirmasi. Simulasi tidak berubah karena draf memang tidak pernah memutasi simulasi.',
          style: TextStyle(color: SovereignColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tetap edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SovereignColors.amber,
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Ya, buang'),
          ),
        ],
      ),
    );
    if (ok == true) {
      controller.discardDraft();
    }
  }
}

class _PolicySlider extends StatelessWidget {
  final String title;
  final double actual;
  final double proposal;
  final double min;
  final double max;
  final String hint;
  final ValueChanged<double> onChanged;

  const _PolicySlider({
    required this.title,
    required this.actual,
    required this.proposal,
    required this.min,
    required this.max,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final changed = (proposal - actual).abs() > 1e-9;
    const int divisions = 40;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: changed
                    ? const Color(0x22FBBF24)
                    : SovereignColors.deepNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Text(
                'Aktual ${formatRate(actual)} → Usulan ${formatRate(proposal)}',
                style: TextStyle(
                    color: changed
                        ? SovereignColors.amber
                        : SovereignColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Slider(
          value: proposal.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: formatRate(proposal),
          onChanged: onChanged,
        ),
        Text(hint,
            style: const TextStyle(
                color: SovereignColors.mutedDim, fontSize: 12)),
      ],
    );
  }
}

// ── Proses kuartal + ringkasan ──────────────────────────────────────

class _ProcessSection extends StatelessWidget {
  final bool isDirty;
  const _ProcessSection({required this.isDirty});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: SovereignSpacing.processButtonHeight,
          child: ElevatedButton.icon(
            onPressed: () => _onProcess(context),
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(isDirty
                ? 'Proses Kuartal (ada draf belum dikonfirmasi)'
                : 'Proses Kuartal'),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isDirty
              ? 'Draf belum dikonfirmasi tidak ikut diproses — konfirmasi dulu bila ingin dipakai.'
              : 'Diproses memakai nilai terkonfirmasi. Deterministik & tercatat di log.',
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: SovereignColors.mutedDim, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _onProcess(BuildContext context) async {
    final controller = context.read<GameController>();
    if (isDirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Draf belum dikonfirmasi'),
          content: const Text(
            'Proses kuartal memakai nilai TERKONFIRMASI. Draf usulan tidak memengaruhi simulasi (ui.md §4.4).',
            style: TextStyle(color: SovereignColors.muted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('batal'),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('proses'),
              child: const Text('Proses saja'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('kunci'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SovereignColors.cyan,
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Konfirmasi & proses'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'batal') return;
      if (choice == 'kunci') {
        try {
          controller.confirmPolicies();
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal konfirmasi: $e')),
          );
          return;
        }
      }
    }
    QuarterResult result;
    try {
      result = controller.processQuarter();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses: $e')),
      );
      return;
    }
    if (!context.mounted) return;
    await _showResultSheet(context, result);
  }

  Future<void> _showResultSheet(BuildContext context, QuarterResult r) {
    final events = context.read<GameController>().events;
    return showQuarterSummarySheet(context, r, allEvents: events);
  }
}
