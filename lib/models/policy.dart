// Definisi + nilai kebijakan. Murni Dart.
class PolicyDefinition {
  final String id;
  final String name;
  final double min;
  final double max;
  final double defaultValue;
  final String unit;

  const PolicyDefinition({
    required this.id,
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.unit,
  });

  factory PolicyDefinition.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('Policy.$key harus string tak-kosong');
      }
      return v;
    }

    double numVal(String key) {
      final v = json[key];
      if (v is! num || v.isNaN) {
        throw FormatException('Policy.$key harus angka valid');
      }
      return v.toDouble();
    }

    final min = numVal('min');
    final max = numVal('max');
    final def = numVal('default');
    if (min > max) throw FormatException('Policy.min > max');
    if (def < min || def > max) {
      throw FormatException('Policy.default di luar [min,max]');
    }
    return PolicyDefinition(
      id: str('id'),
      name: str('name'),
      min: min,
      max: max,
      defaultValue: def,
      unit: str('unit'),
    );
  }

  /// Jepit nilai ke [min,max]; tolak NaN.
  double clamp(double value) {
    if (value.isNaN) throw ArgumentError('Nilai kebijakan tidak boleh NaN');
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

/// Kumpulan nilai kebijakan aktif (id -> nilai), selalu tervalidasi.
class PolicySet {
  final Map<String, double> values;

  PolicySet({Map<String, double>? values}) : values = Map.of(values ?? {});

  /// Nilai default dari daftar definisi config.
  factory PolicySet.defaults(List<PolicyDefinition> defs) {
    return PolicySet(
      values: {for (final d in defs) d.id: d.defaultValue},
    );
  }

  double get(String id) => values[id] ?? double.nan;

  /// Kembalikan salinan dengan satu nilai diganti (divalidasi via definisi).
  PolicySet withValue(PolicyDefinition def, double value) {
    final copy = Map<String, double>.of(values);
    copy[def.id] = def.clamp(value);
    return PolicySet(values: copy);
  }

  /// Validasi semua nilai terhadap definisi; lempar bila tak dikenal/NaN.
  void validate(List<PolicyDefinition> defs) {
    final byId = {for (final d in defs) d.id: d};
    for (final e in values.entries) {
      final def = byId[e.key];
      if (def == null) throw FormatException('Kebijakan tak dikenal: ${e.key}');
      if (e.value.isNaN) throw FormatException('Nilai NaN: ${e.key}');
      if (e.value < def.min || e.value > def.max) {
        throw FormatException('Nilai ${e.key} di luar [min,max]');
      }
    }
  }

  PolicySet copy() => PolicySet(values: Map.of(values));

  Map<String, dynamic> toJson() => Map.of(values);

  factory PolicySet.fromJson(Map<String, dynamic> json) {
    final out = <String, double>{};
    json.forEach((k, v) {
      if (v is! num || v.isNaN) {
        throw FormatException('PolicySet.$k harus angka valid');
      }
      out[k] = v.toDouble();
    });
    return PolicySet(values: out);
  }
}
