// Format angka Indonesia sederhana untuk UI Fase 0.
// Tanpa intl agar tetap ringan; koma dipakai untuk persen.
String formatCompactUsd(double v) {
  final abs = v.abs();
  String num(double n) => n.toStringAsFixed(n >= 100 ? 0 : 1);
  if (abs >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)} T';
  if (abs >= 1e9) return '\$${num(v / 1e9)} M';
  if (abs >= 1e6) return '\$${num(v / 1e6)} jt';
  if (abs >= 1e3) return '\$${num(v / 1e3)} rb';
  return '\$${v.toStringAsFixed(0)}';
}

/// 0.032 -> "3,2%". Satu desimal, koma Indonesia.
String formatPercent(double fraction, {int decimals = 1}) {
  final s = (fraction * 100).toStringAsFixed(decimals);
  return '${s.replaceAll('.', ',')}%';
}

/// 0.39 -> "39%". Untuk rasio utang.
String formatDebtRatio(double ratio) => formatPercent(ratio);

/// Kuartal -> "K3 • Kuartal 3".
String formatQuarter(int q) => q <= 0 ? 'K0 • Awal' : 'K$q • Kuartal $q';

/// "280 jt jiwa" dari population.
String formatPopulation(int pop) {
  if (pop >= 1e9) return '${(pop / 1e9).toStringAsFixed(2).replaceAll('.', ',')} M jiwa';
  if (pop >= 1e6) return '${(pop / 1e6).toStringAsFixed(0)} jt jiwa';
  if (pop >= 1e3) return '${(pop / 1e3).toStringAsFixed(0)} rb jiwa';
  return '$pop jiwa';
}

/// Suku bunga / pajak slider -> "6,0%".
String formatRate(double fraction) => formatPercent(fraction);

/// Belanja besar -> compact USD.
String formatSpending(double v) => formatCompactUsd(v);
