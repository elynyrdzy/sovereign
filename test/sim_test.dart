// Uji sim Fase 0 — murni logika, tanpa DateTime.now(), seeded RNG.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sovereign/data/save_v1.dart';
import 'package:sovereign/models/commodity.dart';
import 'package:sovereign/models/country.dart';
import 'package:sovereign/models/game_event.dart';
import 'package:sovereign/models/policy.dart';
import 'package:sovereign/models/quarter_state.dart';
import 'package:sovereign/models/trade.dart';
import 'package:sovereign/sim/engine.dart';
import 'package:sovereign/sim/formulas.dart';
import 'package:sovereign/state/game_controller.dart';

// --- Fixture bersama (tanpa memuat asset; deterministik) ---

List<PolicyDefinition> testPolicyDefs() => [
      const PolicyDefinition(
          id: 'pajak', name: 'Pajak', min: 0.05, max: 0.35, defaultValue: 0.15, unit: 'fraksi'),
      const PolicyDefinition(
          id: 'belanja',
          name: 'Belanja',
          min: 0,
          max: 200000000000,
          defaultValue: 80000000000,
          unit: 'USD_per_kuartal'),
      const PolicyDefinition(
          id: 'bunga', name: 'Bunga', min: 0.0, max: 0.2, defaultValue: 0.06, unit: 'fraksi'),
      const PolicyDefinition(
          id: 'tarif_impor',
          name: 'Tarif Impor',
          min: 0.0,
          max: 0.5,
          defaultValue: 0.1,
          unit: 'fraksi'),
      const PolicyDefinition(
          id: 'subsidi_ekspor',
          name: 'Subsidi Ekspor',
          min: 0.0,
          max: 0.3,
          defaultValue: 0.05,
          unit: 'fraksi'),
      // trade_terms default 0 (no-op) di fixture agar tak nerf diam-diam;
      // produksi memakai default asset 0.1 (ora-2(4)).
      const PolicyDefinition(
          id: 'trade_terms',
          name: 'Syarat Dagang',
          min: 0.0,
          max: 0.5,
          defaultValue: 0.0,
          unit: 'fraksi'),
    ];

List<Commodity> testCommodities() => [
      const Commodity(
          id: 'beras',
          category: 'pangan',
          baseGlobalPrice: 550,
          unit: 'USD_per_ton',
          strategicImportance: 0.9,
          usedBy: ['rumah_tangga'],
          producers: ['indonesia']),
      const Commodity(
          id: 'minyak',
          category: 'energi',
          baseGlobalPrice: 85,
          unit: 'USD_per_barrel',
          strategicImportance: 0.95,
          usedBy: ['transportasi'],
          producers: ['indonesia']),
      const Commodity(
          id: 'batubara',
          category: 'energi',
          baseGlobalPrice: 130,
          unit: 'USD_per_ton',
          strategicImportance: 0.7,
          usedBy: ['pembangkit'],
          producers: ['indonesia']),
      const Commodity(
          id: 'nikel',
          category: 'material_industri',
          baseGlobalPrice: 18000,
          unit: 'USD_per_ton',
          strategicImportance: 0.8,
          usedBy: ['bahan_baterai'],
          producers: ['indonesia']),
      const Commodity(
          id: 'semikonduktor',
          category: 'teknologi',
          baseGlobalPrice: 1200,
          unit: 'USD_per_unit_indeks',
          strategicImportance: 0.85,
          usedBy: ['elektronik'],
          producers: ['jepang']),
    ];

List<GameEvent> testEvents() => [
      const GameEvent(
        id: 'krisis_energi',
        name: 'Krisis Energi Global',
        description: 'Harga minyak dan gas naik 40%.',
        priceEffects: {'minyak': 0.4, 'batubara': 0.4},
        productionEffects: {},
        triggerQuarterMod: 4,
        triggerOffset: 2,
      ),
      const GameEvent(
        id: 'gagal_panen',
        name: 'Gagal Panen',
        description: 'Produksi pangan turun 20%.',
        priceEffects: {'beras': 0.25},
        productionEffects: {'beras': -0.2},
        triggerQuarterMod: 3,
        triggerOffset: 1,
      ),
    ];

QuarterState testInitial() {
  final commodities = testCommodities();
  return QuarterState.initial(
    countryId: 'indonesia',
    gdp: 1400000000000,
    inflation: 0.032,
    unemployment: 0.053,
    debtToGdp: 0.39,
    fxReserves: 140000000000,
    basePrices: {for (final c in commodities) c.id: c.baseGlobalPrice},
    initialStocks: {for (final c in commodities) c.id: 1000.0},
  );
}

void main() {
  final defs = testPolicyDefs();
  final commodities = testCommodities();
  final events = testEvents();
  const seed = 42;

  test('produksi+konsumsi memperbarui stok tanpa negatif', () {
    final engine = SimEngine();
    final confirmed = PolicySet.defaults(defs);
    final result = engine.processQuarter(
      state: testInitial(),
      confirmed: confirmed,
      seed: seed,
      commodities: commodities,
      events: const [],
      policyDefs: defs,
    );
    // Stok berubah (produksi − konsumsi ≠ 0) dan tetap valid.
    expect(result.next.stocks, isNotEmpty);
    for (final e in result.next.stocks.entries) {
      expect(e.value, greaterThanOrEqualTo(0),
          reason: 'stok ${e.key} negatif');
    }
    expect(result.next.stocks, isNot(equals(testInitial().stocks)));
    result.next.validate();
  });

  test('perdagangan memperbarui devisa dan ekspor/impor', () {
    final engine = SimEngine();
    final confirmed = PolicySet.defaults(defs);
    final prev = testInitial();
    final result = engine.processQuarter(
      state: prev,
      confirmed: confirmed,
      seed: seed,
      commodities: commodities,
      events: const [],
      policyDefs: defs,
    );
    // Salah satu dari devisa/ekspor/impor harus bergerak akibat dagang.
    final fxMoved = result.next.fxReserves != prev.fxReserves;
    final tradeMoved = result.next.exports != prev.exports ||
        result.next.imports != prev.imports;
    expect(fxMoved || tradeMoved, isTrue,
        reason: 'perdagangan tidak mengubah devisa maupun arus dagang');
    expect(result.next.fxReserves, greaterThanOrEqualTo(0));
    expect(result.logs.any((l) => l.contains('/dagang')), isTrue);
  });

  test('kebijakan mengubah state; draft tak-konfirmasi tidak mutasi', () {
    final controller = GameController(
      initial: testInitial(),
      commodities: commodities,
      events: events,
      policyDefs: defs,
      seed: seed,
    );
    final before = controller.current;
    // Draft saja — current tidak boleh berubah.
    controller.proposePolicy('bunga', 0.15);
    expect(controller.current.gdp, equals(before.gdp));
    expect(controller.current.quarter, equals(before.quarter));
    // Konfirmasi + proses dengan bunga tinggi vs bunga rendah.
    controller.confirmPolicies();
    final highRate = controller.processQuarter();

    final controller2 = GameController(
      initial: testInitial(),
      commodities: commodities,
      events: events,
      policyDefs: defs,
      seed: seed,
    );
    controller2.proposePolicy('bunga', 0.01);
    controller2.confirmPolicies();
    final lowRate = controller2.processQuarter();

    expect(highRate.next.investment,
        lessThanOrEqualTo(lowRate.next.investment),
        reason: 'bunga tinggi seharusnya menekan investasi');
    expect(highRate.next.quarter, equals(1));
  });

  test('GDP deterministik: seed sama = hasil sama', () {
    final engine = SimEngine();
    final confirmed = PolicySet.defaults(defs);
    QuarterState run() {
      var s = testInitial();
      for (var i = 0; i < 3; i++) {
        s = engine
            .processQuarter(
              state: s,
              confirmed: confirmed,
              seed: seed,
              commodities: commodities,
              events: events,
              policyDefs: defs,
            )
            .next;
      }
      return s;
    }

    final a = run();
    final b = run();
    expect(a.gdp, equals(b.gdp));
    expect(a.inflation, equals(b.inflation));
    expect(a.unemployment, equals(b.unemployment));
    expect(a.stocks, equals(b.stocks));
    expect(a.prices, equals(b.prices));
    // Sanity: GDP = C+I+G+(X-M) persis (2 desimal).
    expect(a.gdp,
        equals(gdpCompute(a.consumption, a.investment, a.govSpending, a.exports, a.imports)));
  });

  test('10 turn tanpa invalid state', () {
    final engine = SimEngine();
    final confirmed = PolicySet.defaults(defs);
    var s = testInitial();
    for (var i = 0; i < 10; i++) {
      final r = engine.processQuarter(
        state: s,
        confirmed: confirmed,
        seed: seed,
        commodities: commodities,
        events: events,
        policyDefs: defs,
      );
      expect(r.logs.length, equals(11),
          reason: 'log harus mencatat 11 langkah');
      r.next.validate();
      s = r.next;
    }
    expect(s.quarter, equals(10));
  });

  test('save/load round-trip mempertahankan state', () {
    final engine = SimEngine();
    final confirmed = PolicySet.defaults(defs);
    var s = testInitial();
    final history = <QuarterState>[];
    for (var i = 0; i < 2; i++) {
      history.add(s);
      s = engine
          .processQuarter(
            state: s,
            confirmed: confirmed,
            seed: seed,
            commodities: commodities,
            events: events,
            policyDefs: defs,
          )
          .next;
    }
    final raw =
        SaveV1.encode(state: s, confirmed: confirmed, seed: seed, history: history);
    final loaded = SaveV1.decode(raw);
    expect(loaded.seed, equals(seed));
    expect(loaded.state.quarter, equals(s.quarter));
    expect(loaded.state.gdp, equals(s.gdp));
    expect(loaded.state.stocks, equals(s.stocks));
    expect(loaded.state.prices, equals(s.prices));
    expect(loaded.history.length, equals(history.length));
    // Versi salah ditolak.
    final bad = jsonDecode(raw) as Map<String, dynamic>;
    bad['version'] = 999;
    expect(() => SaveV1.decode(jsonEncode(bad)), throwsFormatException);
  });

  test('config JSON bawaan valid dan lengkap Fase 1', () {
    final countriesRaw =
        File('assets/config/countries.json').readAsStringSync();
    final commoditiesRaw =
        File('assets/config/commodities.json').readAsStringSync();
    final policiesRaw =
        File('assets/config/policies.json').readAsStringSync();
    final eventsRaw = File('assets/config/events.json').readAsStringSync();

    final countries = (jsonDecode(countriesRaw) as List)
        .map((e) => Country.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final parsedCommodities = (jsonDecode(commoditiesRaw) as List)
        .map((e) => Commodity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final parsedPolicies = (jsonDecode(policiesRaw) as List)
        .map((e) => PolicyDefinition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final parsedEvents = (jsonDecode(eventsRaw) as List)
        .map((e) => GameEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    expect(countries.length, equals(3));
    expect(countries.first.id, equals('indonesia'));
    // Fase 1: Jepang + Brasil aditif; aktif tetap Indonesia (urutan pertama).
    expect(countries.map((c) => c.id).toList(),
        containsAll(['indonesia', 'jepang', 'brasil']));
    expect(parsedCommodities.length, equals(10));
    expect(parsedCommodities.map((c) => c.id).toList(),
        containsAll(['gas', 'gandum', 'tembaga', 'besi_baja', 'mesin_industri']));
    expect(parsedPolicies.length, greaterThanOrEqualTo(5));
    expect(parsedEvents.length, equals(7));
    // Policy default berada dalam [min,max].
    for (final p in parsedPolicies) {
      expect(p.defaultValue, greaterThanOrEqualTo(p.min));
      expect(p.defaultValue, lessThanOrEqualTo(p.max));
    }
    // Fase 1: id existing tidak berubah/hilang (backward-compatible).
    expect(parsedCommodities.map((c) => c.id).toList(),
        containsAll(['beras', 'minyak', 'batubara', 'nikel', 'semikonduktor']));
    // Dagang aditif: id kebijakan lama tak berubah + trade_terms tersedia.
    expect(parsedPolicies.map((p) => p.id).toList(),
        containsAll(['pajak', 'belanja', 'bunga', 'tarif_impor', 'subsidi_ekspor']));
    expect(parsedPolicies.map((p) => p.id), contains('trade_terms'));
    // Fase 1: event baru ringan (SEMENTARA) — efek harga/produksi kecil.
    final newEventIds = [
      'lonjakan_gas',
      'panen_gandum_baik',
      'permintaan_tembaga',
      'rantai_pasok_mesin',
      'baja_murah'
    ];
    for (final id in newEventIds) {
      expect(parsedEvents.map((e) => e.id), contains(id));
    }
    for (final e in parsedEvents) {
      if (newEventIds.contains(e.id)) {
        for (final v in e.priceEffects.values) {
          expect(v.abs(), lessThanOrEqualTo(0.15),
              reason: 'event ${e.id} harus ringan <=15%');
        }
        for (final v in e.productionEffects.values) {
          expect(v.abs(), lessThanOrEqualTo(0.15),
              reason: 'event ${e.id} harus ringan <=15%');
        }
      }
    }
  });

  test('multi-negara read-only: aktif tetap Indonesia + outlook surplus/defisit', () {
    final countriesRaw =
        File('assets/config/countries.json').readAsStringSync();
    final countries = (jsonDecode(countriesRaw) as List)
        .map((e) => Country.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final controller = GameController(
      initial: testInitial(),
      commodities: commodities,
      events: events,
      policyDefs: defs,
      seed: seed,
      allCountries: countries,
    );
    // Negara aktif tetap Indonesia.
    expect(controller.activeCountryId, equals('indonesia'));
    expect(controller.findCountry('jepang')?.id, equals('jepang'));
    expect(controller.findCountry('brasil')?.id, equals('brasil'));
    expect(controller.otherCountries.map((c) => c.id),
        containsAll(['jepang', 'brasil']));
    // Outlook sederhana: jepang surplus semikonduktor, defisit minyak.
    final outlookJp = SimEngine.countryOutlook(
        countries.firstWhere((c) => c.id == 'jepang'), commodities);
    // testCommodities hanya 5 (tanpa gas/dll); cek yang ada di fixture.
    expect(outlookJp['semikonduktor'], equals('surplus'));
    // outlookFor via controller konsisten dengan statik engine.
    expect(controller.outlookFor('jepang')['semikonduktor'],
        equals('surplus'));
    // Negara tak dikenal -> map kosong (read-only aman).
    expect(controller.outlookFor('atlantis'), isEmpty);
  });

  test('dagang: proposal→accept→apply mengubah devisa/stok', () {
    final countriesRaw =
        File('assets/config/countries.json').readAsStringSync();
    final countries = (jsonDecode(countriesRaw) as List)
        .map((e) => Country.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final controller = GameController(
      initial: testInitial(),
      commodities: commodities,
      events: const [],
      policyDefs: defs,
      seed: seed,
      allCountries: countries,
    );
    expect(controller.activeCountryId, equals('indonesia'));
    final before = controller.current;
    // Draft tidak mutasi sim. ora-2(1): validasi memakai state.countryId.
    final draft = controller.proposeTrade(
      fromCountry: 'indonesia',
      toCountry: 'jepang',
      commodityId: 'beras',
      qty: 100,
      pricePerUnit: 550,
    );
    expect(draft.status, equals(TradeStatus.proposal));
    // ora-2(3): id monoton t{q}_{seq}.
    expect(draft.id, startsWith('t0_'));
    expect(controller.current.stocks, equals(before.stocks));
    expect(controller.current.fxReserves, equals(before.fxReserves));
    // Validasi model menolak qty/price invalid.
    expect(
        () => controller.proposeTrade(
              fromCountry: 'indonesia',
              toCountry: 'jepang',
              commodityId: 'beras',
              qty: 0,
              pricePerUnit: 550,
            ),
        throwsA(anything));
    // Accept: proposal→accepted + kontrak terbentuk, sim tetap belum berubah.
    final contract = controller.acceptTrade(draft.id);
    expect(controller.proposals
        .firstWhere((e) => e.id == draft.id)
        .status, equals(TradeStatus.accepted));
    expect(controller.contracts.map((c) => c.id), contains(contract.id));
    // ora-2(3): kontrak id c_{proposalId}_{startQ}.
    expect(contract.id, equals('c_${draft.id}_1'));
    expect(contract.isActiveFor(1), isTrue);
    expect(controller.current.stocks, equals(before.stocks));
    // Apply murni via engine: ekspor mengurangi stok, menaikkan exports+fx.
    // ora-2(2): kanal FX terunifikasi via SimEngine.kFxPerValue.
    expect(SimEngine.kFxPerValue, equals(0.01));
    final price = 550.0;
    final applied = SimEngine.applyTrade(before, contract, price);
    expect(applied.log, contains('/dagang'));
    expect(applied.log, contains('terms=0'));
    expect(applied.state.stocks['beras'],
        equals((before.stocks['beras'] ?? 0) - contract.qty));
    expect(applied.state.exports, greaterThan(before.exports));
    expect(applied.state.fxReserves, greaterThanOrEqualTo(before.fxReserves));
    // ora-2(2): partial-fill saat stok tak cukup dicatat di log.
    final overContract = TradeContract(
      id: 'c_over_1',
      proposalId: 'over',
      fromCountry: 'indonesia',
      toCountry: 'jepang',
      commodityId: 'beras',
      qty: (before.stocks['beras'] ?? 0) + 5000,
      pricePerUnit: 550,
      startQuarter: 1,
      durationQuarters: 1,
    );
    final overApplied = SimEngine.applyTrade(before, overContract, price);
    expect(overApplied.log, contains('partial-fill'));
    expect(overApplied.state.stocks['beras'], equals(0));
    // ora-2(4): trade_terms menekan fx ekspor & menaikkan biaya impor.
    final expBase = SimEngine.applyTrade(before, contract, price, terms: 0);
    final expTerms =
        SimEngine.applyTrade(before, contract, price, terms: 0.4);
    expect(expTerms.state.fxReserves,
        lessThanOrEqualTo(expBase.state.fxReserves));
    // Kontrak impor arah sebaliknya menambah stok.
    final importProposal = TradeProposal(
      id: 'tX',
      fromCountry: 'jepang',
      toCountry: 'indonesia',
      commodityId: 'semikonduktor',
      qty: 10,
      pricePerUnit: 1200,
      status: TradeStatus.accepted,
      createdQuarter: 0,
    );
    final importContract = TradeContract.fromProposal(
      importProposal,
      startQuarter: 1,
      durationQuarters: 2,
    );
    final impApplied = SimEngine.applyTrade(before, importContract, 1200);
    expect(impApplied.state.stocks['semikonduktor'],
        equals((before.stocks['semikonduktor'] ?? 0) + 10));
    expect(impApplied.state.imports, greaterThan(before.imports));
    // ora-2(3): kontrak id mencakup startQ; ora-2(4): impor +terms lebih mahal.
    expect(importContract.id, equals('c_tX_1'));
    final impTerms =
        SimEngine.applyTrade(before, importContract, 1200, terms: 0.4);
    expect(impTerms.state.fxReserves,
        lessThanOrEqualTo(impApplied.state.fxReserves));
    // processQuarter melipat kontrak aktif tanpa tambah langkah log.
    final r = controller.processQuarter();
    expect(r.logs.length, equals(11));
    expect(r.logs.any((l) => l.contains('/dagang')), isTrue);
    expect(controller.proposals
        .firstWhere((e) => e.id == draft.id)
        .status, equals(TradeStatus.active));
    // Cancel menghapus kontrak.
    controller.cancelTrade(draft.id);
    expect(controller.proposals
        .firstWhere((e) => e.id == draft.id)
        .status, equals(TradeStatus.cancelled));
    expect(controller.contracts.map((c) => c.proposalId),
        isNot(contains(draft.id)));
  });

  test('save round-trip mencakup kontrak + toleran save lama', () {
    final confirmed = PolicySet.defaults(defs);
    final s = testInitial();
    final proposal = TradeProposal(
      id: 't0_0',
      fromCountry: 'indonesia',
      toCountry: 'jepang',
      commodityId: 'beras',
      qty: 50,
      pricePerUnit: 550,
      status: TradeStatus.accepted,
      createdQuarter: 0,
    );
    final contract = TradeContract.fromProposal(
      proposal,
      startQuarter: 1,
      durationQuarters: 4,
    );
    final raw = SaveV1.encode(
      state: s,
      confirmed: confirmed,
      seed: seed,
      history: const [],
      proposals: [proposal],
      contracts: [contract],
      activeCountry: 'indonesia',
      tradeSeq: 1,
    );
    final loaded = SaveV1.decode(raw);
    expect(loaded.proposals.map((e) => e.id), contains('t0_0'));
    expect(loaded.contracts.map((e) => e.id), contains(contract.id));
    expect(loaded.activeCountry, equals('indonesia'));
    expect(loaded.contracts.first.isActiveFor(1), isTrue);
    // ora-2(3): trade_seq monoton persisten + kontrak id baru c_{id}_{startQ}.
    expect(contract.id, equals('c_t0_0_1'));
    expect(loaded.tradeSeq, equals(1));
    // Save lama tanpa field dagang tetap terbaca (toleran hilang).
    final legacy = jsonDecode(raw) as Map<String, dynamic>;
    legacy.remove('proposals');
    legacy.remove('contracts');
    legacy.remove('active_country');
    legacy.remove('trade_seq');
    final legacyLoaded = SaveV1.decode(jsonEncode(legacy));
    expect(legacyLoaded.proposals, isEmpty);
    expect(legacyLoaded.contracts, isEmpty);
    expect(legacyLoaded.activeCountry, equals(s.countryId));
    expect(legacyLoaded.tradeSeq, equals(0));
  });

  test('activeCountry selectable + validasi id', () {
    final countriesRaw =
        File('assets/config/countries.json').readAsStringSync();
    final countries = (jsonDecode(countriesRaw) as List)
        .map((e) => Country.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final controller = GameController(
      initial: testInitial(),
      commodities: commodities,
      events: events,
      policyDefs: defs,
      seed: seed,
      allCountries: countries,
    );
    expect(controller.activeCountryId, equals('indonesia'));
    controller.activeCountryId = 'jepang';
    expect(controller.activeCountryId, equals('jepang'));
    expect(() => controller.activeCountryId = 'atlantis',
        throwsArgumentError);
    // ora-2(1): activeCountryId hanya filter UI/outlook; dagang memakai
    // state.countryId (indonesia) walau view = jepang.
    final stillSim = controller.proposeTrade(
      fromCountry: 'indonesia',
      toCountry: 'jepang',
      commodityId: 'beras',
      qty: 10,
      pricePerUnit: 550,
    );
    expect(stillSim.id, startsWith('t0_'));
    expect(
        () => controller.proposeTrade(
              fromCountry: 'jepang',
              toCountry: 'brasil',
              commodityId: 'beras',
              qty: 10,
              pricePerUnit: 550,
            ),
        throwsArgumentError);
  });
}
