// Menu SOVEREIGN (ui.md §3): Kebijakan, Kejadian, + placeholder jujur.
// Navigasi via push (halaman detail pakai tombol kembali kiri atas).
// Draf kebijakan tidak hilang saat pindah tab (controller persist).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/game_controller.dart';
import '../theme.dart';
import 'achievements_screen.dart';
import 'budget_screen.dart';
import 'events_screen.dart';
import 'policies_screen.dart';
import 'save_screen.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final isDirty = _isDirty(controller);

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
              border: Border(
                  bottom: BorderSide(color: SovereignColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('MENU',
                          style: TextStyle(
                              color: SovereignColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      SizedBox(height: 2),
                      Text('Kebijakan, kejadian & arsip',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  SovereignSpacing.margin,
                  12,
                  SovereignSpacing.margin,
                  20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MenuTile(
                    icon: Icons.tune_rounded,
                    title: 'Kebijakan',
                    subtitle:
                        'Fiskal • Moneter • Perdagangan • Struktural + panel dampak',
                    badge: isDirty ? 'DRAF' : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const PoliciesScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.bolt_outlined,
                    title: 'Kejadian & respons',
                    subtitle:
                        'Penyebab, dampak, opsi + biaya/risiko (pratinjau Fase 1)',
                    badge: controller.events.isEmpty
                        ? null
                        : '${controller.events.length}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EventsScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.school_outlined,
                    title: 'Tutorial',
                    subtitle:
                        'Siklus main 5 langkah: laporan → analisis → kebijakan → proses → evaluasi',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const TutorialScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.save_outlined,
                    title: 'Simpan / muat',
                    subtitle:
                        '3 slot lokal + simpanan utama — muat, timpa, atau hapus',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SaveScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Anggaran rinci',
                    subtitle:
                        'Belanja (G), penerimaan & defisit estimasi, utang — read-only',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const BudgetScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.emoji_events_outlined,
                    title: 'Pencapaian',
                    subtitle:
                        'Lencana dihitung dari history — terkunci menyebut syarat jujur',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const AchievementsScreen()),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    subtitle:
                        'Kontras, teks besar, tutorial ulang & versi — lokal',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SEGERA • JUJUR BELUM AKTIF',
                    style: TextStyle(
                      color: SovereignColors.mutedDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _SoonTile(
                    icon: Icons.cloud_sync_outlined,
                    title: 'Pengaturan lanjutan',
                    subtitle:
                        'Sinkronisasi cloud & server — butuh API yang belum ada, jadi tetap non-aktif jujur.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Navigasi kembali selalu aman — draf kebijakan tidak hilang saat pindah tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isDirty(GameController c) {
    final p = c.proposed.values;
    final q = c.confirmed.values;
    if (p.length != q.length) return true;
    for (final e in p.entries) {
      final other = q[e.key];
      if (other == null) return true;
      if ((e.value - other).abs() > 1e-9) return true;
    }
    return false;
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius:
            BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(SovereignSpacing.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x1436C5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: SovereignColors.border),
                  ),
                  child: Icon(icon,
                      color: SovereignColors.cyan, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0x22FBBF24),
                                borderRadius:
                                    BorderRadius.circular(999),
                              ),
                              child: Text(badge!,
                                  style: const TextStyle(
                                      color:
                                          SovereignColors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: SovereignColors.muted,
                              fontSize: 12,
                              height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: SovereignColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile non-aktif yang jujur: bukan stub palsu fungsional.
class _SoonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SoonTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.78,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SovereignColors.deepNavySoft,
          borderRadius:
              BorderRadius.circular(SovereignSpacing.radius),
          border: Border.all(color: SovereignColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: SovereignColors.muted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: SovereignColors.deepNavy,
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                              color: SovereignColors.border),
                        ),
                        child: const Text('Segera',
                            style: TextStyle(
                                color: SovereignColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
