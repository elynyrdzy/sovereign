// Snapshot ekonomi satu kuartal. Murni Dart.
class QuarterState {
  final int quarter;
  final String countryId;
  // Level makro.
  final double gdp;
  final double inflation;
  final double unemployment;
  final double debtToGdp;
  final double fxReserves;
  // Komponen GDP (C+I+G+(X-M)) level kuartal berjalan.
  final double consumption;
  final double investment;
  final double govSpending;
  final double exports;
  final double imports;
  // Suku bunga & fiskal aktual kuartal ini.
  final double interestRate;
  final double taxRate;
  // Stok & harga per komoditas (id -> nilai, 2 desimal).
  final Map<String, double> stocks;
  final Map<String, double> prices;
  // Indeks kemakmuran 0..100.
  final double prosperity;
  // Id event yang sudah diterapkan pada kuartal ini (cegah double-apply).
  final List<String> appliedEvents;

  const QuarterState({
    required this.quarter,
    required this.countryId,
    required this.gdp,
    required this.inflation,
    required this.unemployment,
    required this.debtToGdp,
    required this.fxReserves,
    required this.consumption,
    required this.investment,
    required this.govSpending,
    required this.exports,
    required this.imports,
    required this.interestRate,
    required this.taxRate,
    required this.stocks,
    required this.prices,
    required this.prosperity,
    required this.appliedEvents,
  });

  /// State awal turunan Country + Commodity (harga = base, stok = baseline).
  factory QuarterState.initial({
    required String countryId,
    required double gdp,
    required double inflation,
    required double unemployment,
    required double debtToGdp,
    required double fxReserves,
    required Map<String, double> basePrices,
    required Map<String, double> initialStocks,
    double interestRate = 0.06,
    double taxRate = 0.15,
  }) {
    // GDP awal dipecah ke komponen (fraksi wajar, jumlah = 1.0).
    const consumptionShare = 0.55; // Fraksi C terhadap GDP.
    const investmentShare = 0.25; // Fraksi I terhadap GDP.
    const govShare = 0.15; // Fraksi G terhadap GDP.
    const netExportShare = 0.05; // Fraksi (X-M) terhadap GDP.
    final c = gdp * consumptionShare;
    final i = gdp * investmentShare;
    final g = gdp * govShare;
    final netX = gdp * netExportShare;
    // Bagi net ekspor ke X dan M kasar (X > M bila surplus).
    final x = netX >= 0 ? netX + gdp * 0.10 : gdp * 0.10;
    final m = x - netX;
    return QuarterState(
      quarter: 0,
      countryId: countryId,
      gdp: gdp,
      inflation: inflation,
      unemployment: unemployment,
      debtToGdp: debtToGdp,
      fxReserves: fxReserves,
      consumption: c,
      investment: i,
      govSpending: g,
      exports: x,
      imports: m,
      interestRate: interestRate,
      taxRate: taxRate,
      stocks: Map.of(initialStocks),
      prices: Map.of(basePrices),
      prosperity: 50.0,
      appliedEvents: const [],
    );
  }

  QuarterState copyWith({
    int? quarter,
    double? gdp,
    double? inflation,
    double? unemployment,
    double? debtToGdp,
    double? fxReserves,
    double? consumption,
    double? investment,
    double? govSpending,
    double? exports,
    double? imports,
    double? interestRate,
    double? taxRate,
    Map<String, double>? stocks,
    Map<String, double>? prices,
    double? prosperity,
    List<String>? appliedEvents,
  }) {
    return QuarterState(
      quarter: quarter ?? this.quarter,
      countryId: countryId,
      gdp: gdp ?? this.gdp,
      inflation: inflation ?? this.inflation,
      unemployment: unemployment ?? this.unemployment,
      debtToGdp: debtToGdp ?? this.debtToGdp,
      fxReserves: fxReserves ?? this.fxReserves,
      consumption: consumption ?? this.consumption,
      investment: investment ?? this.investment,
      govSpending: govSpending ?? this.govSpending,
      exports: exports ?? this.exports,
      imports: imports ?? this.imports,
      interestRate: interestRate ?? this.interestRate,
      taxRate: taxRate ?? this.taxRate,
      stocks: stocks ?? Map.of(this.stocks),
      prices: prices ?? Map.of(this.prices),
      prosperity: prosperity ?? this.prosperity,
      appliedEvents: appliedEvents ?? List.of(this.appliedEvents),
    );
  }

  /// Validasi invarian; lempar StateError bila invalid.
  void validate() {
    void finite(String k, double v) {
      if (v.isNaN || v.isInfinite) throw StateError('QuarterState.$k invalid');
    }

    finite('gdp', gdp);
    finite('inflation', inflation);
    finite('unemployment', unemployment);
    finite('debtToGdp', debtToGdp);
    finite('fxReserves', fxReserves);
    if (gdp <= 0) throw StateError('gdp harus > 0');
    if (unemployment < 0 || unemployment > 1) {
      throw StateError('unemployment harus 0..1');
    }
    if (debtToGdp < 0) throw StateError('debtToGdp negatif');
    for (final e in stocks.entries) {
      finite('stocks.${e.key}', e.value);
      if (e.value < 0) throw StateError('stok negatif: ${e.key}');
    }
    for (final e in prices.entries) {
      finite('prices.${e.key}', e.value);
      if (e.value <= 0) throw StateError('harga harus > 0: ${e.key}');
    }
  }

  Map<String, dynamic> toJson() => {
        'quarter': quarter,
        'country_id': countryId,
        'gdp': gdp,
        'inflation': inflation,
        'unemployment': unemployment,
        'debt_to_gdp': debtToGdp,
        'fx_reserves': fxReserves,
        'consumption': consumption,
        'investment': investment,
        'gov_spending': govSpending,
        'exports': exports,
        'imports': imports,
        'interest_rate': interestRate,
        'tax_rate': taxRate,
        'stocks': stocks,
        'prices': prices,
        'prosperity': prosperity,
        'applied_events': appliedEvents,
      };

  factory QuarterState.fromJson(Map<String, dynamic> json) {
    double numVal(String key) {
      final v = json[key];
      if (v is! num || v.isNaN || v.isInfinite) {
        throw FormatException('QuarterState.$key harus angka finite');
      }
      return v.toDouble();
    }

    Map<String, double> numMap(String key) {
      final v = json[key];
      if (v is! Map) throw FormatException('QuarterState.$key harus map');
      final out = <String, double>{};
      v.forEach((k, val) {
        if (val is! num || val.isNaN || val.isInfinite) {
          throw FormatException('QuarterState.$key.$k invalid');
        }
        out[k.toString()] = val.toDouble();
      });
      return out;
    }

    final q = json['quarter'];
    if (q is! int || q < 0) throw FormatException('quarter harus int >= 0');
    final cid = json['country_id'];
    if (cid is! String || cid.isEmpty) {
      throw FormatException('country_id harus string tak-kosong');
    }
    final ae = json['applied_events'];
    if (ae is! List) throw FormatException('applied_events harus list');
    return QuarterState(
      quarter: q,
      countryId: cid,
      gdp: numVal('gdp'),
      inflation: numVal('inflation'),
      unemployment: numVal('unemployment'),
      debtToGdp: numVal('debt_to_gdp'),
      fxReserves: numVal('fx_reserves'),
      consumption: numVal('consumption'),
      investment: numVal('investment'),
      govSpending: numVal('gov_spending'),
      exports: numVal('exports'),
      imports: numVal('imports'),
      interestRate: numVal('interest_rate'),
      taxRate: numVal('tax_rate'),
      stocks: numMap('stocks'),
      prices: numMap('prices'),
      prosperity: numVal('prosperity'),
      appliedEvents: ae.map((e) => e.toString()).toList(),
    );
  }
}
