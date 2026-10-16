// Definisi komoditas statis (dari assets/config/commodities.json).
// State dinamis (stok/harga) hidup di QuarterState agar config ≠ logika.
class Commodity {
  final String id;
  final String category;
  final double baseGlobalPrice;
  final String unit;
  // 0..1 seberapa strategis untuk ketahanan nasional.
  final double strategicImportance;
  final List<String> usedBy;
  final List<String> producers;

  const Commodity({
    required this.id,
    required this.category,
    required this.baseGlobalPrice,
    required this.unit,
    required this.strategicImportance,
    required this.usedBy,
    required this.producers,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('Commodity.$key harus string tak-kosong');
      }
      return v;
    }

    final price = json['base_global_price'];
    if (price is! num || price.isNaN || price <= 0) {
      throw FormatException('Commodity.base_global_price harus > 0');
    }
    final importance = json['strategic_importance'];
    if (importance is! num ||
        importance.isNaN ||
        importance < 0 ||
        importance > 1) {
      throw FormatException('Commodity.strategic_importance harus 0..1');
    }
    List<String> list(String key) {
      final v = json[key];
      if (v is! List) throw FormatException('Commodity.$key harus list');
      return v.map((e) => e.toString()).toList();
    }

    return Commodity(
      id: str('id'),
      category: str('category'),
      baseGlobalPrice: price.toDouble(),
      unit: str('unit'),
      strategicImportance: importance.toDouble(),
      usedBy: list('used_by'),
      producers: list('producers'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'base_global_price': baseGlobalPrice,
        'unit': unit,
        'strategic_importance': strategicImportance,
        'used_by': usedBy,
        'producers': producers,
      };
}
