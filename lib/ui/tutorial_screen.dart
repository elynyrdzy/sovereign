// Tutorial SOVEREIGN — onboarding 5 langkahsekali-tampil.
// Langkah: laporan → analisis → kebijakan → proses → evaluasi.
// Ditampilkan sekali via SharedPreferences (key sovereign_tutorial_done,
// baca/tulis defensif try/catch). Bisa dibuka ulang dari Menu kapan saja.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  /// Kunci flag "sudah pernah melihat tutorial".
  static const prefsKey = 'sovereign_tutorial_done';

  /// Baca flag secara defensif: gagal baca = anggap belum (false),
  /// agar loading/bootstrap tidak pernah diblokir error prefs.
  static Future<bool> isDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefsKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Tulis flag secara defensif: kegagalan ditelan diam-diam.
  static Future<void> markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, true);
    } catch (_) {
      // Prefs gagal (mis. storage penuh) — tutorial tetap ditutup normal.
    }
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialStep {
  final IconData icon;
  final String kick;
  final String title;
  final String body;
  final String tip;
  const _TutorialStep({
    required this.icon,
    required this.kick,
    required this.title,
    required this.body,
    required this.tip,
  });
}

const _steps = <_TutorialStep>[
  _TutorialStep(
    icon: Icons.dashboard_outlined,
    kick: 'Langkah 1 dari 5 • Laporan',
    title: 'Baca kondisi negara',
    body:
        'Beranda adalah laporan kuartal berjalan: GDP, inflasi, pengangguran, '
        'devisa, dan rasio utang. Kartu berwarna memberi status — hijau baik, '
        'kuning waspada, merah kritis. Banner muncul hanya saat ada yang perlu perhatian.',
    tip: 'Ketuk kartu Inflasi untuk penjelasan & jalan pintas ke Ekonomi.',
  ),
  _TutorialStep(
    icon: Icons.show_chart_rounded,
    kick: 'Langkah 2 dari 5 • Analisis',
    title: 'Pahami tren sebelum bertindak',
    body:
        'Tab Ekonomi → Ringkasan menunjukkan penyebab inflasi (energi, permintaan, '
        'nilai tukar) dan arah konsumsi, investasi, serta perdagangan. Jangan ubah '
        'kebijakan sebelum tahu apa yang sebenarnya bergerak.',
    tip: 'Perubahan vs kuartal lalu tertulis di tiap kartu KPI.',
  ),
  _TutorialStep(
    icon: Icons.tune_rounded,
    kick: 'Langkah 3 dari 5 • Kebijakan',
    title: 'Usulan dulu, kunci kemudian',
    body:
        'Geser Suku Bunga atau Pajak untuk membuat DRAF usulan — simulasi TIDAK '
        'berubah selama masih draf. Tekan Konfirmasi untuk mengunci, atau Batalkan '
        '(butuh konfirmasi) untuk membuang draf. Draf aman saat pindah tab.',
    tip: 'Bunga tinggi menekan inflasi tapi bisa menaikkan pengangguran.',
  ),
  _TutorialStep(
    icon: Icons.play_arrow_rounded,
    kick: 'Langkah 4 dari 5 • Proses',
    title: 'Jalankan satu kuartal',
    body:
        'Tombol Proses Kuartal memakai nilai TERKONFIRMASI — draf yang belum '
        'dikunci tidak ikut diproses dan aplikasi akan mengingatkan dulu. '
        'Simulasi deterministik dan tercatat, jadi keputusanmu bisa dilacak.',
    tip: 'Ada draf gantung? Pilih “Konfirmasi & proses” atau “Proses saja”.',
  ),
  _TutorialStep(
    icon: Icons.fact_check_outlined,
    kick: 'Langkah 5 dari 5 • Evaluasi',
    title: 'Nilai hasil, ulangi siklus',
    body:
        'Ringkasan kuartal menampilkan apa yang berubah dan kejadian yang muncul. '
        'Kejadian & respons ada di Menu, arsip simpanan di Simpan / Muat. '
        'Siklus laporan → analisis → kebijakan → proses → evaluasi inilah inti SOVEREIGN.',
    tip: 'Simpan sebelum eksperimen berani — slot bisa dimuat ulang.',
  ),
];

class _TutorialScreenState extends State<TutorialScreen> {
  final _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await TutorialScreen.markDone();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _go(int page) {
    _pager.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Scaffold(
      backgroundColor: SovereignColors.deepNavy,
      appBar: AppBar(
        backgroundColor: SovereignColors.deepNavy,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tutorial',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Lewati'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _StepPage(step: _steps[i]),
              ),
            ),
            _Dots(count: _steps.length, active: _page),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SovereignSpacing.margin, 0, SovereignSpacing.margin, 8),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: SizedBox(
                        height: SovereignSpacing.touchMin,
                        child: OutlinedButton(
                          onPressed: () => _go(_page - 1),
                          child: const Text('Kembali'),
                        ),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: SovereignSpacing.touchMin,
                      child: ElevatedButton(
                        onPressed: () => last ? _finish() : _go(_page + 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SovereignColors.cyan,
                          foregroundColor: SovereignColors.deepNavy,
                        ),
                        child: Text(last ? 'Mulai Bermain' : 'Lanjut'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Hanya tampil otomatis sekali — buka lagi kapan saja dari Menu.',
                style: TextStyle(
                    color: SovereignColors.mutedDim, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final _TutorialStep step;
  const _StepPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          SovereignSpacing.margin, 12, SovereignSpacing.margin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SovereignColors.blueSlate,
              borderRadius:
                  BorderRadius.circular(SovereignSpacing.radius),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0x1436C5F0),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: SovereignColors.border),
                  ),
                  child: Icon(step.icon,
                      color: SovereignColors.cyan, size: 30),
                ),
                const SizedBox(height: 16),
                Text(step.kick,
                    style: const TextStyle(
                        color: SovereignColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(step.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 10),
                Text(step.body,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 14,
                        height: 1.55)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x1436C5F0),
              borderRadius:
                  BorderRadius.circular(SovereignSpacing.radius),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: SovereignColors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(step.tip,
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 13,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on
                ? SovereignColors.cyan
                : SovereignColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
