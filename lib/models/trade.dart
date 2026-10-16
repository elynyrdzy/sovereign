// Model dagang bilateral — murni Dart, tanpa import Flutter.
// Aditif Fase dagang: proposal (draft) → accepted → active (kontrak).
// Draft TIDAK memutasi simulasi; mutasi hanya via SimEngine.applyTrade
// atau GameController.acceptTrade/processQuarter.
class TradeStatus {
  static const String proposal = 'proposal';
  static const String accepted = 'accepted';
  static const String active = 'active';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';

  static const Set<String> values = {
    proposal,
    accepted,
    active,
    rejected,
    cancelled,
  };

  static bool isValid(String s) => values.contains(s);
}

/// Usulan dagang bilateral (draft sampai diterima).
class TradeProposal {
  final String id;
  final String fromCountry;
  final String toCountry;
  final String commodityId;
  final double qty;
  final double pricePerUnit;
  final String status;
  final int createdQuarter;

  const TradeProposal({
    required this.id,
    required this.fromCountry,
    required this.toCountry,
    required this.commodityId,
    required this.qty,
    required this.pricePerUnit,
    required this.status,
    required this.createdQuarter,
  });

  double get totalValue => qty * pricePerUnit;

  /// Validasi invarian; lempar bila invalid.
  /// qty > 0, price > 0, id/country/commodity tak-kosong,
  /// status salah satu dari proposal/accepted/active/rejected/cancelled,
  /// createdQuarter >= 0.
  void validate() {
    if (id.isEmpty) throw StateError('TradeProposal.id kosong');
    if (fromCountry.isEmpty) throw StateError('fromCountry kosong');
    if (toCountry.isEmpty) throw StateError('toCountry kosong');
    if (commodityId.isEmpty) throw StateError('commodityId kosong');
    if (qty.isNaN || qty.isInfinite || qty <= 0) {
      throw StateError('qty harus > 0');
    }
    if (pricePerUnit.isNaN ||
        pricePerUnit.isInfinite ||
        pricePerUnit <= 0) {
      throw StateError('pricePerUnit harus > 0');
    }
    if (!TradeStatus.isValid(status)) {
      throw StateError('status tak dikenal: $status');
    }
    if (createdQuarter < 0) throw StateError('createdQuarter negatif');
  }

  TradeProposal copyWith({
    String? status,
    double? qty,
    double? pricePerUnit,
  }) {
    return TradeProposal(
      id: id,
      fromCountry: fromCountry,
      toCountry: toCountry,
      commodityId: commodityId,
      qty: qty ?? this.qty,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      status: status ?? this.status,
      createdQuarter: createdQuarter,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_country': fromCountry,
        'to_country': toCountry,
        'commodity_id': commodityId,
        'qty': qty,
        'price_per_unit': pricePerUnit,
        'status': status,
        'created_quarter': createdQuarter,
      };

  factory TradeProposal.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('TradeProposal.$key harus string tak-kosong');
      }
      return v;
    }

    double numVal(String key) {
      final v = json[key];
      if (v is! num || v.isNaN || v.isInfinite) {
        throw FormatException('TradeProposal.$key harus angka finite');
      }
      return v.toDouble();
    }

    final q = json['created_quarter'];
    if (q is! int || q < 0) {
      throw const FormatException('created_quarter harus int >= 0');
    }
    final p = TradeProposal(
      id: str('id'),
      fromCountry: str('from_country'),
      toCountry: str('to_country'),
      commodityId: str('commodity_id'),
      qty: numVal('qty'),
      pricePerUnit: numVal('price_per_unit'),
      status: str('status'),
      createdQuarter: q,
    );
    p.validate();
    return p;
  }
}

/// Kontrak dagang — turunan proposal yang sudah accepted → active.
/// Aktif pada kuartal [startQuarter, startQuarter + durationQuarters).
class TradeContract {
  final String id;
  final String proposalId;
  final String fromCountry;
  final String toCountry;
  final String commodityId;
  final double qty;
  final double pricePerUnit;
  final int startQuarter;
  final int durationQuarters;

  const TradeContract({
    required this.id,
    required this.proposalId,
    required this.fromCountry,
    required this.toCountry,
    required this.commodityId,
    required this.qty,
    required this.pricePerUnit,
    required this.startQuarter,
    required this.durationQuarters,
  });

  double get totalValue => qty * pricePerUnit;

  /// True bila kontrak berlaku pada [quarter].
  bool isActiveFor(int quarter) {
    return quarter >= startQuarter &&
        quarter < startQuarter + durationQuarters;
  }

  void validate() {
    if (id.isEmpty) throw StateError('TradeContract.id kosong');
    if (proposalId.isEmpty) throw StateError('proposalId kosong');
    if (fromCountry.isEmpty) throw StateError('fromCountry kosong');
    if (toCountry.isEmpty) throw StateError('toCountry kosong');
    if (commodityId.isEmpty) throw StateError('commodityId kosong');
    if (qty.isNaN || qty.isInfinite || qty <= 0) {
      throw StateError('qty harus > 0');
    }
    if (pricePerUnit.isNaN ||
        pricePerUnit.isInfinite ||
        pricePerUnit <= 0) {
      throw StateError('pricePerUnit harus > 0');
    }
    if (startQuarter < 0) throw StateError('startQuarter negatif');
    if (durationQuarters <= 0) {
      throw StateError('durationQuarters harus > 0');
    }
  }

  /// Turunan accepted → active: hanya proposal berstatus accepted
  /// yang boleh dijadikan kontrak. Lempar StateError bila bukan.
  /// Kontrak id monoton: `c_{proposalId}_{startQuarter}` (ora-2(3)) agar unik
  /// lintas kuartal walau proposalId sama dipakai ulang secara tak sengaja;
  /// validasi unik dilakukan caller (GameController.acceptTrade).
  factory TradeContract.fromProposal(
    TradeProposal proposal, {
    required int startQuarter,
    required int durationQuarters,
  }) {
    proposal.validate();
    if (proposal.status != TradeStatus.accepted) {
      throw StateError(
          'Hanya proposal accepted yang bisa jadi kontrak (was ${proposal.status})');
    }
    if (startQuarter < 0) throw StateError('startQuarter negatif');
    if (durationQuarters <= 0) {
      throw StateError('durationQuarters harus > 0');
    }
    return TradeContract(
      id: 'c_${proposal.id}_$startQuarter',
      proposalId: proposal.id,
      fromCountry: proposal.fromCountry,
      toCountry: proposal.toCountry,
      commodityId: proposal.commodityId,
      qty: proposal.qty,
      pricePerUnit: proposal.pricePerUnit,
      startQuarter: startQuarter,
      durationQuarters: durationQuarters,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'proposal_id': proposalId,
        'from_country': fromCountry,
        'to_country': toCountry,
        'commodity_id': commodityId,
        'qty': qty,
        'price_per_unit': pricePerUnit,
        'start_quarter': startQuarter,
        'duration_quarters': durationQuarters,
      };

  factory TradeContract.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('TradeContract.$key harus string tak-kosong');
      }
      return v;
    }

    double numVal(String key) {
      final v = json[key];
      if (v is! num || v.isNaN || v.isInfinite) {
        throw FormatException('TradeContract.$key harus angka finite');
      }
      return v.toDouble();
    }

    int intVal(String key) {
      final v = json[key];
      if (v is! int) throw FormatException('TradeContract.$key harus int');
      return v;
    }

    final c = TradeContract(
      id: str('id'),
      proposalId: str('proposal_id'),
      fromCountry: str('from_country'),
      toCountry: str('to_country'),
      commodityId: str('commodity_id'),
      qty: numVal('qty'),
      pricePerUnit: numVal('price_per_unit'),
      startQuarter: intVal('start_quarter'),
      durationQuarters: intVal('duration_quarters'),
    );
    c.validate();
    return c;
  }
}
