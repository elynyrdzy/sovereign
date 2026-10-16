// Sumber Daya Fase 1 — komoditas & stok (ui.md §4.3).
// Grid 2 kolom kartu 100–124 dp, bar kapasitas 8–12 dp, tombol Kelola 48–52 dp.
// Bottom-sheet detail rantai pasok read-only Fase 1; aksi ganggu domestik
// selalu minta konfirmasi dialog dan TIDAK mutasi sim di luar controller.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/commodity.dart';
import '../models/quarter_state.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'format.dart';

// Ambang stok aman kuartalan (lihat SimEngine langkah 5: targetBuffer 800).
const double _kTargetBuffer = 800.0;
// Baseline produksi/konsumsi per kuartal (lihat formulas.dart sementara).
const double _kBaseOutput = 1000.0;
const double _kBaseUse = 950.0;

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final prevStocks = controller.history.isEmpty
        ? null
        : controller.history.last.stocks;
    final tarif = controller.confirmed.values['tarif_impor'] ?? 0.10;
    final items = controller.commodities;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: SovereignSpacing.headerHeight,
            padding: const EdgeInsets.symmetric(
                horizontal: SovereignSpacing.margin, vertical: 8),
            decoration: const BoxDecoration(
              color: SovereignColors.deepNavy,
              border:
                  Border(bottom: BorderSide(color: SovereignColors.border)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SUMBER DAYA',
                          style: TextStyle(
                              color: SovereignColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      SizedBox(height: 2),
                      Text('Stok, harga & kecukupan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1436C5F0),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SovereignColors.border),
                  ),
                  child: Text(formatQuarter(s.quarter),
                      style: const TextStyle(
                          color: SovereignColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  SovereignSpacing.margin, 12, SovereignSpacing.margin, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StockBanner(state: s, count: items.length),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      // 360 dp → 2 kolom; layar sangat sempit → 1 kolom.
                      final twoCol = c.maxWidth >= 320;
                      if (twoCol) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            // 158 lebar → ±116 tinggi (100–124 dp).
                            childAspectRatio: 1.36,
                          ),
                          itemBuilder: (c2, i) => _CommodityCard(
                            commodity: items[i],
                            stock: s.stocks[items[i].id] ?? 0,
                            price: s.prices[items[i].id] ?? items[i].baseGlobalPrice,
                            basePrice: items[i].baseGlobalPrice,
                            prevStock: prevStocks?[items[i].id],
                            tarif: tarif,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final cMod in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CommodityCard(
                                commodity: cMod,
                                stock: s.stocks[cMod.id] ?? 0,
                                price:
                                    s.prices[cMod.id] ?? cMod.baseGlobalPrice,
                                basePrice: cMod.baseGlobalPrice,
                                prevStock: prevStocks?[cMod.id],
                                tarif: tarif,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stok awal 1.000/komoditas. Estimasi durasi = stok ÷ 950 pakai/kuartal. Harga domestik ≈ global × (1 + tarif). Fase 1 read-only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: SovereignColors.mutedDim, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ringkasan stok atas ─────────────────────────────────────────────

class _StockBanner extends StatelessWidget {
  final QuarterState state;
  final int count;
  const _StockBanner({required this.state, required this.count});

  @override
  Widget build(BuildContext context) {
    var kritis = 0;
    var waspada = 0;
    for (final v in state.stocks.values) {
      final st = _stockStatus(v);
      if (st == SovereignStatus.bad) kritis++;
      if (st == SovereignStatus.warn) waspada++;
    }
    final status = kritis > 0
        ? SovereignStatus.bad
        : waspada > 0
            ? SovereignStatus.warn
            : SovereignStatus.good;
    final text = kritis > 0
        ? '$kritis komoditas kritis — buka detail untuk impor darurat.'
        : waspada > 0
            ? '$waspada komoditas menipis — pantau sebelum defisit.'
            : 'Semua $count komoditas di atas buffer aman.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: status.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kecukupan stok • ${status.label}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu komoditas 100–124 dp ──────────────────────────────────────

class _CommodityCard extends StatelessWidget {
  final Commodity commodity;
  final double stock;
  final double price;
  final double basePrice;
  final double? prevStock;
  final double tarif;
  const _CommodityCard({
    required this.commodity,
    required this.stock,
    required this.price,
    required this.basePrice,
    required this.prevStock,
    required this.tarif,
  });

  @override
  Widget build(BuildContext context) {
    final status = _stockStatus(stock);
    final duration = stock / _kBaseUse; // kuartal tersisa (estimasi).
    final domestic = price * (1 + tarif);
    final delta = prevStock == null || prevStock == 0
        ? null
        : stock - prevStock!;
    final flow = _flowLabel(stock);

    return Semantics(
      button: true,
      label:
          '${commodity.id}, stok ${stock.toStringAsFixed(0)}, ${status.label}, ${duration.toStringAsFixed(1)} kuartal',
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        child: Ink(
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
              Row(
                children: [
                  Expanded(
                    child: Text(_prettyId(commodity.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  Icon(status.icon, size: 15, color: status.color),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('${stock.toStringAsFixed(0)} • ≈${_fmtDur(duration)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Text(status.label,
                      style: TextStyle(
                          color: status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                delta == null
                    ? '${flow.label} • \$${domestic.toStringAsFixed(0)}/unit'
                    : '${flow.label} • ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)} QoQ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: SovereignColors.muted, fontSize: 11, height: 1.3),
              ),
              const SizedBox(height: 7),
              // Bar kapasitas 8–12 dp: stok ÷ 1600 (2× buffer).
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: LinearProgressIndicator(
                    value: (stock / (_kTargetBuffer * 2)).clamp(0.0, 1.0),
                    backgroundColor: SovereignColors.deepNavy,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(status.color),
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CommoditySheet(
        commodity: commodity,
        stock: stock,
        price: price,
        basePrice: basePrice,
        prevStock: prevStock,
        tarif: tarif,
      ),
    );
  }
}

// ── Bottom-sheet detail rantai pasok (read-only Fase 1) ────────────

class _CommoditySheet extends StatelessWidget {
  final Commodity commodity;
  final double stock;
  final double price;
  final double basePrice;
  final double? prevStock;
  final double tarif;
  const _CommoditySheet({
    required this.commodity,
    required this.stock,
    required this.price,
    required this.basePrice,
    required this.prevStock,
    required this.tarif,
  });

  @override
  Widget build(BuildContext context) {
    final status = _stockStatus(stock);
    final duration = stock / _kBaseUse;
    final flow = _flowLabel(stock);
    final domestic = price * (1 + tarif);
    final priceDelta =
        basePrice == 0 ? 0 : (price - basePrice) / basePrice;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 14, color: status.color),
                      const SizedBox(width: 4),
                      Text(status.label,
                          style: TextStyle(
                              color: status.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SovereignColors.deepNavy,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SovereignColors.border),
                  ),
                  child: Text(_prettyCat(commodity.category),
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Tutup',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_prettyId(commodity.id),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            Text(
                'Stok ${stock.toStringAsFixed(0)} • ≈${_fmtDur(duration)} kebutuhan • ${flow.label}',
                style: const TextStyle(
                    color: SovereignColors.muted, fontSize: 13)),
            const SizedBox(height: 12),
            _SheetRow(
                label: 'Produksi / kuartal',
                value: '≈${_kBaseOutput.toStringAsFixed(0)}',
                sub: 'Basis sementara + shock kecil'),
            _SheetRow(
                label: 'Konsumsi / kuartal',
                value: '≈${_kBaseUse.toStringAsFixed(0)}',
                sub: prevStock == null
                    ? 'Kuartal awal — belum ada delta'
                    : 'Delta stok ${stock - prevStock! >= 0 ? '+' : ''}${(stock - prevStock!).toStringAsFixed(0)} vs kuartal lalu'),
            _SheetRow(
                label: 'Impor / Ekspor',
                value: flow.label,
                sub: flow.desc),
            _SheetRow(
                label: 'Harga domestik',
                value: '\$${domestic.toStringAsFixed(0)} / ${commodity.unit}',
                sub: 'Global \$${price.toStringAsFixed(0)} × (1 + tarif ${(tarif * 100).toStringAsFixed(0)}%)'),
            _SheetRow(
                label: 'Harga global vs acuan',
                value:
                    '${priceDelta >= 0 ? '+' : ''}${(priceDelta * 100).toStringAsFixed(1).replaceAll('.', ',')}% vs \$${basePrice.toStringAsFixed(0)}',
                sub: 'Acuan config; bergerak ±2% per kuartal + event'),
            _SheetRow(
                label: 'Kapasitas (stok ÷ 1.600)',
                value:
                    '${((stock / (_kTargetBuffer * 2)).clamp(0, 1) * 100).toStringAsFixed(0)}% • ${status.label}',
                sub: 'Buffer aman 800; <400 impor darurat, >800 surplus diekspor'),
            _SheetRow(
                label: 'Industri pengguna',
                value: commodity.usedBy.map(_prettyId).join(', '),
                sub:
                    'Produsen: ${commodity.producers.map(_prettyId).join(', ')} • Strategis ${(commodity.strategicImportance * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SovereignColors.deepNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SovereignColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: SovereignColors.muted, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fase 1 read-only: pengaturan kapasitas, investasi, dan prioritas distribusi hadir Fase 2. Aksi di bawah hanya simulasi dialog — tidak mengubah sim.',
                      style: TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tombol Kelola Produksi 48–52 dp.
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmDomestic(
                    context, 'Prioritaskan kebutuhan domestik?'),
                icon: const Icon(Icons.tune_rounded, size: 19),
                label: const Text('Kelola Produksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SovereignColors.cyan,
                  foregroundColor: SovereignColors.deepNavy,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDomestic(
                    context, 'Alihkan volume ke ekspor?'),
                icon: const Icon(Icons.warning_amber_rounded, size: 19),
                label: const Text('Alihkan ke Ekspor (gangguan domestik)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDomestic(BuildContext context, String title) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Tindakan ini memengaruhi kebutuhan domestik / kontrak dagang (ui.md §4.3). Fase 1: konfirmasi tidak memutasi simulasi — pengaturan penuh hadir Fase 2.',
          style: TextStyle(
              color: SovereignColors.muted, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 48)),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Tercatat — sim tidak berubah di Fase 1. Lanjut via Proses Kuartal di Beranda.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SovereignColors.amber,
              foregroundColor: SovereignColors.deepNavy,
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _SheetRow({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: SovereignColors.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(sub,
                    style: const TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Util status ─────────────────────────────────────────────────────

SovereignStatus _stockStatus(double stock) {
  if (stock < _kTargetBuffer * 0.5) return SovereignStatus.bad; // <400
  if (stock < _kTargetBuffer) return SovereignStatus.warn; // 400–800
  return SovereignStatus.good;
}

({String label, String desc}) _flowLabel(double stock) {
  if (stock > _kTargetBuffer) {
    return (
      label: 'Surplus • Ekspor',
      desc: 'Di atas 800 — 50% surplus diekspor'
    );
  }
  if (stock < _kTargetBuffer * 0.5) {
    return (
      label: 'Defisit • Impor',
      desc: 'Di bawah 400 — impor darurat + tarif'
    );
  }
  return (label: 'Seimbang', desc: '400–800 — tanpa dagang darurat');
}

String _fmtDur(double q) =>
    '${q.toStringAsFixed(1).replaceAll('.', ',')} krt';

String _prettyId(String id) {
  final s = id.replaceAll('_', ' ');
  if (s.isEmpty) return s;
  return s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String _prettyCat(String c) => _prettyId(c);
