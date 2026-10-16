// Pengaturan SOVEREIGN — fungsional lokal, tanpa sentuh sim.
// Toggle kontras tinggi + teks besar (skala font via MediaQuery textScaler
// yang dipasang di AppBootstrap), simpan SharedPreferences defensif.
// Info versi + putar ulang tutorial (reset flag TutorialScreen.prefsKey).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import 'tutorial_screen.dart';

/// State aksesibilitas global (in-memory) — dipersist ke prefs.
class AccessState {
  final bool highContrast;
  final bool largeText;
  const AccessState({this.highContrast = false, this.largeText = false});

  AccessState copyWith({bool? highContrast, bool? largeText}) {
    return AccessState(
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
    );
  }

  /// Skala font via MediaQuery textScaler (ui.md §6 aksesibilitas).
  double get textScale => largeText ? 1.3 : 1.0;
}

/// Bus in-memory + persist defensif. Kegagalan prefs tidak pernah melempar
/// ke UI — toggle tetap jalan sesi ini, tersimpan bila storage tersedia.
class AccessBus {
  static const highKey = 'sovereign_high_contrast';
  static const largeKey = 'sovereign_large_text';

  static final ValueNotifier<AccessState> current =
      ValueNotifier<AccessState>(const AccessState());

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hi = prefs.getBool(highKey) ?? false;
      final lg = prefs.getBool(largeKey) ?? false;
      current.value = AccessState(highContrast: hi, largeText: lg);
    } catch (_) {
      // Prefs rusak/penuh — pakai default sesi ini, UI tetap jalan.
    }
  }

  static Future<void> setHighContrast(bool v) async {
    current.value = current.value.copyWith(highContrast: v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(highKey, v);
    } catch (_) {
      // Ditelan defensif — state in-memory tetap berlaku sesi ini.
    }
  }

  static Future<void> setLargeText(bool v) async {
    current.value = current.value.copyWith(largeText: v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(largeKey, v);
    } catch (_) {
      // Ditelan defensif.
    }
  }

  static Future<void> resetDefaults() async {
    current.value = const AccessState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(highKey, false);
      await prefs.setBool(largeKey, false);
    } catch (_) {
      // Ditelan defensif.
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _tutorialBusy = false;

  @override
  void initState() {
    super.initState();
    // Sinkronkan toggle dengan simpanan; gagal = default, tidak blokir UI.
    AccessBus.load();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _replayTutorial() async {
    if (_tutorialBusy) return;
    setState(() => _tutorialBusy = true);
    var resetOk = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hapus flag agar gate tutorial menganggap belum pernah lihat.
      // Fallback set false bila remove gagal di platform tertentu.
      final removed = await prefs.remove(TutorialScreen.prefsKey);
      if (!removed) await prefs.setBool(TutorialScreen.prefsKey, false);
    } catch (_) {
      resetOk = false;
    }
    if (!mounted) return;
    setState(() => _tutorialBusy = false);
    if (!resetOk) {
      _snack('Penyimpanan gagal — tutorial tetap dibuka sekali ini.');
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TutorialScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Pengaturan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Lokal di perangkat • tanpa sentuh sim',
                style: TextStyle(color: SovereignColors.muted, fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<AccessState>(
          valueListenable: AccessBus.current,
          builder: (context, access, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  SovereignSpacing.margin, 12, SovereignSpacing.margin, 20),
              children: [
                const Text(
                  'AKSESIBILITAS',
                  style: TextStyle(
                      color: SovereignColors.mutedDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                _SettingToggle(
                  icon: Icons.contrast_rounded,
                  title: 'Kontras tinggi',
                  subtitle: access.highContrast
                      ? 'Aktif — teks putih penuh & garis dipertegas di seluruh aplikasi.'
                      : 'Mati — tema standar Deep Navy.',
                  value: access.highContrast,
                  onChanged: (v) => AccessBus.setHighContrast(v),
                ),
                _SettingToggle(
                  icon: Icons.text_fields_rounded,
                  title: 'Teks besar',
                  subtitle: access.largeText
                      ? 'Aktif — skala font 1,3× via textScaler, berlaku segera.'
                      : 'Mati — skala font normal 1,0×.',
                  value: access.largeText,
                  onChanged: (v) {
                    AccessBus.setLargeText(v);
                    _snack(v
                        ? 'Teks besar aktif (1,3×) — berlaku segera.'
                        : 'Teks kembali normal.');
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1436C5F0),
                    borderRadius:
                        BorderRadius.circular(SovereignSpacing.radius),
                    border: Border.all(color: SovereignColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: SovereignColors.cyan, size: 18),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Pratinjau langsung: teks di layar ini ikut membesar saat toggle dinyalakan — karena skala dipasang global via MediaQuery. Tersimpan lokal walau aplikasi ditutup.',
                          style: TextStyle(
                              color: SovereignColors.muted,
                              fontSize: 12,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: SovereignSpacing.touchMin,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AccessBus.resetDefaults();
                      _snack('Pengaturan dikembalikan ke default.');
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 19),
                    label: const Text('Kembalikan default'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TUTORIAL',
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
                    color: SovereignColors.blueSlate,
                    borderRadius:
                        BorderRadius.circular(SovereignSpacing.radius),
                    border: Border.all(color: SovereignColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school_outlined,
                              color: SovereignColors.cyan, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Tutorial 5 langkah',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text(
                                    'Laporan → analisis → kebijakan → proses → evaluasi.',
                                    style: TextStyle(
                                        color: SovereignColors.muted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        height: SovereignSpacing.touchMin,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _tutorialBusy
                              ? null
                              : _replayTutorial,
                          icon: _tutorialBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          SovereignColors.deepNavy),
                                )
                              : const Icon(
                                  Icons.replay_rounded,
                                  size: 19),
                          label: Text(_tutorialBusy
                              ? 'Menyiapkan…'
                              : 'Putar tutorial ulang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SovereignColors.cyan,
                            foregroundColor:
                                SovereignColors.deepNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mereset penanda sovereign_tutorial_done lalu membuka tutorial. Bila penyimpanan gagal, tutorial tetap dibuka sekali ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: SovereignColors.mutedDim,
                            fontSize: 12,
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TENTANG',
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.token_outlined,
                              color: SovereignColors.muted, size: 20),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text('SOVEREIGN • 0.0.1+1',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Text('Fase 0',
                              style: TextStyle(
                                  color: SovereignColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'The Resource Economy — strategi ekonomi bergilir. Versi dari pubspec (0.0.1+1, build 1). Config lokal di perangkat; tanpa cek update server karena belum ada API — tidak diklaim memeriksa pembaruan.',
                        style: TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Baris toggle 48dp+ — label + switch kanan, subtitle jujur satu-dua baris.
class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(minHeight: SovereignSpacing.touchMin),
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? SovereignColors.cyan : SovereignColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value
                  ? SovereignColors.cyan
                  : SovereignColors.muted,
              size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: title,
            toggled: value,
            child: Switch(
              value: value,
              activeThumbColor: SovereignColors.cyan,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
