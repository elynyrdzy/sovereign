# SOVEREIGN — The Resource Economy (Fase 0: Prototype Ekonomi)

Turn-based grand strategy / economic management sim. Pemain mengelola ekonomi
1 negara selama 10 kuartal dengan 5 komoditas dan 5 tuas kebijakan.

## Status Fase 0

- Engine: Flutter (Dart) 3.44.7. Sim murni-Dart tanpa import Flutter
  (`lib/sim/`, `lib/models/`) agar deterministik & testable.
- 1 negara (Indonesia), 5 komoditas (beras, minyak, batubara, nikel,
  semikonduktor), 5 kebijakan (pajak, belanja, bunga, tarif_impor,
  subsidi_ekspor), 2 event seeded (Krisis Energi +40%, Gagal Panen −20%).
- Urutan kuartal 11 langkah (sementara): load confirmed+seed → fiskal →
  moneter → produksi → dagang → GDP=C+I+G+(X−M) → inflasi → pengangguran →
  indeks → event seeded → snapshot+save. Rounding 2 desimal, seeded RNG,
  tanpa `DateTime.now()` di sim.
- Save: JSON file `version: 1` (`lib/data/save_v1.dart`).
- Tanpa UI (`lib/ui/` belum ada — ranah @designer).

## Struktur

```text
lib/
  sim/            engine.dart, formulas.dart (SEMENTARA), rng.dart
  models/         country.dart, commodity.dart, policy.dart,
                  quarter_state.dart, result.dart, game_event.dart
  state/          game_controller.dart (ChangeNotifier minimal)
  data/           save_v1.dart
  main.dart       placeholder (diganti @designer)
assets/config/    countries.json, commodities.json, policies.json, events.json
test/             sim_test.dart
docs/             blueprint.md, ui.md (jangan hapus)
```

## Cara jalan

```bash
flutter pub get
flutter test
flutter run   # placeholder Fase 0, UI menyusul
```

## Catatan

- Semua angka config di `assets/config/`; sim tidak punya magic number
  tanpa konstanta bernama + komentar.
- Formula di `lib/sim/formulas.dart` bertanda SEMENTARA — akan di-tuning
  di fase balancing.
