// FORMULA SEMENTARA Fase 0 — belum balancing final.
// Semua hubungan ekonomi di bawah ini adalah placeholder linier sederhana
// agar prototype berjalan deterministik. Jangan anggap sebagai model
// ekonomi final. Tuning menyusul di fase balancing (lihat blueprint §12).
//
// Konvensi: semua uang dalam USD, laju dalam fraksi (0.05 = 5%),
// pembulatan 2 desimal via round2. Semua fungsi murni & cegah div-by-zero.

import 'dart:math' as math;

// --- Konstanta bernama (tanpa magic numbers tanpa komentar) ---

// Fiskal: tiap 1 poin pajak menaikkan penerimaan ~0.8x GDP (SEMENTARA).
const double kTaxYieldFactor = 0.8;
// Defisit menambah debt-to-GDP proporsional; penyebut dijaga > 0.
const double kDeficitToDebtFactor = 1.0;
// Moneter: tiap 1 poin bunga menekan inflasi 0.35 poin (SEMENTARA).
const double kRateToInflationFactor = 0.35;
// Tiap 1 poin bunga menekan investasi 2.5% relatif (SEMENTARA).
const double kRateToInvestmentFactor = 2.5;
// Produksi: baseline output per komoditas per kuartal (SEMENTARA).
const double kBaseOutputPerQuarter = 1000.0;
// Konsumsi baseline per komoditas per kuartal (SEMENTARA).
const double kBaseConsumptionPerQuarter = 950.0;
// Sensitivitas harga terhadap kelangkaan (SEMENTARA).
const double kScarcityPriceFactor = 0.15;
// Tarif impor menaikkan harga domestik efektif (SEMENTARA: 1:1).
const double kTariffPriceFactor = 1.0;
// Subsidi ekspor menaikkan volume ekspor relatif (SEMENTARA).
const double kSubsidyExportFactor = 0.8;
// Batas laju inflasi/pertumbuhan per kuartal (SEMENTARA).
const double kMaxQuarterInflation = 0.5;
const double kMinQuarterInflation = -0.1;
// Pengangguran: hukum Okun sederhana (SEMENTARA): tiap 2% GDP di atas
// baseline 2% menurunkan pengangguran 1%.
const double kOkunGdpBaseline = 0.02;
const double kOkunFactor = 0.5;
// Shock acak maksimum per kuartal (SEMENTARA, kecil agar deterministik).
const double kPriceShockMagnitude = 0.02;
// Bobot indeks kemakmuran (SEMENTARA, blueprint §10 bobot indikatif).
const double kWInflation = 0.25;
const double kWUnemployment = 0.25;
const double kWDebt = 0.25;
const double kWGrowth = 0.25;

/// Bulatkan ke 2 desimal; NaN/inf dilempar agar bug ketahuan.
double round2(double v) {
  if (v.isNaN || v.isInfinite) throw ArgumentError('round2 input invalid');
  return (v * 100).roundToDouble() / 100;
}

/// Penyebut aman: ganti 0/near-0 dengan epsilon bertanda.
double safeDenom(double v, [double epsilon = 1e-9]) {
  if (v.isNaN || v.isInfinite) return epsilon;
  if (v.abs() < epsilon) return v >= 0 ? epsilon : -epsilon;
  return v;
}

/// Penerimaan pajak kuartalan ≈ GDP * taxRate * yield (SEMENTARA).
double fiscalRevenue(double gdp, double taxRate) {
  return round2(math.max(0, gdp) * math.max(0, taxRate) * kTaxYieldFactor);
}

/// Defisit = belanja − penerimaan (positif = defisit). (SEMENTARA).
double fiscalDeficit(double spending, double revenue) {
  return round2(math.max(0, spending) - math.max(0, revenue));
}

/// Update debt-to-GDP akibat defisit (SEMENTARA).
double debtToGdpUpdate(double prev, double deficit, double gdp) {
  final d = safeDenom(gdp);
  return round2(math.max(0, prev + (deficit / d) * kDeficitToDebtFactor));
}

/// Tekanan inflasi dari kebijakan moneter (SEMENTARA).
/// Bunga di atas baseline menekan inflasi (delta negatif).
double monetaryInflationDelta(double interestRate, double baseRate) {
  return round2(-(interestRate - baseRate) * kRateToInflationFactor);
}

/// Level investasi setelah respons suku bunga (SEMENTARA).
double investmentAfterRate(double base, double interestRate, double baseRate) {
  final adj =
      1.0 - (interestRate - baseRate) * kRateToInvestmentFactor;
  return round2(math.max(0, base * math.max(0, adj)));
}

/// Konsumsi setelah pajak: pajak tinggi menekan daya beli (SEMENTARA).
double consumptionAfterTax(double base, double taxRate) {
  return round2(math.max(0, base * (1.0 - math.max(0, taxRate) * 0.5)));
}

/// Output produksi komoditas: baseline + efek subsidi/bunga kecil (SEMENTARA).
double commodityOutput(double baseOutput, double govSupportFactor) {
  return round2(math.max(0, baseOutput * (1.0 + govSupportFactor * 0.1)));
}

/// Harga domestik efektif = global * (1 + tarif) + scarcity adj (SEMENTARA).
double domesticPrice(double globalPrice, double tariff, double scarcityRatio) {
  final p = math.max(1e-9, globalPrice);
  return round2(p * (1.0 + math.max(0, tariff) * kTariffPriceFactor) *
      (1.0 + math.max(0, scarcityRatio) * kScarcityPriceFactor));
}

/// GDP = C + I + G + (X − M). (Blueprint §3.1, definitif.)
double gdpCompute(double c, double i, double g, double x, double m) {
  return round2(c + i + g + (x - m));
}

/// Laju pertumbuhan = (baru − lama) / |lama|; cegah div-by-zero.
double growthRate(double next, double prev) {
  return round2((next - prev) / safeDenom(prev.abs()));
}

/// Inflasi kuartal baru (SEMENTARA): baseline + demand gap + import effect.
double inflationUpdate({
  required double prev,
  required double demandGap,
  required double importPriceEffect,
  required double rateEffect,
}) {
  final v = prev + demandGap * 0.1 + importPriceEffect * 0.2 + rateEffect;
  return round2(v.clamp(kMinQuarterInflation, kMaxQuarterInflation));
}

/// Pengangguran via Okun sederhana (SEMENTARA).
double unemploymentUpdate(double prev, double gdpGrowth) {
  final delta = -kOkunFactor * (gdpGrowth - kOkunGdpBaseline);
  return round2((prev + delta).clamp(0.0, 0.35));
}

/// Indeks kemakmuran 0..100 (SEMENTARA): rendah inflasi/pengangguran/utang
/// + tinggi growth => skor tinggi.
double prosperityIndex({
  required double inflation,
  required double unemployment,
  required double debtToGdp,
  required double growth,
}) {
  double score(double v, double worst) =>
      (1.0 - (v.clamp(0.0, worst) / worst)).clamp(0.0, 1.0);
  final s = kWInflation * score(inflation, 0.2) +
      kWUnemployment * score(unemployment, 0.2) +
      kWDebt * score(debtToGdp, 1.0) +
      kWGrowth * ((growth + 0.05).clamp(0.0, 0.1) / 0.1);
  return round2((s * 100).clamp(0.0, 100.0));
}
