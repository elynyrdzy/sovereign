// RNG seeded deterministik — tanpa DateTime.now(). Murni Dart.
import 'dart:math' as math;

/// Pembungkus Random dengan seed eksplisit agar replay = hasil sama.
class SeededRng {
  final math.Random _inner;
  final int seed;

  SeededRng(this.seed) : _inner = math.Random(seed);

  double nextDouble() => _inner.nextDouble();

  int nextInt(int max) => _inner.nextInt(max);

  /// Kisaran simetris [-magnitude, +magnitude].
  double shock(double magnitude) =>
      (_inner.nextDouble() * 2.0 - 1.0) * magnitude;
}
