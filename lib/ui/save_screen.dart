// Simpan / muat SOVEREIGN — slot lokal (ui, read-only thd kontrak save).
// Memakai API SaveV1 yang ada (saveToFile/loadFromFile); daftar slot
// dipindai dari ApplicationDocuments via path_provider. Semua IO try/catch
// + empty-state jujur. Toleran format berubah aditif: berkas tak-terbaca
// ditampilkan sebagai rusak (bukan crash) dan tetap bisa dihapus.
//
// Muat slot: berkas slot divalidasi dulu, disalin ke path utama
// (sovereign_save_v1.json, sama dengan GameController), lalu
// GameController.load() dipanggil — tanpa menyentuh state/data/engine.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/save_v1.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'format.dart';

/// Jumlah slot tetap agar UX sentuh sederhana & jujur.
const int saveSlotCount = 3;

String _slotName(int i) => 'sovereign_save_slot_$i.json';
const String _mainName = 'sovereign_save_v1.json';

class _SlotView {
  final int index;
  final String path;
  final bool exists;
  final SaveData? data;
  final DateTime? modified;
  final String? error;
  const _SlotView({
    required this.index,
    required this.path,
    required this.exists,
    this.data,
    this.modified,
    this.error,
  });
}

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  bool _loading = true;
  String? _dirError;
  List<_SlotView> _slots = const [];
  _SlotView? _main;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<Directory?> _docsDir() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      _dirError = '$e';
      return null;
    }
  }

  Future<_SlotView> _readSlot(Directory dir, int index) async {
    final path = '${dir.path}/${_slotName(index)}';
    return _readFile(path, index: index);
  }

  Future<_SlotView> _readMain(Directory dir) async {
    final path = '${dir.path}/$_mainName';
    return _readFile(path, index: 0);
  }

  /// Baca satu berkas secara defensif: hilang/rusak/versi-beda
  /// tidak pernah melempar — dikemas jadi view dengan [error].
  Future<_SlotView> _readFile(String path, {required int index}) async {
    final file = File(path);
    bool exists = false;
    try {
      exists = await file.exists();
    } catch (e) {
      return _SlotView(
          index: index, path: path, exists: false, error: '$e');
    }
    if (!exists) {
      return _SlotView(index: index, path: path, exists: false);
    }
    DateTime? modified;
    try {
      modified = await file.lastModified();
    } catch (_) {
      modified = null;
    }
    try {
      final data = await SaveV1.loadFromFile(path);
      return _SlotView(
          index: index,
          path: path,
          exists: true,
          data: data,
          modified: modified);
    } catch (e) {
      // Fallback cantik: API/field berubah aditif atau berkas korup
      // → tampilkan sebagai tak-terbaca, tetap bisa dihapus/ditimpa.
      return _SlotView(
          index: index,
          path: path,
          exists: true,
          modified: modified,
          error: '$e');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _dirError = null;
    });
    final dir = await _docsDir();
    if (dir == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final slots = <_SlotView>[];
    for (var i = 1; i <= saveSlotCount; i++) {
      slots.add(await _readSlot(dir, i));
    }
    final main = await _readMain(dir);
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _main = main;
      _loading = false;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<bool> _confirm(
      String title, String body, String okLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body,
            style: const TextStyle(
                color: SovereignColors.muted,
                fontSize: 13,
                height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SovereignColors.cyan,
              minimumSize: const Size(0, 48),
            ),
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _saveSlot(_SlotView slot) async {
    if (slot.exists) {
      final ok = await _confirm('Timpa Slot ${slot.index}?',
          'Simpanan lama di slot ini akan diganti dengan kondisi permainan sekarang.',
          'Ya, timpa');
      if (!ok) return;
      if (!mounted) return;
    }
    try {
      final c = context.read<GameController>();
      await SaveV1.saveToFile(
        slot.path,
        state: c.current,
        confirmed: c.confirmed,
        seed: c.seed,
        history: c.history,
        proposals: c.proposals,
        contracts: c.contracts,
        activeCountry: c.activeCountryId,
      );
      _snack('Slot ${slot.index} tersimpan.');
    } catch (e) {
      _snack('Gagal menyimpan slot ${slot.index}: $e');
    }
    await _refresh();
  }

  Future<void> _loadSlot(_SlotView slot) async {
    final ok = await _confirm('Muat Slot ${slot.index}?',
        'Permainan berjalan akan diganti dengan simpanan ini. Draf usulan ikut disetel ulang.',
        'Ya, muat');
    if (!ok) return;
    try {
      final file = File(slot.path);
      // Validasi dulu agar berkas rusak tidak menimpa simpanan utama.
      await SaveV1.loadFromFile(slot.path);
      final dir = await getApplicationDocumentsDirectory();
      await file.copy('${dir.path}/$_mainName');
      if (!mounted) return;
      await context.read<GameController>().load();
      _snack('Slot ${slot.index} dimuat — selamat melanjutkan.');
    } catch (e) {
      _snack('Gagal memuat slot ${slot.index}: $e');
    }
    await _refresh();
  }

  Future<void> _deleteSlot(_SlotView slot, String label) async {
    final ok = await _confirm('Hapus $label?',
        'Berkas simpanan akan dihapus permanen dari perangkat ini.', 'Ya, hapus');
    if (!ok) return;
    try {
      await File(slot.path).delete();
      _snack('$label dihapus.');
    } catch (e) {
      _snack('Gagal menghapus: $e');
    }
    await _refresh();
  }

  Future<void> _quickSave() async {
    try {
      final path = await context.read<GameController>().save();
      _snack('Tersimpan ke simpanan utama.');
      debugPrint('save utama: $path');
    } catch (e) {
      _snack('Gagal menyimpan: $e');
    }
    await _refresh();
  }

  Future<void> _quickLoad() async {
    final ok = await _confirm('Muat simpanan utama?',
        'Permainan berjalan akan diganti dengan simpanan utama terakhir.',
        'Ya, muat');
    if (!ok) return;
    if (!mounted) return;
    try {
      await context.read<GameController>().load();
      _snack('Simpanan utama dimuat.');
    } catch (e) {
      _snack('Gagal memuat: $e');
    }
    await _refresh();
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
            Text('Simpan / Muat',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Slot lokal di perangkat ini',
                style: TextStyle(
                    color: SovereignColors.muted, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang daftar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: SovereignColors.cyan),
                    SizedBox(height: 12),
                    Text('Memindai slot simpanan…',
                        style: TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 13)),
                  ],
                ),
              )
            : _dirError != null
                ? _DirErrorView(
                    error: _dirError!,
                    onRetry: _refresh,
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          SovereignSpacing.margin,
                          12,
                          SovereignSpacing.margin,
                          20),
                      children: [
                        if (_slots.every((s) => !s.exists))
                          const _EmptyBox(),
                        for (final s in _slots) ...[
                          _SlotCard(
                            slot: s,
                            onSave: () => _saveSlot(s),
                            onLoad: s.exists && s.error == null
                                ? () => _loadSlot(s)
                                : null,
                            onDelete: s.exists
                                ? () => _deleteSlot(
                                    s, 'Slot ${s.index}')
                                : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 4),
                        const Text(
                          'SIMPANAN UTAMA • OTOMATIS',
                          style: TextStyle(
                            color: SovereignColors.mutedDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MainCard(
                          main: _main,
                          onSave: _quickSave,
                          onLoad: _quickLoad,
                          onDelete: _main != null && _main!.exists
                              ? () => _deleteSlot(
                                  _main!, 'Simpanan utama')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Slot tersimpan sebagai berkas JSON berversi di dokumen aplikasi. '
                          'Berkas tak-terbaca (versi beda/rusak) tidak merusak permainan — hapus atau timpa saja.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: SovereignColors.mutedDim,
                              fontSize: 12,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ── Kartu slot ────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final _SlotView slot;
  final VoidCallback onSave;
  final VoidCallback? onLoad;
  final VoidCallback? onDelete;
  const _SlotCard({
    required this.slot,
    required this.onSave,
    this.onLoad,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final filled = slot.exists && slot.error == null && slot.data != null;
    final broken = slot.exists && slot.error != null;
    return Container(
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1436C5F0),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: SovereignColors.border),
                ),
                child: Icon(
                  filled
                      ? Icons.save_rounded
                      : broken
                          ? Icons.warning_amber_rounded
                          : Icons.save_outlined,
                  color: filled
                      ? SovereignColors.cyan
                      : broken
                          ? SovereignColors.amber
                          : SovereignColors.muted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Slot ${slot.index}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      filled
                          ? '${formatQuarter(slot.data!.state.quarter)} • ${formatCompactUsd(slot.data!.state.gdp)}${_dateSuffix(slot.modified)}'
                          : broken
                              ? 'Berkas tak-terbaca — versi beda atau rusak.'
                              : 'Kosong — belum ada simpanan.',
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: SovereignColors.muted, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
          if (broken)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Rincian: ${slot.error}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SovereignColors.mutedDim,
                      fontSize: 11)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: SovereignSpacing.touchMin,
                  child: OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.download_rounded,
                        size: 18),
                    label: Text(slot.exists ? 'Timpa' : 'Simpan'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: SovereignSpacing.touchMin,
                  child: ElevatedButton.icon(
                    onPressed: onLoad,
                    icon: const Icon(Icons.upload_rounded,
                        size: 18),
                    label: const Text('Muat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SovereignColors.cyan,
                      foregroundColor: SovereignColors.deepNavy,
                      disabledBackgroundColor:
                          SovereignColors.border,
                      disabledForegroundColor:
                          SovereignColors.mutedDim,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateSuffix(DateTime? m) {
    if (m == null) return '';
    return ' • ${_fmtDate(m)}';
  }
}

// ── Kartu simpanan utama ──────────────────────────────────────────

class _MainCard extends StatelessWidget {
  final _SlotView? main;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback? onDelete;
  const _MainCard({
    required this.main,
    required this.onSave,
    required this.onLoad,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = main;
    final d = m?.data;
    final filled =
        m != null && m.exists && m.error == null && d != null;
    final broken = m != null && m.exists && m.error != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavySoft,
        borderRadius:
            BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin_outlined,
                  color: SovereignColors.muted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filled
                      ? '${formatQuarter(d.state.quarter)} • ${formatCompactUsd(d.state.gdp)}'
                      : broken
                          ? 'Berkas utama tak-terbaca.'
                          : 'Belum ada simpanan utama.',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Hapus simpanan utama',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: SovereignColors.muted, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: SovereignSpacing.touchMin,
                  child: OutlinedButton(
                      onPressed: onSave,
                      child: const Text('Simpan sekarang')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: SovereignSpacing.touchMin,
                  child: OutlinedButton(
                      onPressed: filled ? onLoad : null,
                      child: const Text('Muat')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty & error states yang jujur ───────────────────────────────

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0F22C55E),
        borderRadius:
            BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: const Color(0x3322C55E)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: SovereignColors.green, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Belum ada simpanan slot',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text(
                  'Mainkan dulu beberapa kuartal, lalu tekan Simpan di salah satu slot di bawah.',
                  style: TextStyle(
                      color: SovereignColors.muted,
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _DirErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SovereignSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined,
                color: SovereignColors.amber, size: 40),
            const SizedBox(height: 12),
            const Text('Penyimpanan tak dapat diakses.',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: SovereignColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              height: SovereignSpacing.touchMin,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime m) {
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${p2(m.day)}/${p2(m.month)}/${m.year} ${p2(m.hour)}:${p2(m.minute)}';
}
