// Pencapaian SOVEREIGN — read-only, dihitung dari history + kuartal berjalan.
// Daftar statis 7 lencana; yang terkunci menyebut alasan jujur + progres.
// Tidak menyentuh sim: hanya watch GameController.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quarter_state.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'format.dart';

class _Ach {
  final String id;
  final IconData icon;
  final String title;
  final String desc;
  final bool unlocked;
  final String progress;
  final String lockedReason;
  const _Ach({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
    required this.unlocked,
    required this.progress,
    required this.lockedReason,
  });
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final all = <QuarterState>[...controller.history, s];

    final quarters = s.quarter;
    final streak = _trailingLowInflation(all);
    final bestFx = all.map((q) => q.fxReserves).reduce((a, b) => a > b ? a : b);
    final everHealthyDebt = all.any((q) => q.debtToGdp < 0.45);
    final bestDebt =
        all.map((q) => q.debtToGdp).reduce((a, b) => a < b ? a : b);
    final everProsperous = all.any((q) => q.prosperity >= 60);
    final bestProsper =
        all.map((q) => q.prosperity).reduce((a, b) => a > b ? a : b);
    final everSurplus =
        all.any((q) => q.taxRate * q.gdp > q.govSpending);

    final list = <_Ach>[
      _Ach(
        id: 'selamat-5',
        icon: Icons.shield_outlined,
        title: 'Selamat 5 Kuartal',
        desc: 'Bertahan tanpa restart kampanye sampai K5.',
        unlocked: quarters >= 5,
        progress: 'K$quarters / 5',
        lockedReason: quarters <= 0
            ? 'Belum ada kuartal diproses — tekan Proses Kuartal di Beranda.'
            : 'Mainkan sampai K5 — saat ini K$quarters.',
      ),
      _Ach(
        id: 'selamat-10',
        icon: Icons.fort_rounded,
        title: 'Dekade Kuartal',
        desc: 'Bertahan 10 kuartal penuh dalam satu kampanye.',
        unlocked: quarters >= 10,
        progress: 'K$quarters / 10',
        lockedReason: 'Butuh K10 — saat ini K$quarters. Lanjut bertahap.',
      ),
      _Ach(
        id: 'inflasi-terkendali',
        icon: Icons.thermostat_outlined,
        title: 'Inflasi Terkendali',
        desc: 'Inflasi di bawah 4% selama 4 kuartal beruntun.',
        unlocked: streak >= 4,
        progress: 'Beruntun $streak / 4',
        lockedReason: streak == 0
            ? 'Belum ada kuartal <4% beruntun — inflasi kini ${formatPercent(s.inflation)}.'
            : 'Butuh 4 beruntun <4% — saat ini $streak. Kini ${formatPercent(s.inflation)}.',
      ),
      _Ach(
        id: 'cadangan-kuat',
        icon: Icons.savings_outlined,
        title: 'Cadangan Kuat',
        desc: 'Devisa menyentuh ≥ \$100 M pada satu kuartal.',
        unlocked: bestFx >= 100e9,
        progress: 'Maks ${formatCompactUsd(bestFx)} / \$100 M',
        lockedReason:
            'Tertinggi ${formatCompactUsd(bestFx)} — dorong surplus dagang / jaga impor.',
      ),
      _Ach(
        id: 'utang-sehat',
        icon: Icons.balance_rounded,
        title: 'Utang Sehat',
        desc: 'Rasio utang/GDP pernah di bawah 45%.',
        unlocked: everHealthyDebt,
        progress: 'Terbaik ${formatDebtRatio(bestDebt)} / 45%',
        lockedReason:
            'Terbaik ${formatDebtRatio(bestDebt)} — jaga belanja & penerimaan pajak.',
      ),
      _Ach(
        id: 'makmur',
        icon: Icons.spa_outlined,
        title: 'Negeri Makmur',
        desc: 'Indeks kemakmuran menyentuh ≥60 sekali saja.',
        unlocked: everProsperous,
        progress: 'Tertinggi ${bestProsper.toStringAsFixed(0)} / 60',
        lockedReason:
            'Tertinggi ${bestProsper.toStringAsFixed(0)} — stabilkan inflasi & kerja.',
      ),
      _Ach(
        id: 'disiplin-fiskal',
        icon: Icons.account_balance_outlined,
        title: 'Disiplin Fiskal',
        desc: 'Satu kuartal surplus: pajak × GDP melebihi belanja.',
        unlocked: everSurplus,
        progress: everSurplus ? 'Pernah surplus' : 'Belum pernah surplus',
        lockedReason:
            'Kini belanja ${formatCompactUsd(s.govSpending)} vs pajak ${formatCompactUsd(s.taxRate * s.gdp)} — naikkan pajak / tahan belanja.',
      ),
    ];

    final opened = list.where((e) => e.unlocked).length;

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
            Text('Pencapaian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Lencana kampanye • read-only',
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
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x1422C55E),
                      borderRadius: BorderRadius.circular(13),
                      border:
                          Border.all(color: SovereignColors.border),
                    ),
                    child: const Icon(Icons.emoji_events_outlined,
                        color: SovereignColors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$opened dari ${list.length} terbuka',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          all.length <= 1
                              ? 'Kuartal awal — lencana dihitung dari history + kuartal berjalan.'
                              : 'Dihitung dari ${all.length} kuartal (history + berjalan). Read-only.',
                          style: const TextStyle(
                              color: SovereignColors.muted,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final a in list) ...[
              _AchCard(ach: a),
              const SizedBox(height: 10),
            ],
            const Text(
              'Syarat di atas final untuk Fase ini — tidak ada lencana tersembunyi. Terkunci berarti syarat belum terpenuhi, bukan fitur belum jadi.',
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

  /// Hitung ekor beruntun inflasi <4% dari seri penuh (history + kini).
  static int _trailingLowInflation(List<QuarterState> all) {
    var n = 0;
    for (var i = all.length - 1; i >= 0; i--) {
      if (all[i].inflation < 0.04) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }
}

class _AchCard extends StatelessWidget {
  final _Ach ach;
  const _AchCard({required this.ach});

  @override
  Widget build(BuildContext context) {
    final open = ach.unlocked;
    return Opacity(
      opacity: open ? 1.0 : 0.92,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: open
              ? SovereignColors.blueSlate
              : SovereignColors.deepNavySoft,
          borderRadius:
              BorderRadius.circular(SovereignSpacing.radius),
          border: Border.all(
            color: open ? const Color(0x4422C55E) : SovereignColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: open
                    ? const Color(0x1422C55E)
                    : SovereignColors.deepNavy,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Icon(
                open ? ach.icon : Icons.lock_outline_rounded,
                color: open
                    ? SovereignColors.green
                    : SovereignColors.muted,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(ach.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: open
                              ? const Color(0x1422C55E)
                              : SovereignColors.deepNavy,
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: SovereignColors.border),
                        ),
                        child: Text(open ? 'Terbuka' : 'Terkunci',
                            style: TextStyle(
                                color: open
                                    ? SovereignColors.green
                                    : SovereignColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(ach.desc,
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.45)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                          open
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_top_rounded,
                          size: 14,
                          color: open
                              ? SovereignColors.green
                              : SovereignColors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          open ? ach.progress : ach.lockedReason,
                          style: TextStyle(
                              color: open
                                  ? SovereignColors.green
                                  : SovereignColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
