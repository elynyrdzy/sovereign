// Engine simulasi kuartal — murni Dart, deterministik, tanpa DateTime.now().
// Urutan 11 langkah (sementara, sesuai Decision Lock):
//  1 load confirmed+seed → 2 fiskal → 3 moneter → 4 produksi → 5 dagang →
//  6 GDP=C+I+G+(X-M) → 7 inflasi → 8 pengangguran → 9 indeks →
//  10 event seeded → 11 snapshot+save (save dilakukan caller via save_v1).
import '../models/commodity.dart';
import '../models/country.dart';
import '../models/game_event.dart';
import '../models/policy.dart';
import '../models/quarter_state.dart';
import '../models/result.dart';
import '../models/trade.dart';
import 'formulas.dart';
import 'rng.dart';

/// Hasil sekali aplikasi kontrak dagang bilateral (murni).
class TradeApplyResult {
  final QuarterState state;
  final String log;
  const TradeApplyResult({required this.state, required this.log});
}

class SimEngine {
  // Baseline suku bunga acuan untuk respons investasi/inflasi (SEMENTARA).
  static const double baseRateRef = 0.06;

  // Konversi nilai dagang ke devisa (SEMENTARA, belum balancing final).
  // Unifikasi semua kanal FX (kontrak ekspor/impor, impor darurat, net X-M)
  // ke satu konstanta agar tuning satu pintu.
  // TODO(balancing): kalibrasi kFxPerValue terhadap target cadangan devisa
  // dan neraca dagang (lihat blueprint §12); nilai 0.01 sementara.
  static const double kFxPerValue = 0.01;

  // Multi-negara read-only Fase 1 (SEMENTARA, aditif, tidak ubah 11 langkah).
  // Negara aktif tetap yang dimainkan (Indonesia); negara lain hanya data
  // statis dari countries.json untuk tampilan/analisis.
  // Surplus bila komoditas ada di resources, defisit bila di import_needs,
  // selain itu netral. Murni & deterministik.
  // TODO(Fase-2): world-price & dagang bilateral bila balancing siap.
  static Map<String, String> countryOutlook(
    Country country,
    List<Commodity> commodities,
  ) {
    final out = <String, String>{};
    for (final c in commodities) {
      if (country.resources.contains(c.id)) {
        out[c.id] = 'surplus';
      } else if (country.importNeeds.contains(c.id)) {
        out[c.id] = 'defisit';
      } else {
        out[c.id] = 'netral';
      }
    }
    return out;
  }

  /// Terapkan SATU kontrak dagang bilateral ke [state] secara murni.
  ///
  /// Sumber tunggal negara: arah ditentukan dari [state.countryId] (bukan
  /// activeCountryId; itu hanya filter UI/outlook di controller — ora-2(1)).
  /// Bila sama dengan `contract.fromCountry` => ekspor (stok −, exports +,
  /// fx += nilai*kFxPerValue); bila sama dengan `contract.toCountry` => impor
  /// (stok +, imports +, fx −= nilai*kFxPerValue, dijaga >= 0); bila tidak
  /// menyentuh negara state => no-op konsisten (state disalin, log transit).
  /// - Ekspor dijepit ke stok tersedia agar tidak negatif (vol aktual yang
  ///   dinilai). Bila stok tak cukup (partial-fill) dicatat di log
  ///   `partial-fill(butuh=..,ada=..)`; caller (processQuarter) melipatnya
  ///   ke warnings (ora-2(2)). Nilai = round2(volAktual * price).
  /// - [price] adalah harga per unit efektif (biasanya harga pasar berjalan
  ///   `prices[commodityId]`, fallback `contract.pricePerUnit` di caller).
  ///   Harus > 0 finite, bila tidak lempar ArgumentError.
  /// - [terms] adalah syarat dagang (trade_terms, default 0 = no-op agar tak
  ///   nerf diam-diam): fxEkspor *= (1-terms*0.5), fxImpor *= (1+terms).
  ///   Auto-trade (surplus/defisit) tetap memakai tarif/subsidi saja agar
  ///   tidak double-stack (ora-2(4)). Harus finite >= 0.
  /// - Mengembalikan [TradeApplyResult] berisi state baru (tervalidasi) +
  ///   log `'q<state.quarter>/dagang ...'` untuk audit.
  ///
  /// Dipakai `processQuarter` (langkah 5, dilipat ke log dagang agar tetap
  /// 11 langkah) dan dapat dipakai langsung @designer/UI preview.
  static TradeApplyResult applyTrade(
    QuarterState state,
    TradeContract contract,
    double price, {
    double terms = 0,
  }) {
    state.validate();
    contract.validate();
    if (price.isNaN || price.isInfinite || price <= 0) {
      throw ArgumentError('price harus > 0 finite (was $price)');
    }
    if (terms.isNaN || terms.isInfinite || terms < 0) {
      throw ArgumentError('terms harus finite >= 0 (was $terms)');
    }
    final isExport = contract.fromCountry == state.countryId;
    final isImport = contract.toCountry == state.countryId;
    if (isExport && isImport) {
      throw ArgumentError('Kontrak domestik tidak didukung: ${contract.id}');
    }
    final stocks = Map<String, double>.of(state.stocks);
    var exports = state.exports;
    var imports = state.imports;
    var fx = state.fxReserves;
    final String kind;
    final double value;
    String partialNote = '';
    if (isExport) {
      final avail = stocks[contract.commodityId] ?? 0;
      final vol = avail >= contract.qty ? contract.qty : avail;
      if (vol < contract.qty) {
        partialNote =
            ' partial-fill(butuh=${contract.qty},ada=$avail,vol=$vol)';
      }
      final effValue = round2(vol * price);
      stocks[contract.commodityId] = round2(avail - vol);
      exports = round2(exports + effValue);
      fx = round2(fx + effValue * kFxPerValue * (1 - terms * 0.5));
      if (fx < 0) fx = 0;
      kind = 'ekspor';
      value = effValue;
    } else if (isImport) {
      final prev = stocks[contract.commodityId] ?? 0;
      final effValue = round2(contract.qty * price);
      stocks[contract.commodityId] = round2(prev + contract.qty);
      imports = round2(imports + effValue);
      fx = round2(fx - effValue * kFxPerValue * (1 + terms));
      if (fx < 0) fx = 0;
      kind = 'impor';
      value = effValue;
    } else {
      kind = 'transit';
      value = round2(contract.qty * price);
    }
    final next = state.copyWith(
      exports: exports,
      imports: imports,
      fxReserves: fx,
      stocks: stocks,
    );
    next.validate();
    final log = 'q${state.quarter}/dagang $kind '
        '${contract.qty}x${contract.commodityId} '
        '${contract.fromCountry}->${contract.toCountry} '
        'nilai=$value fx=$fx terms=$terms$partialNote';
    return TradeApplyResult(state: next, log: log);
  }

  QuarterResult processQuarter({
    required QuarterState state,
    required PolicySet confirmed,
    required int seed,
    required List<Commodity> commodities,
    required List<GameEvent> events,
    List<PolicyDefinition>? policyDefs,
    // Kontrak bilateral aktif (ADITIF, default kosong = perilaku lama).
    // Hanya yang [TradeContract.isActiveFor](nextQuarter) diterapkan,
    // via [applyTrade], dilipat ke log langkah-5 agar tetap 11 langkah.
    List<TradeContract> tradeContracts = const [],
  }) {
    final logs = <String>[];
    final warnings = <String>[];
    final triggered = <String>[];

    // Cegah double-apply: kuartal yang sama + seed sama tidak boleh diproses
    // dua kali dari state yang sudah berisi appliedEvents kuartal tujuan.
    final nextQuarter = state.quarter + 1;
    if (state.appliedEvents.any((e) => e.startsWith('q$nextQuarter:'))) {
      throw StateError('Kuartal $nextQuarter sudah diterapkan (double-apply)');
    }
    state.validate();
    if (policyDefs != null) confirmed.validate(policyDefs);

    // Langkah 1: load confirmed + seed (RNG = seed + quarter, deterministik).
    final rng = SeededRng(seed + nextQuarter);
    final taxRate = confirmed.values['pajak'] ?? state.taxRate;
    final spending = confirmed.values['belanja'] ?? state.govSpending;
    final rate = confirmed.values['bunga'] ?? state.interestRate;
    final tariff = confirmed.values['tarif_impor'] ?? 0.1;
    final subsidy = confirmed.values['subsidi_ekspor'] ?? 0.05;
    // trade_terms: default 0 (no-op) bila kunci tak ada — sengaja BUKAN 0.1
    // agar tidak nerf diam-diam sebelum balancing (ora-2(4)). Hanya dipakai
    // kanal kontrak bilateral via applyTrade(terms:); auto-trade di bawah
    // tetap tarif/subsidi agar tidak double-stack.
    final double terms = confirmed.values['trade_terms'] ?? 0.0;
    logs.add('q$nextQuarter/load confirmed(pajak=$taxRate,belanja=$spending,'
        'bunga=$rate,tarif=$tariff,subsidi=$subsidy,terms=$terms) seed=${seed + nextQuarter}');

    // Langkah 2: fiskal — penerimaan, defisit, utang.
    final revenue = fiscalRevenue(state.gdp, taxRate);
    final deficit = fiscalDeficit(spending, revenue);
    final debtToGdp = debtToGdpUpdate(state.debtToGdp, deficit, state.gdp);
    // Kas devisa terpengaruh defisit ringan (SEMENTARA).
    var fx = round2(state.fxReserves - deficit * 0.05);
    if (fx < 0) {
      warnings.add('Devisa habis; dijaga 0 (was $fx)');
      fx = 0;
    }
    logs.add('q$nextQuarter/fiskal revenue=$revenue deficit=$deficit '
        'debtToGdp=$debtToGdp');

    // Langkah 3: moneter — respons investasi & efek inflasi awal.
    final investBase = state.investment;
    final investment =
        investmentAfterRate(investBase, rate, baseRateRef);
    final rateEffect = monetaryInflationDelta(rate, baseRateRef);
    final consumption = consumptionAfterTax(state.consumption, taxRate);
    logs.add('q$nextQuarter/moneter investment=$investment rateEffect=$rateEffect'
        ' consumption=$consumption');

    // Langkah 4: produksi — output + konsumsi per komoditas update stok.
    final stocks = Map<String, double>.of(state.stocks);
    final prices = Map<String, double>.of(state.prices);
    for (final c in commodities) {
      final prevStock = stocks[c.id] ?? 0;
      final prevPrice = prices[c.id] ?? c.baseGlobalPrice;
      // Event produksi (mis. gagal panen −20%) diterapkan di langkah 10,
      // tapi efek produksi dihitung di sini untuk event yang trigger
      // kuartal ini agar stok konsisten — dicatat eksplisit.
      double prodFactor = 0;
      final output = commodityOutput(
          kBaseOutputPerQuarter + rng.shock(kBaseOutputPerQuarter * 0.02),
          prodFactor);
      final use = round2(kBaseConsumptionPerQuarter *
          (1.0 + rng.shock(0.02)) *
          (1.0 + state.inflation * 0.5));
      var next = round2(prevStock + output - use);
      if (next < 0) {
        warnings.add('Stok ${c.id} habis (kelangkaan); dijaga 0');
        next = 0;
      }
      stocks[c.id] = next;
      // Harga global bergerak kecil + shock seeded (SEMENTARA).
      prices[c.id] = round2(
          (prevPrice * (1.0 + rng.shock(kPriceShockMagnitude)))
              .clamp(c.baseGlobalPrice * 0.3, c.baseGlobalPrice * 4.0));
    }
    logs.add('q$nextQuarter/produksi stok=${stocks.toString()}');

    // Langkah 5: dagang — ekspor surplus, impor defisit; update devisa.
    // (SEMENTARA: tiap komoditas surplus => ekspor, defisit => impor darurat.)
    // Auto-trade memakai tarif/subsidi saja (hindari double-stack trade_terms).
    // TODO(balancing): kalibrasi buffer 800/vol 0.5 + kFxPerValue (ora-2(2)).
    double totalX = 0;
    double totalM = 0;
    for (final c in commodities) {
      final stock = stocks[c.id] ?? 0;
      final price = prices[c.id] ?? c.baseGlobalPrice;
      const targetBuffer = 800.0; // Stok aman kuartalan (SEMENTARA).
      if (stock > targetBuffer) {
        final vol = round2((stock - targetBuffer) * 0.5);
        final value = round2(vol * price * (1.0 + subsidy * kSubsidyExportFactor));
        totalX = round2(totalX + value);
        stocks[c.id] = round2(stock - vol);
      } else if (stock < targetBuffer * 0.5) {
        final vol = round2(targetBuffer * 0.5 - stock);
        final effPrice = round2(price * (1.0 + tariff));
        final value = round2(vol * effPrice);
        totalM = round2(totalM + value);
        stocks[c.id] = round2(stock + vol);
        // Impor darurat menguras devisa via kFxPerValue (SEMENTARA, ora-2(2)).
        fx = round2(fx - value * kFxPerValue);
        if (fx < 0) fx = 0;
      }
    }
    final exportsBase =
        round2(state.exports * 0.7 + totalX * 0.3 + totalX * 0.7);
    final importsBase =
        round2(state.imports * 0.7 + totalM * 0.3 + totalM * 0.7);
    var exports = exportsBase;
    var imports = importsBase;
    fx = round2(fx + (exports - imports) * kFxPerValue);
    if (fx < 0) fx = 0;
    // Kontrak bilateral aktif (ADITIF): diterapkan via applyTrade murni
    // agar exports/imports/fxReserves/stocks konsisten satu sumber.
    // Dilipat ke log langkah-5 ini supaya processQuarter tetap 11 langkah
    // (tidak menambah entri log per kontrak). trade_terms (terms) hanya
    // berlaku di kanal kontrak ini; auto-trade di atas tidak kena terms.
    final contractNotes = <String>[];
    if (tradeContracts.isNotEmpty) {
      var interim = state.copyWith(
        exports: exports,
        imports: imports,
        fxReserves: fx,
        stocks: Map<String, double>.of(stocks),
        prices: Map<String, double>.of(prices),
      );
      for (final tc in tradeContracts) {
        if (!tc.isActiveFor(nextQuarter)) continue;
        final effPrice = prices[tc.commodityId] ?? tc.pricePerUnit;
        final applied = applyTrade(interim, tc, effPrice, terms: terms);
        interim = applied.state;
        contractNotes.add('${tc.commodityId}:${tc.qty}@$effPrice');
        if (applied.log.contains('partial-fill')) {
          warnings.add(
              'Ekspor partial-fill ${tc.commodityId} ${tc.id}: ${applied.log}');
        }
      }
      exports = interim.exports;
      imports = interim.imports;
      fx = interim.fxReserves;
      stocks
        ..clear()
        ..addAll(interim.stocks);
    }
    logs.add(
        'q$nextQuarter/dagang X=$exports M=$imports fx=$fx terms=$terms${contractNotes.isEmpty ? '' : ' kontrak[${contractNotes.join(',')}]'}');

    // Langkah 6: GDP = C + I + G + (X − M).
    final gdp = gdpCompute(consumption, investment, spending, exports, imports);
    final growth = growthRate(gdp, state.gdp);
    logs.add('q$nextQuarter/gdp=$gdp growth=$growth');

    // Langkah 7: inflasi.
    final demandGap = growth; // (SEMENTARA: growth sebagai proksi demand gap).
    final importEffect = totalM > 0 && state.gdp > 0
        ? round2((totalM / safeDenom(state.gdp)) * 10.0)
        : 0.0;
    final inflation = inflationUpdate(
      prev: state.inflation,
      demandGap: demandGap,
      importPriceEffect: importEffect,
      rateEffect: rateEffect,
    );
    logs.add('q$nextQuarter/inflasi=$inflation');

    // Langkah 8: pengangguran.
    final unemployment = unemploymentUpdate(state.unemployment, growth);
    logs.add('q$nextQuarter/pengangguran=$unemployment');

    // Langkah 9: indeks kemakmuran.
    final prosperity = prosperityIndex(
      inflation: inflation,
      unemployment: unemployment,
      debtToGdp: debtToGdp,
      growth: growth,
    );
    logs.add('q$nextQuarter/indeks=$prosperity');

    // Langkah 10: event seeded (deterministik via trigger quarter + rng).
    final applied = <String>[];
    for (final e in events) {
      final key = 'q$nextQuarter:${e.id}';
      if (e.triggersOn(nextQuarter)) {
        triggered.add(e.id);
        applied.add(key);
        for (final pe in e.priceEffects.entries) {
          if (!prices.containsKey(pe.key)) continue;
          prices[pe.key] = round2(prices[pe.key]! * (1.0 + pe.value));
        }
        for (final pr in e.productionEffects.entries) {
          if (!stocks.containsKey(pr.key)) continue;
          // Gagal panen −20%: kurangi stok proporsional (SEMENTARA).
          stocks[pr.key] =
              round2((stocks[pr.key]! * (1.0 + pr.value)).clamp(0, 1e12));
        }
        // event dicatat ringkas setelah loop agar log tetap 11 langkah;
      }
    }

    logs.add(
        'q$nextQuarter/event ${triggered.isEmpty ? "nihil" : triggered.join(",")} diterapkan');
    // Langkah 11: snapshot (save dilakukan caller).
    final next = QuarterState(
      quarter: nextQuarter,
      countryId: state.countryId,
      gdp: gdp <= 0 ? 1.0 : gdp,
      inflation: inflation,
      unemployment: unemployment,
      debtToGdp: debtToGdp,
      fxReserves: fx,
      consumption: consumption,
      investment: investment,
      govSpending: round2(spending),
      exports: exports,
      imports: imports,
      interestRate: rate,
      taxRate: taxRate,
      stocks: stocks,
      prices: prices,
      prosperity: prosperity,
      appliedEvents: applied,
    );
    next.validate();
    logs.add('q$nextQuarter/snapshot ok');

    return QuarterResult(
      prev: state,
      next: next,
      logs: logs,
      triggeredEvents: triggered,
      warnings: warnings,
    );
  }
}
