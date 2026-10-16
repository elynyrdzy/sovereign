// Event seeded dari assets/config/events.json. Murni Dart.
class GameEvent {
  final String id;
  final String name;
  final String description;
  // id komoditas -> fraksi perubahan harga (mis. 0.4 = +40%).
  final Map<String, double> priceEffects;
  // id komoditas -> fraksi perubahan produksi (mis. -0.2 = −20%).
  final Map<String, double> productionEffects;
  // Pemicu deterministik: aktif bila (quarter % mod == offset).
  final int triggerQuarterMod;
  final int triggerOffset;

  const GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.priceEffects,
    required this.productionEffects,
    required this.triggerQuarterMod,
    required this.triggerOffset,
  });

  static Map<String, double> _fracMap(dynamic v, String key) {
    if (v == null) return {};
    if (v is! Map) throw FormatException('GameEvent.$key harus map');
    final out = <String, double>{};
    v.forEach((k, val) {
      if (val is! num || val.isNaN) {
        throw FormatException('GameEvent.$key.$k harus angka valid');
      }
      out[k.toString()] = val.toDouble();
    });
    return out;
  }

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty) {
      throw FormatException('GameEvent.id harus string tak-kosong');
    }
    if (name is! String || name.isEmpty) {
      throw FormatException('GameEvent.name harus string tak-kosong');
    }
    final mod = json['trigger_quarter_mod'];
    final off = json['trigger_offset'];
    if (mod is! int || mod <= 0) {
      throw FormatException('trigger_quarter_mod harus int > 0');
    }
    if (off is! int || off < 0 || off >= mod) {
      throw FormatException('trigger_offset harus 0 <= offset < mod');
    }
    return GameEvent(
      id: id,
      name: name,
      description: (json['description'] ?? '').toString(),
      priceEffects: _fracMap(json['price_effects'], 'price_effects'),
      productionEffects:
          _fracMap(json['production_effects'], 'production_effects'),
      triggerQuarterMod: mod,
      triggerOffset: off,
    );
  }

  /// True bila event aktif pada nomor kuartal ini (deterministik).
  bool triggersOn(int quarter) => quarter % triggerQuarterMod == triggerOffset;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price_effects': priceEffects,
        'production_effects': productionEffects,
        'trigger_quarter_mod': triggerQuarterMod,
        'trigger_offset': triggerOffset,
      };
}
