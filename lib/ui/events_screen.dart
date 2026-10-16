// Layar Kejadian & krisis SOVEREIGN (ui.md §4.6).
// Kartu: judul + urgensi, penyebab, dampak, opsi respons + biaya/risiko,
// opsi locked dengan alasan. Alur: pilih → estimasi → konfirmasi.
// Via controller yang ada; respons belum ada API → dialog konfirmasi +
// TODO tanpa mutasi liar (tidak menyentuh sim di luar controller).
// Defensif: list dinamis, fallback bila field kosong.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_event.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'confirm_sheet.dart';
import 'format.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final events = controller.events;
    final current = controller.current;

    return Scaffold(
      backgroundColor: SovereignColors.deepNavy,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KEJADIAN',
                style: TextStyle(
                    color: SovereignColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
            Text('Respons krisis & kejadian',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: events.isEmpty
            ? const _EmptyEvents()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    SovereignSpacing.margin,
                    12,
                    SovereignSpacing.margin,
                    20),
                itemCount: events.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: SovereignSpacing.gap),
                itemBuilder: (ctx, i) {
                  if (i == 0) return const _EventsIntro();
                  return _EventCard(
                    event: events[i - 1],
                    quarter: current.quarter,
                    fx: current.fxReserves,
                    debtRatio: current.debtToGdp,
                    stocks: current.stocks,
                  );
                },
              ),
      ),
    );
  }
}

class _EventsIntro extends StatelessWidget {
  const _EventsIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius:
            BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: SovereignColors.cyan, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bandingkan respons → pilih → lihat estimasi → konfirmasi. Fase ini pratinjau: konfirmasi dicatat tanpa mengubah simulasi di luar antrean resmi.',
              style: TextStyle(
                color: SovereignColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0x1436C5F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SovereignColors.border),
              ),
              child: const Icon(Icons.bolt_outlined,
                  color: SovereignColors.cyan, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada kejadian terdaftar',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sim dapat menambah kejadian aditif — kartunya muncul di sini otomatis dengan fallback aman bila field kosong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: SovereignColors.muted,
                  fontSize: 13,
                  height: 1.6),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: SovereignSpacing.touchMin,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final GameEvent event;
  final int quarter;
  final double fx;
  final double debtRatio;
  final Map<String, double> stocks;
  const _EventCard({
    required this.event,
    required this.quarter,
    required this.fx,
    required this.debtRatio,
    required this.stocks,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = _urgencyOf(event, quarter);
    final title = event.name.trim().isEmpty
        ? _prettyId(event.id)
        : event.name.trim();
    final cause = event.description.trim().isEmpty
        ? 'Penyebab belum dirinci untuk kejadian ini.'
        : event.description.trim();

    return Container(
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius:
            BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: urgency.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(urgency.icon,
                      color: urgency.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.25)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: urgency.color
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Text(
                          urgency.label,
                          style: TextStyle(
                            color: urgency.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: _Section(
              icon: Icons.help_outline_rounded,
              title: 'Penyebab & pemicu',
              body: '$cause\n${_triggerText(event, quarter)}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _Section(
              icon: Icons.show_chart_rounded,
              title: 'Dampak terhadap negara',
              body: _effectsText(event),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PILIH RESPONS',
                  style: TextStyle(
                    color: SovereignColors.mutedDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                for (final opt in _optionsFor(
                    event, fx, debtRatio, stocks))
                  _OptionTile(
                    event: event,
                    option: opt,
                    fxText: formatCompactUsd(fx),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static ({String label, Color color, IconData icon}) _urgencyOf(
      GameEvent e, int quarter) {
    if (e.triggersOn(quarter)) {
      return (
        label: 'Aktif kuartal ini • Kritis',
        color: SovereignColors.red,
        icon: Icons.error_outline_rounded
      );
    }
    // Mendesak bila meledak kuartal depan.
    try {
      if (e.triggersOn(quarter + 1)) {
        return (
          label: 'Mendesak • next kuartal',
          color: SovereignColors.amber,
          icon: Icons.warning_amber_rounded
        );
      }
    } catch (_) {}
    final bigPrice =
        e.priceEffects.values.any((v) => v.abs() >= 0.3);
    final bigProd =
        e.productionEffects.values.any((v) => v <= -0.15);
    if (bigPrice || bigProd) {
      return (
        label: 'Waspada • dampak besar',
        color: SovereignColors.amber,
        icon: Icons.warning_amber_rounded
      );
    }
    return (
      label: 'Pantau • dampak terbatas',
      color: SovereignColors.muted,
      icon: Icons.info_outline_rounded
    );
  }

  static String _triggerText(GameEvent e, int now) {
    final mod = e.triggerQuarterMod;
    final off = e.triggerOffset;
    if (mod <= 0) return 'Pola pemicu belum tersedia.';
    var next = now;
    for (var k = 0; k <= mod + 1; k++) {
      if ((now + k) % mod == off) {
        next = now + k;
        break;
      }
    }
    final when = next == now
        ? 'berlaku kuartal ini (K$now)'
        : next == now + 1
            ? 'berikutnya K$next (siaga)'
            : 'berikutnya K$next';
    return 'Pola: tiap $mod kuartal • $when.';
  }

  static String _effectsText(GameEvent e) {
    final bits = <String>[];
    for (final en in e.priceEffects.entries) {
      if (en.key.trim().isEmpty) continue;
      final pct = (en.value * 100).toStringAsFixed(0);
      final sign = en.value >= 0 ? '+' : '';
      bits.add('Harga ${_prettyId(en.key)} $sign$pct%');
    }
    for (final en in e.productionEffects.entries) {
      if (en.key.trim().isEmpty) continue;
      final pct = (en.value * 100).toStringAsFixed(0);
      final sign = en.value >= 0 ? '+' : '';
      bits.add('Produksi ${_prettyId(en.key)} $sign$pct%');
    }
    if (bits.isEmpty) {
      return 'Dampak kuantitatif belum dirinci — pantau inflasi, stok & devisa.';
    }
    return '${bits.join(' • ')}.';
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

  /// Opsi generik (API respons belum ada): gating jujur memakai
  /// state nyata (devisa/utang), aksi final hanya TODO + snackbar.
  static List<_EventOption> _optionsFor(
    GameEvent e,
    double fx,
    double debt,
    Map<String, double> stocks,
  ) {
    final imporLocked = fx < 50e9;
    final fiskalLocked = debt >= 0.6;
    return [
      const _EventOption(
        id: 'serap',
        title: 'Serap & pantau',
        cost: 'Tanpa biaya langsung',
        risk: 'Harga/inflasi naik sementara; stok terkuras pelan',
        locked: false,
        lockReason: null,
      ),
      _EventOption(
        id: 'impor',
        title: 'Impor / cadangan darurat',
        cost: 'Kuras devisa ±0,1% + tarif impor berjalan',
        risk: 'Devisa turun; harga domestik ikut global',
        locked: imporLocked,
        lockReason: imporLocked
            ? 'Devisa ${formatCompactUsd(fx)} di bawah ambang aman — impor darurat berisiko.'
            : null,
      ),
      _EventOption(
        id: 'subsidi',
        title: 'Subsidi / intervensi harga',
        cost: 'Beban fiskal naik; utang melebar',
        risk: 'Defisit bila berkepanjangan; pantau utang/GDP',
        locked: fiskalLocked,
        lockReason: fiskalLocked
            ? 'Utang/GDP ${formatDebtRatio(debt)} berat — ruang fiskal sempit.'
            : null,
      ),
    ];
  }
}

class _EventOption {
  final String id;
  final String title;
  final String cost;
  final String risk;
  final bool locked;
  final String? lockReason;
  const _EventOption({
    required this.id,
    required this.title,
    required this.cost,
    required this.risk,
    required this.locked,
    required this.lockReason,
  });
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Section(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SovereignColors.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(
                      color: SovereignColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final GameEvent event;
  final _EventOption option;
  final String fxText;
  const _OptionTile({
    required this.event,
    required this.option,
    required this.fxText,
  });

  @override
  Widget build(BuildContext context) {
    final locked = option.locked;
    return Opacity(
      opacity: locked ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: SovereignColors.deepNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? SovereignColors.border
                : const Color(0x4436C5F0),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onTap(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: locked
                          ? SovereignColors.blueSlate
                          : const Color(0x1436C5F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      locked
                          ? Icons.lock_outline_rounded
                          : Icons.touch_app_outlined,
                      size: 18,
                      color: locked
                          ? SovereignColors.muted
                          : SovereignColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (locked)
                              const Text(
                                'TERKUNCI',
                                style: TextStyle(
                                  color: SovereignColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Biaya: ${option.cost}\nRisiko: ${option.risk}',
                          style: const TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (locked &&
                            (option.lockReason ?? '')
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: SovereignColors.amber),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  option.lockReason!.trim(),
                                  style: const TextStyle(
                                    color: SovereignColors.amber,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.chevron_right_rounded,
                        color: SovereignColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (option.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                option.lockReason ?? 'Opsi belum tersedia.')),
      );
      return;
    }
    final title = event.name.trim().isEmpty ? event.id : event.name;
    // Estimasi → konfirmasi via bottom-sheet reusable.
    final ok = await showSovereignConfirmSheet(
      context: context,
      title: '${option.title} — ${title.trim()}?',
      subtitle:
          'Estimasi kualitatif Fase ini. Konfirmasi dicatat sebagai niat; simulasi tidak diubah di luar antrean resmi.',
      comparisons: [
        ConfirmComparison(
          label: 'Status respons',
          before: 'Belum merespons',
          after: option.title,
        ),
      ],
      impacts: [
        ConfirmImpact(
            text: 'Biaya: ${option.cost}',
            tone: SovereignStatus.warn),
        ConfirmImpact(
            text: 'Risiko: ${option.risk}',
            tone: SovereignStatus.neutral),
        const ConfirmImpact(
            text:
                'Efek ke GDP/inflasi/devisa mengikuti simulasi kuartal berikut.',
            tone: SovereignStatus.neutral),
      ],
      costText:
          'Devisa kini $fxText • Opsi terkunci otomatis bila ambang dilanggar.',
      confirmLabel: 'Konfirmasi respons',
    );
    if (ok != true || !context.mounted) return;
    // TODO(events): sambungkan ke GameController / event-response API
    // saat tersedia (mis. queueEventResponse(eventId, optionId)).
    // Sengaja TANPA mutasi liar: jangan panggil propose/process palsu.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Respons "${option.title}" dicatat (pratinjau) — antrean resmi menyusul saat API tersedia.'),
      ),
    );
  }
}
