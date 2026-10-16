// GameController minimal Fase 0 — antrean proposed→confirmed→simulated.
// Yang belum dikonfirmasi TIDAK memutasi simulasi (lihat ui.md §4.4).
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/save_v1.dart';
import '../models/commodity.dart';
import '../models/country.dart';
import '../models/game_event.dart';
import '../models/policy.dart';
import '../models/quarter_state.dart';
import '../models/result.dart';
import '../models/trade.dart';
import '../sim/engine.dart';

class GameController extends ChangeNotifier {
  final SimEngine _engine;
  final List<Commodity> commodities;
  final List<GameEvent> events;
  final List<PolicyDefinition> policyDefs;
  final int seed;
  // Daftar semua negara dari countries.json (read-only, statis).
  // Negara aktif selectable via activeCountryId (default initial.countryId).
  final List<Country> allCountries;

  QuarterState _current;
  PolicySet _proposed;
  PolicySet _confirmed;
  QuarterResult? _simulated;
  final List<QuarterState> _history = [];
  // Dagang bilateral aditif (draft tidak mutasi sim sampai accept+proses).
  final List<TradeProposal> _proposals = [];
  final List<TradeContract> _contracts = [];
  String _activeCountryId;
  int _tradeSeq = 0;

  GameController({
    required QuarterState initial,
    required this.commodities,
    required this.events,
    required this.policyDefs,
    required this.seed,
    SimEngine? engine,
    List<Country> allCountries = const [],
  })  : _current = initial,
        allCountries = List.unmodifiable(allCountries),
        _activeCountryId = initial.countryId,
        _proposed = PolicySet.defaults(policyDefs),
        _confirmed = PolicySet.defaults(policyDefs),
        _engine = engine ?? SimEngine() {
    _current.validate();
  }

  QuarterState get current => _current;
  PolicySet get proposed => _proposed.copy();
  PolicySet get confirmed => _confirmed.copy();
  QuarterResult? get simulated => _simulated;
  List<QuarterState> get history => List.unmodifiable(_history);

  // Koleksi dagang (read-only view; mutasi hanya via propose/accept/cancel).
  List<TradeProposal> get proposals => List.unmodifiable(_proposals);
  List<TradeContract> get contracts => List.unmodifiable(_contracts);

  // Multi-negara Fase 1 + dagang: negara aktif selectable (default
  // initial.countryId, lazimnya 'indonesia').
  // ora-2(1): sumber tunggal sim/dagang adalah _current.countryId.
  // activeCountryId HANYA filter UI/outlook (otherCountries/outlookFor) dan
  // tidak dipakai validasi propose/accept/apply. Dipilih opsi terkecil:
  // ganti cek activeCountryId -> _current.countryId (bukan assert sama),
  // agar view boleh beda tanpa memecah sim.
  String get activeCountryId => _activeCountryId;
  set activeCountryId(String id) {
    if (id.isEmpty) throw ArgumentError('activeCountryId kosong');
    if (allCountries.isNotEmpty && findCountry(id) == null) {
      throw ArgumentError('Negara tak dikenal: $id');
    }
    _activeCountryId = id;
    notifyListeners();
  }

  List<Country> get otherCountries => allCountries
      .where((c) => c.id != activeCountryId)
      .toList(growable: false);

  Country? findCountry(String id) {
    for (final c in allCountries) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Surplus/defisit sederhana per komoditas untuk satu negara (read-only).
  Map<String, String> outlookFor(String countryId) {
    final c = findCountry(countryId);
    if (c == null) return {};
    return SimEngine.countryOutlook(c, commodities);
  }

  PolicyDefinition _defOf(String id) {
    return policyDefs.firstWhere(
      (d) => d.id == id,
      orElse: () => throw ArgumentError('Kebijakan tak dikenal: $id'),
    );
  }

  /// Draft usulan; tidak menyentuh _current/_confirmed.
  void proposePolicy(String id, double value) {
    final def = _defOf(id);
    _proposed = _proposed.withValue(def, value);
    notifyListeners();
  }

  /// Kunci usulan menjadi confirmed untuk kuartal berikutnya.
  void confirmPolicies() {
    _proposed.validate(policyDefs);
    _confirmed = _proposed.copy();
    notifyListeners();
  }

  /// Batalkan draft kembali ke confirmed.
  void discardDraft() {
    _proposed = _confirmed.copy();
    notifyListeners();
  }

  bool _commodityExists(String id) {
    for (final c in commodities) {
      if (c.id == id) return true;
    }
    return false;
  }

  void _validateTradeParties({
    required String fromCountry,
    required String toCountry,
    required String commodityId,
  }) {
    if (fromCountry.isEmpty || toCountry.isEmpty || commodityId.isEmpty) {
      throw ArgumentError('country/commodity id tak boleh kosong');
    }
    if (fromCountry == toCountry) {
      throw ArgumentError('fromCountry == toCountry tidak didukung');
    }
    if (allCountries.isNotEmpty) {
      if (findCountry(fromCountry) == null) {
        throw ArgumentError('fromCountry tak dikenal: $fromCountry');
      }
      if (findCountry(toCountry) == null) {
        throw ArgumentError('toCountry tak dikenal: $toCountry');
      }
    }
    if (!_commodityExists(commodityId)) {
      throw ArgumentError('Komoditas tak dikenal: $commodityId');
    }
    // ora-2(1): sumber tunggal = _current.countryId (bukan activeCountryId;
    // active hanya filter UI/outlook). Kontrak harus menyentuh negara sim.
    final simCountry = _current.countryId;
    final involvesSim =
        fromCountry == simCountry || toCountry == simCountry;
    if (!involvesSim) {
      throw ArgumentError(
          'Kontrak harus melibatkan negara sim ($simCountry)');
    }
  }

  /// Buat draft proposal dagang. TIDAK memutasi [_current] (sim).
  /// Validasi jujur ringan: id tak-kosong, qty/price > 0, komoditas ada,
  /// salah satu sisi adalah negara sim (_current.countryId, ora-2(1)).
  /// Id monoton `t{q}_{seq}` dari _tradeSeq persisten (ora-2(3)); unik
  /// divalidasi sebelum tambah.
  TradeProposal proposeTrade({
    required String fromCountry,
    required String toCountry,
    required String commodityId,
    required double qty,
    required double pricePerUnit,
  }) {
    _validateTradeParties(
      fromCountry: fromCountry,
      toCountry: toCountry,
      commodityId: commodityId,
    );
    final newId = 't${_current.quarter}_$_tradeSeq';
    if (_proposals.any((e) => e.id == newId)) {
      throw StateError('Duplikat proposal id: $newId');
    }
    final p = TradeProposal(
      id: newId,
      fromCountry: fromCountry,
      toCountry: toCountry,
      commodityId: commodityId,
      qty: qty,
      pricePerUnit: pricePerUnit,
      status: TradeStatus.proposal,
      createdQuarter: _current.quarter,
    );
    p.validate();
    _proposals.add(p);
    _tradeSeq++;
    notifyListeners();
    return p;
  }

  /// Setujui proposal (draft → accepted) + buat kontrak aktif berikutnya.
  /// Validasi jujur saat confirm terhadap negara sim (_current.countryId,
  /// ora-2(1)): ekspor butuh stok cukup, impor butuh devisa cukup untuk
  /// biaya kuartal ini (nilai*kFxPerValue*(1+terms), sama dengan engine).
  /// Kontrak id `c_{proposalId}_{startQ}` (ora-2(3)); duplikat ditolak.
  /// TIDAK memutasi [_current]; efek sim baru pada [processQuarter].
  TradeContract acceptTrade(
    String proposalId, {
    int? startQuarter,
    int? durationQuarters,
  }) {
    final idx = _proposals.indexWhere((e) => e.id == proposalId);
    if (idx < 0) throw ArgumentError('Proposal tak ditemukan: $proposalId');
    final p = _proposals[idx];
    if (p.status != TradeStatus.proposal) {
      throw StateError(
          'Hanya status proposal yang bisa diterima (was ${p.status})');
    }
    // Validasi stok/devisa jujur terhadap state berjalan (negara sim).
    final simCountry = _current.countryId;
    if (p.fromCountry == simCountry) {
      final avail = _current.stocks[p.commodityId] ?? 0;
      if (avail < p.qty) {
        throw StateError(
            'Stok ${p.commodityId} tak cukup: butuh ${p.qty}, ada $avail');
      }
    }
    if (p.toCountry == simCountry) {
      // Selaras engine impor: nilai*kFxPerValue*(1+terms) (ora-2(2,4)).
      final double terms = _confirmed.values['trade_terms'] ?? 0.0;
      final cost =
          p.qty * p.pricePerUnit * SimEngine.kFxPerValue * (1 + terms);
      if (_current.fxReserves < cost) {
        throw StateError(
            'Devisa tak cukup: butuh $cost, ada ${_current.fxReserves}');
      }
    }
    final accepted = p.copyWith(status: TradeStatus.accepted);
    _proposals[idx] = accepted;
    final contract = TradeContract.fromProposal(
      accepted,
      startQuarter: startQuarter ?? _current.quarter + 1,
      durationQuarters: durationQuarters ?? 4,
    );
    if (_contracts.any((c) => c.id == contract.id)) {
      throw StateError('Duplikat kontrak id: ${contract.id}');
    }
    _contracts.add(contract);
    notifyListeners();
    return contract;
  }

  /// Batalkan proposal (proposal/accepted/active → cancelled) + hapus
  /// kontrak terkait bila ada sehingga tidak lagi diterapkan engine.
  void cancelTrade(String proposalId) {
    final idx = _proposals.indexWhere((e) => e.id == proposalId);
    if (idx < 0) throw ArgumentError('Proposal tak ditemukan: $proposalId');
    final p = _proposals[idx];
    if (p.status == TradeStatus.cancelled ||
        p.status == TradeStatus.rejected) {
      throw StateError('Proposal sudah final (${p.status})');
    }
    _proposals[idx] = p.copyWith(status: TradeStatus.cancelled);
    _contracts.removeWhere((c) => c.proposalId == proposalId);
    notifyListeners();
  }

  /// Proses 1 kuartal via engine memakai confirmed + kontrak aktif;
  /// lalu proposed=confirmed diselaraskan. Proposal accepted yang kontraknya
  /// aktif pada kuartal hasil => status dipromosikan ke active
  /// (accepted → active terdokumentasi di sini).
  QuarterResult processQuarter() {
    final result = _engine.processQuarter(
      state: _current,
      confirmed: _confirmed,
      seed: seed,
      commodities: commodities,
      events: events,
      policyDefs: policyDefs,
      tradeContracts: List.unmodifiable(_contracts),
    );
    _history.add(_current);
    _current = result.next;
    for (var i = 0; i < _proposals.length; i++) {
      final p = _proposals[i];
      if (p.status != TradeStatus.accepted) continue;
      final linked = _contracts.where((c) => c.proposalId == p.id);
      for (final c in linked) {
        if (c.isActiveFor(result.next.quarter)) {
          _proposals[i] = p.copyWith(status: TradeStatus.active);
          break;
        }
      }
    }
    _simulated = result;
    _proposed = _confirmed.copy();
    notifyListeners();
    return result;
  }

  Future<String> _savePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/sovereign_save_v1.json';
  }

  /// Simpan slot + catat path terakhir di SharedPreferences.
  Future<String> save() async {
    final path = await _savePath();
    await SaveV1.saveToFile(
      path,
      state: _current,
      confirmed: _confirmed,
      seed: seed,
      history: _history,
      proposals: List.unmodifiable(_proposals),
      contracts: List.unmodifiable(_contracts),
      activeCountry: _activeCountryId,
      tradeSeq: _tradeSeq,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sovereign_last_save', path);
    return path;
  }

  /// Muat slot; ganti current/confirmed/history + proposals/contracts/
  /// activeCountry (toleran save lama: kosong/state.countryId).
  Future<void> load() async {
    final path = await _savePath();
    final data = await SaveV1.loadFromFile(path);
    _current = data.state;
    _confirmed = data.confirmed;
    _proposed = data.confirmed.copy();
    _history
      ..clear()
      ..addAll(data.history);
    _proposals
      ..clear()
      ..addAll(data.proposals);
    _contracts
      ..clear()
      ..addAll(data.contracts);
    final restored = data.activeCountry;
    if (restored.isNotEmpty) {
      if (allCountries.isEmpty || findCountry(restored) != null) {
        _activeCountryId = restored;
      } else {
        _activeCountryId = data.state.countryId;
      }
    } else {
      _activeCountryId = data.state.countryId;
    }
    // Lanjutkan urutan id trade monoton pasca-load (ora-2(3)): pakai
    // trade_seq persisten; save lama (tradeSeq=0) fallback ke jumlah proposal
    // agar tak tabrakan id lama.
    _tradeSeq = data.tradeSeq > _proposals.length
        ? data.tradeSeq
        : _proposals.length;
    _simulated = null;
    notifyListeners();
  }
}
