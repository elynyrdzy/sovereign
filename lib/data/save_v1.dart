// Save system v1 — JSON file, version:1. Murni Dart (testable).
// Dipakai GameController dengan path dari path_provider; meta terakhir
// dapat disimpan via shared_preferences oleh caller (opsional).
import 'dart:convert';
import 'dart:io';

import '../models/policy.dart';
import '../models/quarter_state.dart';
import '../models/trade.dart';

class SaveV1 {
  static const int version = 1;

  /// Encode slot save ke string JSON (deterministik, 2 desimal dijaga sim).
  /// [proposals]/[contracts]/[activeCountry] aditif opsional (default
  /// kosong/diisi state.countryId) agar save lama tetap terbaca.
  /// [tradeSeq] monoton aditif (ora-2(3)): penghitung id `t{q}_{seq}`;
  /// default 0 agar save lama tetap terbaca.
  static String encode({
    required QuarterState state,
    required PolicySet confirmed,
    required int seed,
    required List<QuarterState> history,
    List<TradeProposal> proposals = const [],
    List<TradeContract> contracts = const [],
    String? activeCountry,
    int tradeSeq = 0,
  }) {
    state.validate();
    final map = {
      'version': version,
      'seed': seed,
      'state': state.toJson(),
      'confirmed': confirmed.toJson(),
      'history': history.map((e) => e.toJson()).toList(),
      'proposals': proposals.map((e) => e.toJson()).toList(),
      'contracts': contracts.map((e) => e.toJson()).toList(),
      'active_country': activeCountry ?? state.countryId,
      'trade_seq': tradeSeq,
    };
    return jsonEncode(map);
  }

  /// Decode + validasi; lempar FormatException bila versi/format salah.
  /// Toleran field hilang (save lama tanpa proposals/contracts/active_country
  /// /trade_seq => default kosong/state.countryId/0) — bump kompatibel
  /// tanpa naik versi.
  static SaveData decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Save harus object');
    if (decoded['version'] != version) {
      throw FormatException('Versi save tak didukung: ${decoded['version']}');
    }
    final seed = decoded['seed'];
    if (seed is! int) throw const FormatException('seed harus int');
    final state = QuarterState.fromJson(
        Map<String, dynamic>.from(decoded['state'] as Map));
    final confirmed = PolicySet.fromJson(
        Map<String, dynamic>.from(decoded['confirmed'] as Map));
    final hist = decoded['history'];
    if (hist is! List) throw const FormatException('history harus list');
    final history = hist
        .map((e) => QuarterState.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    state.validate();
    for (final h in history) {
      h.validate();
    }
    // --- Field dagang aditif: toleran hilang/bukan-list => default kosong.
    List<TradeProposal> proposals = const [];
    final rawProposals = decoded['proposals'];
    if (rawProposals is List) {
      proposals = rawProposals
          .map((e) =>
              TradeProposal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    List<TradeContract> contracts = const [];
    final rawContracts = decoded['contracts'];
    if (rawContracts is List) {
      contracts = rawContracts
          .map((e) =>
              TradeContract.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    String? activeCountry;
    final rawActive = decoded['active_country'];
    if (rawActive is String && rawActive.isNotEmpty) {
      activeCountry = rawActive;
    }
    // trade_seq monoton aditif (ora-2(3)); toleran hilang/bukan-int => 0.
    var tradeSeq = 0;
    final rawSeq = decoded['trade_seq'];
    if (rawSeq is int && rawSeq >= 0) {
      tradeSeq = rawSeq;
    }
    return SaveData(
      state: state,
      confirmed: confirmed,
      seed: seed,
      history: history,
      proposals: proposals,
      contracts: contracts,
      activeCountry: activeCountry ?? state.countryId,
      tradeSeq: tradeSeq,
    );
  }

  static Future<void> saveToFile(
    String path, {
    required QuarterState state,
    required PolicySet confirmed,
    required int seed,
    required List<QuarterState> history,
    List<TradeProposal> proposals = const [],
    List<TradeContract> contracts = const [],
    String? activeCountry,
    int tradeSeq = 0,
  }) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(encode(
      state: state,
      confirmed: confirmed,
      seed: seed,
      history: history,
      proposals: proposals,
      contracts: contracts,
      activeCountry: activeCountry,
      tradeSeq: tradeSeq,
    ));
  }

  static Future<SaveData> loadFromFile(String path) async {
    final raw = await File(path).readAsString();
    return decode(raw);
  }
}

class SaveData {
  final QuarterState state;
  final PolicySet confirmed;
  final int seed;
  final List<QuarterState> history;
  final List<TradeProposal> proposals;
  final List<TradeContract> contracts;
  final String activeCountry;
  // Penghitung monoton id trade `t{q}_{seq}` (ora-2(3)); default 0 toleran.
  final int tradeSeq;

  const SaveData({
    required this.state,
    required this.confirmed,
    required this.seed,
    required this.history,
    this.proposals = const [],
    this.contracts = const [],
    this.activeCountry = '',
    this.tradeSeq = 0,
  });
}
