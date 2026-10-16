// Model negara — murni Dart, tanpa import Flutter.
class Country {
  // Identitas & demografi.
  final String id;
  final String name;
  final int population;
  // Makro awal (level, bukan laju kuartalan kecuali inflasi/unemployment).
  final double gdp;
  final double inflation;
  final double unemployment;
  final double debtToGdp;
  final double fxReserves;
  final String incomeGroup;
  final List<String> resources;
  final List<String> importNeeds;

  const Country({
    required this.id,
    required this.name,
    required this.population,
    required this.gdp,
    required this.inflation,
    required this.unemployment,
    required this.debtToGdp,
    required this.fxReserves,
    required this.incomeGroup,
    required this.resources,
    required this.importNeeds,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    // Validasi field wajib; lempar FormatException bila tak valid.
    String str(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('Country.$key harus string tak-kosong');
      }
      return v;
    }

    num number(String key) {
      final v = json[key];
      if (v is! num || v.isNaN) {
        throw FormatException('Country.$key harus angka valid');
      }
      return v;
    }

    List<String> strList(String key) {
      final v = json[key];
      if (v is! List) throw FormatException('Country.$key harus list');
      return v.map((e) => e.toString()).toList();
    }

    final population = number('population').toInt();
    if (population <= 0) throw FormatException('population harus > 0');

    final gdp = number('gdp').toDouble();
    if (gdp <= 0) throw FormatException('gdp harus > 0');

    final fx = number('fx_reserves').toDouble();
    if (fx < 0) throw FormatException('fx_reserves tidak boleh negatif');

    return Country(
      id: str('id'),
      name: str('name'),
      population: population,
      gdp: gdp,
      inflation: number('inflation').toDouble(),
      unemployment: number('unemployment').toDouble(),
      debtToGdp: number('debt_to_gdp').toDouble(),
      fxReserves: fx,
      incomeGroup: str('income_group'),
      resources: strList('resources'),
      importNeeds: strList('import_needs'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'population': population,
        'gdp': gdp,
        'inflation': inflation,
        'unemployment': unemployment,
        'debt_to_gdp': debtToGdp,
        'fx_reserves': fxReserves,
        'income_group': incomeGroup,
        'resources': resources,
        'import_needs': importNeeds,
      };
}
