// Layar Kebijakan SOVEREIGN (ui.md §4.4).
// Tab: Fiskal • Moneter • Perdagangan • Struktural (40–48dp).
// Kartu 72–96dp + slider/numerik + panel dampak 100–180dp
// (hint statis + delta usulan vs aktual). Terapkan 52dp sticky.
// Bedakan: Aktual (hasil kuartal lalu) / Usulan draf / Antre terkonfirmasi.
// Batalkan membuang draf (kembali ke terkonfirmasi). Draf tak mutasi sim.
// Defensif: list dinamis dari policyDefs, fallback bila field kosong,
// sim boleh tambah instrumen aditif (unknown → Struktural).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/policy.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'confirm_sheet.dart';
import 'format.dart';

const _kTabs = ['Fiskal', 'Moneter', 'Perdagangan', 'Struktural'];

class PoliciesScreen extends StatefulWidget {
  final int initialTab;
  const PoliciesScreen({super.key, this.initialTab = 0});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: _kTabs.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _kTabs.length - 1),
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
    final defs = controller.policyDefs;
    final proposed = controller.proposed;
    final confirmed = controller.confirmed;
    final dirtyCount = _dirtyCount(proposed, confirmed);

    return Scaffold(
      backgroundColor: SovereignColors.deepNavy,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KEBIJAKAN',
                style: TextStyle(
                    color: SovereignColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
            Text('Ubah tanpa kehilangan konteks',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: PopScope(
        canPop: dirtyCount == 0,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || dirtyCount == 0) return;
          if (!context.mounted) return;
          final leave = await _askDiscard(context);
          if (leave == true && context.mounted) {
            context.read<GameController>().discardDraft();
            Navigator.of(context).pop();
          }
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _LegendBar(dirtyCount: dirtyCount),
              Container(
                height: 46,
                decoration: const BoxDecoration(
                  color: SovereignColors.deepNavy,
                  border: Border(
                      bottom:
                          BorderSide(color: SovereignColors.border)),
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
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    for (final t in _kTabs) Tab(text: t, height: 46),
                  ],
                ),
              ),
              Expanded(
                child: defs.isEmpty
                    ? const _EmptyDefs()
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          for (final cat in _kTabs)
                            _PolicyTab(
                              category: cat,
                              defs: defs
                                  .where(
                                      (d) => _categoryOf(d) == cat)
                                  .toList(),
                            ),
                        ],
                      ),
              ),
              _StickyActionBar(dirtyCount: dirtyCount),
            ],
          ),
        ),
      ),
    );
  }

  static int _dirtyCount(PolicySet proposed, PolicySet confirmed) {
    var n = 0;
    final keys = {...proposed.values.keys, ...confirmed.values.keys};
    for (final k in keys) {
      final a = proposed.values[k];
      final b = confirmed.values[k];
      if (a == null || b == null) {
        n++;
      } else if ((a - b).abs() > 1e-9) {
        n++;
      }
    }
    return n;
  }

  Future<bool?> _askDiscard(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang draf usulan?'),
        content: const Text(
          'Kembali tanpa menyimpan. Nilai kembali ke yang terkonfirmasi; simulasi tidak berubah.',
          style:
              TextStyle(color: SovereignColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 48)),
            child: const Text('Tetap edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SovereignColors.amber,
              foregroundColor: SovereignColors.deepNavy,
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Ya, buang'),
          ),
        ],
      ),
    );
  }
}

/// Kategori defensif: instrumen dikenal dipetakan eksplisit,
/// instrumen baru (sim aditif) jatuh ke Struktural agar tetap tampil.
String _categoryOf(PolicyDefinition def) {
  final id = def.id.toLowerCase().trim();
  final name = def.name.toLowerCase().trim();
  bool has(List<String> keys) =>
      keys.any((k) => id.contains(k) || name.contains(k));
  if (id == 'pajak' || id == 'belanja') {
    return id == 'pajak' ? 'Fiskal' : 'Fiskal';
  }
  if (id == 'bunga') return 'Moneter';
  if (id == 'tarif_impor' || id == 'subsidi_ekspor') {
    return 'Perdagangan';
  }
  if (has(['pajak', 'belanja', 'fiskal', 'anggaran', 'subsidi_anggaran'])) {
    return 'Fiskal';
  }
  if (has(['bunga', 'suku', 'moneter', 'inflasi_target'])) {
    return 'Moneter';
  }
  if (has(['tarif', 'ekspor', 'impor', 'dagang', 'kuota', 'bea'])) {
    return 'Perdagangan';
  }
  return 'Struktural';
}

class _LegendBar extends StatelessWidget {
  final int dirtyCount;
  const _LegendBar({required this.dirtyCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          SovereignSpacing.margin, 10, SovereignSpacing.margin, 10),
      decoration: const BoxDecoration(
        color: SovereignColors.deepNavySoft,
        border: Border(bottom: BorderSide(color: SovereignColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _LegendPill(
                icon: Icons.circle_rounded,
                color: SovereignColors.cyan,
                text: 'Aktual • hasil K lalu',
              ),
              _LegendPill(
                icon: Icons.edit_outlined,
                color: SovereignColors.amber,
                text: 'Usulan • draf',
              ),
              _LegendPill(
                icon: Icons.lock_outline_rounded,
                color: SovereignColors.green,
                text: 'Antre • terkonfirmasi',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dirtyCount == 0
                ? 'Selaras — usulan sama dengan antrean. Draf tidak mengubah simulasi sebelum dikonfirmasi.'
                : '$dirtyCount perubahan draf — Terapkan untuk mengunci ke antrean giliran berikut.',
            style: const TextStyle(
              color: SovereignColors.mutedDim,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _LegendPill(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyDefs extends StatelessWidget {
  const _EmptyDefs();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada instrumen kebijakan di config.\nSim dapat menambah aditif — UI akan menampilkannya di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: SovereignColors.muted, fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}

class _PolicyTab extends StatelessWidget {
  final String category;
  final List<PolicyDefinition> defs;
  const _PolicyTab({required this.category, required this.defs});

  @override
  Widget build(BuildContext context) {
    if (defs.isEmpty) {
      final isStructural = category == 'Struktural';
      return SingleChildScrollView(
        padding: const EdgeInsets.all(SovereignSpacing.margin),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SovereignColors.blueSlate,
            borderRadius:
                BorderRadius.circular(SovereignSpacing.radius),
            border: Border.all(color: SovereignColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.construction_outlined,
                  color: SovereignColors.muted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStructural
                          ? 'Instrumen struktural menyusul'
                          : 'Belum ada instrumen $category',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isStructural
                          ? 'Config saat ini belum mendaftarkan instrumen struktural. Bila sim menambah aditif, kartunya muncul di tab ini otomatis.'
                          : 'Tidak ada kebijakan $category di config saat ini.',
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
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          SovereignSpacing.margin, 12, SovereignSpacing.margin, 16),
      itemCount: defs.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: SovereignSpacing.gap),
      itemBuilder: (ctx, i) => _PolicyCard(def: defs[i]),
    );
  }
}

/// Kartu kebijakan: header 72–96dp (nama + badge + slider/numerik)
/// + panel dampak 100–180dp (delta usulan vs aktual + hint statis).
class _PolicyCard extends StatelessWidget {
  final PolicyDefinition def;
  const _PolicyCard({required this.def});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final current = controller.current;
    final proposedVal =
        controller.proposed.values[def.id] ?? def.defaultValue;
    final confirmedVal =
        controller.confirmed.values[def.id] ?? def.defaultValue;
    final actualVal = _actualFor(def, current, confirmedVal);

    final draftDiffers =
        (proposedVal - confirmedVal).abs() > 1e-9;
    final vsActual = proposedVal - actualVal;
    final isFraction = _isFraction(def);

    return Container(
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius:
            BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(
          color: draftDiffers
              ? const Color(0x66FBBF24)
              : SovereignColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header kartu.
          Container(
            constraints:
                const BoxConstraints(minHeight: 72, maxHeight: 128),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.name.trim().isEmpty
                            ? _prettyId(def.id)
                            : def.name.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DraftBadge(draftDiffers: draftDiffers),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktual ${_fmtVal(def, actualVal)} • Antre ${_fmtVal(def, confirmedVal)} • Usulan ${_fmtVal(def, proposedVal)}',
                  style: TextStyle(
                    color: draftDiffers
                        ? SovereignColors.amber
                        : SovereignColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 11),
                          overlayShape:
                              const RoundSliderOverlayShape(
                                  overlayRadius: 20),
                        ),
                        child: Slider(
                          value: proposedVal
                              .clamp(def.min, def.max)
                              .toDouble(),
                          min: def.min,
                          max: def.max > def.min
                              ? def.max
                              : def.min + 1,
                          divisions: _divisionsFor(def),
                          label: _fmtVal(def, proposedVal),
                          onChanged: (v) => controller.proposePolicy(
                              def.id, v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: isFraction ? 64 : 86,
                      child: _NumericField(
                          def: def, proposal: proposedVal),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Panel dampak 100–180dp.
          Container(
            constraints: const BoxConstraints(
                minHeight: 100, maxHeight: 220),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SovereignColors.deepNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      vsActual == 0
                          ? Icons.remove_circle_outline_rounded
                          : vsActual > 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                      size: 16,
                      color: vsActual == 0
                          ? SovereignColors.muted
                          : SovereignColors.cyan,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Delta usulan vs aktual: ${_fmtDelta(def, vsActual)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _hintFor(def),
                  style: const TextStyle(
                    color: SovereignColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: SovereignColors.blueSlate,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: SovereignColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14,
                          color: SovereignColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          draftDiffers
                              ? 'Pasca-giliran memakai ${_fmtVal(def, proposedVal)} bila dikonfirmasi.'
                              : 'Pasca-giliran tetap ${_fmtVal(def, confirmedVal)} (selaras).',
                          style: const TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 12,
                            height: 1.4,
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
      ),
    );
  }

  static double _actualFor(
      PolicyDefinition def, dynamic state, double confirmedVal) {
    // state: QuarterState — petakan yang dikenal; sisanya pakai antrean
    // agar tidak mengarang angka aktual palsu.
    try {
      if (def.id == 'bunga') return (state.interestRate as double);
      if (def.id == 'pajak') return (state.taxRate as double);
      if (def.id == 'belanja') return (state.govSpending as double);
    } catch (_) {
      return confirmedVal;
    }
    return confirmedVal;
  }

  static bool _isFraction(PolicyDefinition def) {
    if (def.unit.trim().toLowerCase() == 'fraksi') return true;
    return def.min >= 0 && def.max <= 1.01 && (def.max - def.min) <= 1.01;
  }

  static int? _divisionsFor(PolicyDefinition def) {
    final range = def.max - def.min;
    if (range <= 0) return null;
    if (range <= 1.01) return 40;
    return 40;
  }

  static String _fmtVal(PolicyDefinition def, double v) {
    if (_isFraction(def)) return formatRate(v);
    final u = def.unit.trim().toLowerCase();
    if (u.contains('usd') || v.abs() >= 10000) {
      return formatCompactUsd(v);
    }
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  static String _fmtDelta(PolicyDefinition def, double d) {
    if (d.abs() < 1e-12) return '±0 (sama dengan aktual)';
    final sign = d > 0 ? '+' : '−';
    if (_isFraction(def)) {
      return '$sign${(d.abs() * 100).toStringAsFixed(1).replaceAll('.', ',')} pp';
    }
    final u = def.unit.trim().toLowerCase();
    if (u.contains('usd') || d.abs() >= 10000) {
      return '$sign${formatCompactUsd(d.abs())}';
    }
    return '$sign${d.abs().toStringAsFixed(2)}';
  }

  static String _hintFor(PolicyDefinition def) {
    switch (def.id) {
      case 'pajak':
        return 'Hint: pajak tinggi → penerimaan naik, konsumsi tertahan. Pantau konsumsi & GDP.';
      case 'belanja':
        return 'Hint: belanja naik → permintaan & GDP terdorong, defisit/utang melebar. Pantau utang/GDP.';
      case 'bunga':
        return 'Hint: bunga tinggi → inflasi turun, investasi tertekan. Pantau investasi & pengangguran.';
      case 'tarif_impor':
        return 'Hint: tarif naik → harga domestik naik, impor tertahan, devisa terjaga. Pantau inflasi impor.';
      case 'subsidi_ekspor':
        return 'Hint: subsidi naik → ekspor terdorong, beban fiskal naik. Pantau neto dagang & devisa.';
      default:
        return 'Hint: instrumen tambahan — pantau GDP, inflasi & pengangguran setelah proses kuartal.';
    }
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

class _DraftBadge extends StatelessWidget {
  final bool draftDiffers;
  const _DraftBadge({required this.draftDiffers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: draftDiffers
            ? const Color(0x22FBBF24)
            : const Color(0x1422C55E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            draftDiffers
                ? Icons.edit_outlined
                : Icons.check_circle_rounded,
            size: 13,
            color: draftDiffers
                ? SovereignColors.amber
                : SovereignColors.green,
          ),
          const SizedBox(width: 4),
          Text(
            draftDiffers ? 'DRAF' : 'SELARAS',
            style: TextStyle(
              color: draftDiffers
                  ? SovereignColors.amber
                  : SovereignColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom numerik pendamping slider. Keyboard numerik, min 48dp.
class _NumericField extends StatefulWidget {
  final PolicyDefinition def;
  final double proposal;
  const _NumericField({required this.def, required this.proposal});

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _textFor(widget.proposal));
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant _NumericField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus &&
        (widget.proposal - old.proposal).abs() > 1e-12) {
      _c.text = _textFor(widget.proposal);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _textFor(double v) {
    if (_isFrac(widget.def)) {
      return (v * 100).toStringAsFixed(1).replaceAll('.', ',');
    }
    if (v.abs() >= 1e9) {
      return '${(v / 1e9).toStringAsFixed(1).replaceAll('.', ',')}M';
    }
    return v.toStringAsFixed(0);
  }

  bool _isFrac(PolicyDefinition d) {
    if (d.unit.trim().toLowerCase() == 'fraksi') return true;
    return d.min >= 0 && d.max <= 1.01;
  }

  void _commit() {
    final raw = _c.text.trim().replaceAll(',', '.');
    double? parsed;
    if (_isFrac(widget.def)) {
      // Terima "6,0" (persen) maupun "0,06" (fraksi).
      final num = double.tryParse(raw.replaceAll('%', '').replaceAll('M', ''));
      if (num != null) {
        parsed = num > 1.01 ? num / 100.0 : num;
      }
    } else {
      var t = raw
          .replaceAll('m', '')
          .replaceAll('M', '')
          .replaceAll('\$', '')
          .trim();
      final num = double.tryParse(t);
      if (num != null) {
        parsed = raw.toLowerCase().contains('m') &&
                widget.def.max >= 1e9
            ? num * 1e9
            : num;
      }
    }
    if (parsed == null || parsed.isNaN) {
      _c.text = _textFor(widget.proposal);
      return;
    }
    final clamped = parsed
        .clamp(widget.def.min, widget.def.max)
        .toDouble();
    context.read<GameController>().proposePolicy(widget.def.id, clamped);
    _c.text = _textFor(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SovereignSpacing.touchMin,
      child: TextField(
        controller: _c,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(
            signed: false, decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _commit(),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\%mM\$ ]')),
        ],
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          suffixText: _isFrac(widget.def) ? '%' : null,
          suffixStyle: const TextStyle(
              color: SovereignColors.mutedDim, fontSize: 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: SovereignColors.deepNavy,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: SovereignColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: SovereignColors.cyan),
          ),
        ),
      ),
    );
  }
}

/// Bar sticky bawah: Terapkan 52dp + Batalkan. Konfirmasi via bottom-sheet.
class _StickyActionBar extends StatelessWidget {
  final int dirtyCount;
  const _StickyActionBar({required this.dirtyCount});

  @override
  Widget build(BuildContext context) {
    final isDirty = dirtyCount > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          SovereignSpacing.margin, 10, SovereignSpacing.margin, 12),
      decoration: const BoxDecoration(
        color: SovereignColors.deepNavy,
        border:
            Border(top: BorderSide(color: SovereignColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: SovereignSpacing.processButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: isDirty
                      ? () => _onApply(context)
                      : null,
                  icon: const Icon(Icons.lock_outline_rounded,
                      size: 18),
                  label: Text(isDirty
                      ? 'Terapkan ($dirtyCount)'
                      : 'Terapkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SovereignColors.green,
                    foregroundColor: SovereignColors.deepNavy,
                    disabledBackgroundColor:
                        SovereignColors.border,
                    disabledForegroundColor:
                        SovereignColors.mutedDim,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: SovereignSpacing.processButtonHeight,
                child: OutlinedButton.icon(
                  onPressed:
                      isDirty ? () => _onDiscard(context) : null,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Batalkan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApply(BuildContext context) async {
    final controller = context.read<GameController>();
    final defs = controller.policyDefs;
    final proposed = controller.proposed;
    final confirmed = controller.confirmed;
    final current = controller.current;

    final changed = <PolicyDefinition>[];
    for (final d in defs) {
      final a = proposed.values[d.id];
      final b = confirmed.values[d.id];
      if (a == null || b == null || (a - b).abs() > 1e-9) {
        changed.add(d);
      }
    }
    if (changed.isEmpty) return;

    final comparisons = <ConfirmComparison>[
      for (final d in changed)
        ConfirmComparison(
          label: d.name.trim().isEmpty ? d.id : d.name,
          before: _PolicyCard._fmtVal(
              d, _PolicyCard._actualFor(d, current, confirmed.values[d.id] ?? d.defaultValue)),
          after: _PolicyCard._fmtVal(
              d, proposed.values[d.id] ?? d.defaultValue),
        ),
    ];
    final impacts = <ConfirmImpact>[
      for (final d in changed)
        ConfirmImpact(
          text:
              '${d.name.trim().isEmpty ? d.id : d.name}: ${_PolicyCard._fmtDelta(d, (proposed.values[d.id] ?? 0) - (_PolicyCard._actualFor(d, current, confirmed.values[d.id] ?? d.defaultValue)))} — ${_PolicyCard._hintFor(d)}',
          tone: SovereignStatus.neutral,
        ),
    ];
    String? cost;
    final belanja = changed.where((d) => d.id == 'belanja');
    if (belanja.isNotEmpty) {
      final d = belanja.first;
      final delta = (proposed.values[d.id] ?? 0) -
          (_PolicyCard._actualFor(
              d, current, confirmed.values[d.id] ?? 0));
      if (delta.abs() > 1e-6) {
        cost =
            'Belanja ${delta >= 0 ? '+' : '−'}${formatCompactUsd(delta.abs())}/kuartal → defisit & utang ikut bergerak.';
      }
    }

    final ok = await showSovereignConfirmSheet(
      context: context,
      title: 'Kunci ${changed.length} perubahan?',
      subtitle:
          'Dikunci untuk giliran berikutnya. Berlaku pasca-giliran, bukan seketika.',
      comparisons: comparisons,
      impacts: impacts,
      costText: cost,
      confirmLabel: 'Konfirmasi & antrekan',
    );
    if (ok != true || !context.mounted) return;
    try {
      controller.confirmPolicies();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Usulan dikonfirmasi — dipakai saat Proses Kuartal.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal konfirmasi: $e')),
      );
    }
  }

  Future<void> _onDiscard(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang draf usulan?'),
        content: const Text(
          'Nilai kembali ke yang terkonfirmasi. Simulasi tidak berubah karena draf memang tidak pernah memutasi simulasi.',
          style:
              TextStyle(color: SovereignColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 48)),
            child: const Text('Tetap edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SovereignColors.amber,
              foregroundColor: SovereignColors.deepNavy,
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Ya, buang'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<GameController>().discardDraft();
    }
  }
}
