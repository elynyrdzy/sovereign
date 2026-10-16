// Diplomasi Fase 1 — profil negara & dagang bilateral (ui.md §4.5).
// Header profil 100–140dp, tab Statistik/Sumber Daya/Hubungan 40–48dp,
// baris info 44–64dp, aksi >=48dp. Hanya via GameController; tanpa mutasi
// sim di luar propose/accept/cancel. Defensif: allCountries kosong →
// fallback statis ID/JP/BR + catatan; proposal/kontrak kosong → empty-state.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../models/trade.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'confirm_sheet.dart';
import 'format.dart';

// Fallback statis bila controller.allCountries kosong (mirror countries.json).
// Bukan data live — tampilkan catatan jujur di UI.
const _fallbackCountries = [
  Country(
    id: 'indonesia',
    name: 'Indonesia',
    population: 280000000,
    gdp: 1400000000000,
    inflation: 0.032,
    unemployment: 0.053,
    debtToGdp: 0.39,
    fxReserves: 140000000000,
    incomeGroup: 'upper_middle_income',
    resources: ['nickel', 'coal', 'oil', 'gas', 'palm_oil'],
    importNeeds: ['wheat', 'machinery', 'semiconductors'],
  ),
  Country(
    id: 'jepang',
    name: 'Jepang',
    population: 124000000,
    gdp: 4200000000000,
    inflation: 0.028,
    unemployment: 0.026,
    debtToGdp: 2.6,
    fxReserves: 1250000000000,
    incomeGroup: 'high_income',
    resources: ['semikonduktor', 'mesin_industri', 'besi_baja'],
    importNeeds: ['minyak', 'gas', 'gandum'],
  ),
  Country(
    id: 'brasil',
    name: 'Brasil',
    population: 216000000,
    gdp: 2100000000000,
    inflation: 0.045,
    unemployment: 0.08,
    debtToGdp: 0.88,
    fxReserves: 340000000000,
    incomeGroup: 'upper_middle_income',
    resources: ['minyak', 'besi_baja', 'gandum', 'tembaga'],
    importNeeds: ['semikonduktor', 'mesin_industri', 'gas'],
  ),
];

class DiplomacyScreen extends StatefulWidget {
  const DiplomacyScreen({super.key});

  @override
  State<DiplomacyScreen> createState() => _DiplomacyScreenState();
}

class _DiplomacyScreenState extends State<DiplomacyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _partnerId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final effective = controller.allCountries.isNotEmpty
        ? controller.allCountries
        : _fallbackCountries;
    final isFallback = controller.allCountries.isEmpty;
    final simId = s.countryId;
    final activeId = controller.activeCountryId;

    final byId = {for (final c in effective) c.id: c};
    // Mitra default: negara pertama yang bukan aktif; aman bila 1 negara.
    var partnerOrNull = (_partnerId != null) ? byId[_partnerId] : null;
    partnerOrNull ??= effective.firstWhere(
      (c) => c.id != activeId,
      orElse: () => effective.first,
    );
    final Country partner = partnerOrNull;
    final activeCountry = byId[activeId] ?? partner;
    final simName = byId[simId]?.name ?? _prettyId(simId);
    final observing = activeId != simId;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _DiploHeader(quarter: s.quarter),
          Expanded(
            child: Column(
              children: [
                _ActiveBar(
                  effective: effective,
                  activeId: activeId,
                  simId: simId,
                  simName: simName,
                  observing: observing,
                  onPickActive: (id) => _pickActive(context, id),
                ),
                _PartnerStrip(
                  effective: effective,
                  activeId: activeId,
                  partnerId: partner.id,
                  onPickPartner: (id) => setState(() => _partnerId = id),
                ),
                if (isFallback)
                  const _FallbackNote(),
                _ProfileHeader(country: partner),
                Container(
                  height: 46,
                  decoration: const BoxDecoration(
                    color: SovereignColors.deepNavy,
                    border: Border(
                        bottom:
                            BorderSide(color: SovereignColors.border)),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorColor: SovereignColors.cyan,
                    indicatorWeight: 2.5,
                    labelColor: SovereignColors.cyan,
                    unselectedLabelColor: SovereignColors.muted,
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Statistik', height: 46),
                      Tab(text: 'Sumber Daya', height: 46),
                      Tab(text: 'Hubungan', height: 46),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _StatistikTab(
                        partner: partner,
                        isLiveSim: partner.id == simId,
                      ),
                      _SumberDayaTab(partner: partner),
                      _HubunganTab(
                        partner: partner,
                        activeCountry: activeCountry,
                        observing: observing,
                        simId: simId,
                        simName: simName,
                        onNewOffer: () => _openTradeForm(
                          context,
                          partnerId: partner.id,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickActive(BuildContext context, String id) {
    final controller = context.read<GameController>();
    try {
      controller.activeCountryId = id;
      // Bila mitra sama dengan aktif baru, geser mitra ke negara lain.
      if (_partnerId == id) {
        final eff = controller.allCountries.isNotEmpty
            ? controller.allCountries
            : _fallbackCountries;
        final other = eff.firstWhere(
          (c) => c.id != id,
          orElse: () => eff.first,
        );
        setState(() => _partnerId = other.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ganti sudut pandang: $e')),
      );
    }
  }

  Future<void> _openTradeForm(BuildContext context,
      {required String partnerId}) async {
    final controller = context.read<GameController>();
    if (controller.commodities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Komoditas belum tersedia — tidak bisa negosiasi.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _TradeFormSheet(initialPartnerId: partnerId),
    );
  }
}

// ── Header 60dp ───────────────────────────────────────────────────────

class _DiploHeader extends StatelessWidget {
  final int quarter;
  const _DiploHeader({required this.quarter});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SovereignSpacing.headerHeight,
      padding: const EdgeInsets.symmetric(
          horizontal: SovereignSpacing.margin, vertical: 8),
      decoration: const BoxDecoration(
        color: SovereignColors.deepNavy,
        border: Border(bottom: BorderSide(color: SovereignColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('DIPLOMASI',
                    style: TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                SizedBox(height: 2),
                Text('Profil & dagang bilateral',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1436C5F0),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Text(formatQuarter(quarter),
                style: const TextStyle(
                    color: SovereignColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Sudut pandang aktif + badge observasi ─────────────────────────────

class _ActiveBar extends StatelessWidget {
  final List<Country> effective;
  final String activeId;
  final String simId;
  final String simName;
  final bool observing;
  final ValueChanged<String> onPickActive;
  const _ActiveBar({
    required this.effective,
    required this.activeId,
    required this.simId,
    required this.simName,
    required this.observing,
    required this.onPickActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 10,
          SovereignSpacing.margin, 8),
      decoration: const BoxDecoration(
        color: SovereignColors.deepNavy,
        border: Border(bottom: BorderSide(color: SovereignColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('SUDUT PANDANG (NEGARA AKTIF)',
                    style: TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
              if (observing)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x22FBBF24),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x44FBBF24)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: 13, color: SovereignColors.amber),
                      const SizedBox(width: 5),
                      Text('Observasi (sim tetap $simName)',
                          style: const TextStyle(
                              color: SovereignColors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in effective)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ActiveChip(
                      country: c,
                      selected: c.id == activeId,
                      onTap: () => onPickActive(c.id),
                    ),
                  ),
              ],
            ),
          ),
          if (observing) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x0FFBBF24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FBBF24)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: SovereignColors.amber, size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Divergensi known: sim tetap berjalan untuk negara awal. Kontrak yang tak libatkan sim dicatat sebagai transit (no-op) — tak pengaruhi GDP/devisa sampai Fase-2. Bukan klaim fungsional.',
                      style: TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final Country country;
  final bool selected;
  final VoidCallback onTap;
  const _ActiveChip(
      {required this.country, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Sudut pandang ${country.name}${selected ? ', aktif' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0x1436C5F0)
                : SovereignColors.blueSlate,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? SovereignColors.cyan
                  : SovereignColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FlagDot(code: country.id, size: 30),
              const SizedBox(width: 8),
              Text(country.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? SovereignColors.cyan
                          : SovereignColors.ink)),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    size: 15, color: SovereignColors.cyan),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pilih mitra diprofilkan ───────────────────────────────────────────

class _PartnerStrip extends StatelessWidget {
  final List<Country> effective;
  final String activeId;
  final String partnerId;
  final ValueChanged<String> onPickPartner;
  const _PartnerStrip({
    required this.effective,
    required this.activeId,
    required this.partnerId,
    required this.onPickPartner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 10,
          SovereignSpacing.margin, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PILIH NEGARA → PROFIL',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: effective.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final c = effective[i];
              final isPartner = c.id == partnerId;
              final isActive = c.id == activeId;
              return _PartnerRow(
                country: c,
                isPartner: isPartner,
                isActive: isActive,
                onTap: () => onPickPartner(c.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PartnerRow extends StatelessWidget {
  final Country country;
  final bool isPartner;
  final bool isActive;
  final VoidCallback onTap;
  const _PartnerRow({
    required this.country,
    required this.isPartner,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gdpCap =
        country.population == 0 ? 0 : country.gdp / country.population;
    return Semantics(
      button: true,
      selected: isPartner,
      label:
          'Profil ${country.name}, GDP per kapita ${formatCompactUsd(gdpCap.toDouble())}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SovereignSpacing.radiusSmall),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: 56, maxHeight: 64),
          child: Ink(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isPartner
                ? const Color(0x1436C5F0)
                : SovereignColors.blueSlate,
            borderRadius:
                BorderRadius.circular(SovereignSpacing.radiusSmall),
            border: Border.all(
              color:
                  isPartner ? SovereignColors.cyan : SovereignColors.border,
            ),
          ),
          child: Row(
            children: [
              _FlagDot(code: country.id, size: 38),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(country.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x1422C55E),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('AKTIF',
                                style: TextStyle(
                                    color: SovereignColors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatPopulation(country.population)} • ${formatCompactUsd(country.gdp)} • ${_prettyIncome(country.incomeGroup)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: SovereignColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isPartner
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isPartner
                    ? SovereignColors.cyan
                    : SovereignColors.mutedDim,
                size: 22,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _FallbackNote extends StatelessWidget {
  const _FallbackNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 0,
          SovereignSpacing.margin, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storage_rounded,
              color: SovereignColors.muted, size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Daftar negara fallback statis (ID/JP/BR) — allCountries kosong. Profil dari config bawaan, bukan live sim.',
              style: TextStyle(
                  color: SovereignColors.muted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header profil 100–140dp ───────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Country country;
  const _ProfileHeader({required this.country});

  @override
  Widget build(BuildContext context) {
    final gdpCap = country.population == 0
        ? 0.0
        : country.gdp / country.population;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          SovereignSpacing.margin, 2, SovereignSpacing.margin, 0),
      constraints: const BoxConstraints(minHeight: 108, maxHeight: 138),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        border: Border.all(color: SovereignColors.border),
        gradient: const LinearGradient(
          colors: [Color(0xFF102C43), Color(0xFF0C2236)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _FlagDot(code: country.id, size: 54, big: true),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${_prettyIncome(country.incomeGroup)} • ${formatPopulation(country.population)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SovereignColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _HeadStat(
                          label: 'GDP',
                          value: formatCompactUsd(country.gdp)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeadStat(
                          label: 'GDP/kapita',
                          value: formatCompactUsd(gdpCap)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeadStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: SovereignColors.mutedDim,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 1),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, height: 1.15)),
      ],
    );
  }
}

// ═════════ Tab Statistik ═════════

class _StatistikTab extends StatelessWidget {
  final Country partner;
  final bool isLiveSim;
  const _StatistikTab({required this.partner, required this.isLiveSim});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final gdpCap = partner.population == 0
        ? 0.0
        : partner.gdp / partner.population;

    // Bila mitra adalah negara sim → angka live; selain itu statis config.
    final gdp = (isLiveSim) ? s.gdp : partner.gdp;
    final infl = (isLiveSim) ? s.inflation : partner.inflation;
    final unemp = (isLiveSim) ? s.unemployment : partner.unemployment;
    final debt = (isLiveSim) ? s.debtToGdp : partner.debtToGdp;
    final fx = (isLiveSim) ? s.fxReserves : partner.fxReserves;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isLiveSim)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: SovereignColors.deepNavySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SovereignColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: SovereignColors.muted, size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Angka makro negara ini statis dari config — hanya negara sim yang live per kuartal.',
                      style: TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          _InfoRow(
              label: 'Populasi',
              value: formatPopulation(partner.population),
              sub: _prettyIncome(partner.incomeGroup)),
          _InfoRow(
              label: 'GDP',
              value: formatCompactUsd(gdp),
              sub: isLiveSim ? 'Live kuartal berjalan' : 'Level awal config'),
          _InfoRow(
              label: 'GDP per kapita',
              value: formatCompactUsd(isLiveSim && partner.population > 0
                  ? s.gdp / partner.population
                  : gdpCap),
              sub: 'GDP ÷ populasi'),
          _InfoRow(
              label: 'Inflasi',
              value: formatPercent(infl),
              sub: _toneWord(_inflationStatus(infl)),
              tone: _inflationStatus(infl)),
          _InfoRow(
              label: 'Pengangguran',
              value: formatPercent(unemp),
              sub: _toneWord(_unempStatus(unemp)),
              tone: _unempStatus(unemp)),
          _InfoRow(
              label: 'Utang / GDP',
              value: formatDebtRatio(debt),
              sub: debt < 0.45
                  ? 'Ringan'
                  : debt < 0.6
                      ? 'Waspada'
                      : 'Berat',
              tone: debt < 0.45
                  ? SovereignStatus.good
                  : debt < 0.6
                      ? SovereignStatus.warn
                      : SovereignStatus.bad),
          _InfoRow(
              label: 'Devisa',
              value: formatCompactUsd(fx),
              sub: fx >= 100e9
                  ? 'Kuat'
                  : fx >= 50e9
                      ? 'Cukup'
                      : 'Tipis',
              tone: fx >= 100e9
                  ? SovereignStatus.good
                  : fx >= 50e9
                      ? SovereignStatus.warn
                      : SovereignStatus.bad),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final SovereignStatus? tone;
  const _InfoRow({
    required this.label,
    required this.value,
    this.sub = '',
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final t = tone;
    return Container(
      constraints: const BoxConstraints(minHeight: 52, maxHeight: 64),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        children: [
          if (t != null) ...[
            Icon(t.icon, size: 17, color: t.color),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (sub.trim().isNotEmpty)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t?.color ?? SovereignColors.mutedDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ═════════ Tab Sumber Daya ═════════

class _SumberDayaTab extends StatelessWidget {
  final Country partner;
  const _SumberDayaTab({required this.partner});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final commodities = controller.commodities;
    final outlook = _outlookOf(controller, partner);
    final s = controller.current;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('KEUNGGULAN (SURPLUS)',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          if (partner.resources.isEmpty)
            const _EmptyLine(text: 'Tak ada keunggulan tercatat.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in partner.resources)
                  _ResChip(
                      text: _prettyId(r),
                      icon: Icons.trending_up_rounded,
                      color: SovereignColors.green),
              ],
            ),
          const SizedBox(height: 14),
          const Text('KELEMAHAN (BUTUH IMPOR)',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          if (partner.importNeeds.isEmpty)
            const _EmptyLine(text: 'Tak ada kebutuhan impor tercatat.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in partner.importNeeds)
                  _ResChip(
                      text: _prettyId(r),
                      icon: Icons.trending_down_rounded,
                      color: SovereignColors.amber),
              ],
            ),
          const SizedBox(height: 14),
          const Text('KOMODITAS • SURPLUS / BUTUH',
              style: TextStyle(
                  color: SovereignColors.mutedDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          if (commodities.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SovereignColors.blueSlate,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SovereignColors.border),
              ),
              child: const Text(
                'Komoditas belum tersedia — config kosong. Negosiasi dinonaktifkan jujur.',
                style: TextStyle(
                    color: SovereignColors.muted, fontSize: 13, height: 1.5),
              ),
            )
          else
            for (final c in commodities)
              _CommodityOutlookRow(
                commodityId: c.id,
                unit: c.unit,
                marketPrice:
                    s.prices[c.id] ?? c.baseGlobalPrice,
                outlook: outlook[c.id] ?? 'netral',
              ),
          const SizedBox(height: 8),
          const Text(
            'Surplus = ada di resources • Defisit = ada di importNeeds • Selain itu netral. Harga pasar = harga sim berjalan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SovereignColors.mutedDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ResChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _ResChip(
      {required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CommodityOutlookRow extends StatelessWidget {
  final String commodityId;
  final String unit;
  final double marketPrice;
  final String outlook;
  const _CommodityOutlookRow({
    required this.commodityId,
    required this.unit,
    required this.marketPrice,
    required this.outlook,
  });

  @override
  Widget build(BuildContext context) {
    final st = outlook == 'surplus'
        ? SovereignStatus.good
        : outlook == 'defisit'
            ? SovereignStatus.warn
            : SovereignStatus.neutral;
    final label = outlook == 'surplus'
        ? 'Surplus'
        : outlook == 'defisit'
            ? 'Butuh'
            : 'Netral';
    final icon = outlook == 'surplus'
        ? Icons.north_east_rounded
        : outlook == 'defisit'
            ? Icons.south_west_rounded
            : Icons.remove_rounded;
    return Container(
      constraints: const BoxConstraints(minHeight: 52, maxHeight: 64),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: st.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: st.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_prettyId(commodityId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  '\$${marketPrice.toStringAsFixed(0)}/unit • $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: st.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(st.label,
              style: TextStyle(
                  color: st.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Text(text,
          style: const TextStyle(
              color: SovereignColors.muted, fontSize: 13)),
    );
  }
}

// ═════════ Tab Hubungan ═════════

class _HubunganTab extends StatelessWidget {
  final Country partner;
  final Country activeCountry;
  final bool observing;
  final String simId;
  final String simName;
  final VoidCallback onNewOffer;
  const _HubunganTab({
    required this.partner,
    required this.activeCountry,
    required this.observing,
    required this.simId,
    required this.simName,
    required this.onNewOffer,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final pOutlook = _outlookOf(controller, partner);
    final aOutlook = _outlookOf(controller, activeCountry);

    final activeSurplusPartnerNeeds = <String>[];
    final partnerSurplusActiveNeeds = <String>[];
    for (final c in controller.commodities) {
      final a = aOutlook[c.id] ?? 'netral';
      final p = pOutlook[c.id] ?? 'netral';
      if (a == 'surplus' && p == 'defisit') {
        activeSurplusPartnerNeeds.add(c.id);
      }
      if (p == 'surplus' && a == 'defisit') {
        partnerSurplusActiveNeeds.add(c.id);
      }
    }

    final proposals = controller.proposals
        .where((e) =>
            e.fromCountry == partner.id || e.toCountry == partner.id)
        .toList();
    final contracts = controller.contracts
        .where((e) =>
            e.fromCountry == partner.id || e.toCountry == partner.id)
        .toList();
    final totalProposals = controller.proposals.length;
    final totalContracts = controller.contracts.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SovereignSpacing.margin, 12,
          SovereignSpacing.margin, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: SovereignColors.blueSlate,
              borderRadius:
                  BorderRadius.circular(SovereignSpacing.radius),
              border: Border.all(color: SovereignColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handshake_outlined,
                        color: SovereignColors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${activeCountry.name} ↔ ${partner.name}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (activeSurplusPartnerNeeds.isEmpty &&
                    partnerSurplusActiveNeeds.isEmpty)
                  const Text(
                    'Belum ada kecocokan surplus↔butuh langsung. Cek tab Sumber Daya untuk peluang netral, atau tawarkan volume kecil dulu.',
                    style: TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 13,
                        height: 1.5),
                  )
                else ...[
                  if (activeSurplusPartnerNeeds.isNotEmpty)
                    _MatchLine(
                      icon: Icons.north_east_rounded,
                      color: SovereignColors.green,
                      text:
                          'Ekspor cocok: ${activeSurplusPartnerNeeds.map(_prettyId).join(', ')} (kita surplus → mitra butuh).',
                    ),
                  if (partnerSurplusActiveNeeds.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _MatchLine(
                      icon: Icons.south_west_rounded,
                      color: SovereignColors.amber,
                      text:
                          'Impor cocok: ${partnerSurplusActiveNeeds.map(_prettyId).join(', ')} (mitra surplus → kita butuh).',
                    ),
                  ],
                ],
                if (observing) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Observasi (sim tetap $simName): saran di atas memakai data statis config, belum tentu menggerakkan sim.',
                    style: const TextStyle(
                        color: SovereignColors.mutedDim,
                        fontSize: 12,
                        height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: SovereignSpacing.touchMin,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNewOffer,
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: Text('Buat Penawaran ke ${partner.name}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SovereignColors.green,
                foregroundColor: SovereignColors.deepNavy,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(
              title: 'Proposal (${proposals.length})',
              subtitle: totalProposals == proposals.length
                  ? 'Semua proposal'
                  : '${proposals.length} terkait mitra ini • $totalProposals total'),
          const SizedBox(height: 8),
          if (proposals.isEmpty)
            _HonestEmpty(
              icon: Icons.mail_outline_rounded,
              title: 'Belum ada proposal dengan ${partner.name}.',
              body:
                  'Pilih komoditas yang surplus/butuh di atas, lalu buat penawaran pertama. Draft tidak mengubah sim sampai diterima + kuartal diproses.',
            )
          else
            for (final p in proposals)
              _ProposalCard(
                  proposal: p,
                  currentQuarter: s.quarter,
                  simId: simId,
                  simName: simName),
          const SizedBox(height: 14),
          _SectionTitle(
              title: 'Kontrak (${contracts.length})',
              subtitle: totalContracts == contracts.length
                  ? 'Semua kontrak'
                  : '${contracts.length} terkait mitra ini • $totalContracts total'),
          const SizedBox(height: 8),
          if (contracts.isEmpty)
            const _HonestEmpty(
              icon: Icons.description_outlined,
              title: 'Belum ada kontrak aktif.',
              body:
                  'Terima sebuah proposal untuk membuat kontrak (mulai K+1, durasi 4). Efek sim baru setelah Proses Kuartal di Beranda.',
            )
          else
            for (final c in contracts)
              _ContractCard(
                  contract: c,
                  currentQuarter: s.quarter,
                  simId: simId,
                  simName: simName),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        Text(subtitle,
            style: const TextStyle(
                color: SovereignColors.mutedDim, fontSize: 11)),
      ],
    );
  }
}

class _MatchLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _MatchLine(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }
}

class _HonestEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _HonestEmpty(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SovereignColors.muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(
                        color: SovereignColors.muted,
                        fontSize: 12,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu proposal: amber / hijau / abu + aksi ────────────────────────

class _ProposalCard extends StatelessWidget {
  final TradeProposal proposal;
  final int currentQuarter;
  final String simId;
  final String simName;
  const _ProposalCard({
    required this.proposal,
    required this.currentQuarter,
    required this.simId,
    required this.simName,
  });

  @override
  Widget build(BuildContext context) {
    final st = proposal.status;
    final isPending = st == TradeStatus.proposal;
    final isDone = st == TradeStatus.accepted || st == TradeStatus.active;
    final isFinal =
        st == TradeStatus.cancelled || st == TradeStatus.rejected;

    final badgeColor = isPending
        ? SovereignColors.amber
        : isDone
            ? SovereignColors.green
            : SovereignColors.muted;
    final badgeIcon = isPending
        ? Icons.hourglass_top_rounded
        : isDone
            ? Icons.check_circle_rounded
            : Icons.cancel_outlined;
    final badgeText = isPending
        ? 'Proposal • Menunggu'
        : st == TradeStatus.accepted
            ? 'Diterima • Hijau'
            : st == TradeStatus.active
                ? 'Kontrak aktif • Hijau'
                : st == TradeStatus.rejected
                    ? 'Ditolak • Abu'
                    : 'Dibatalkan • Abu';
    final involvesSim = proposal.fromCountry == simId ||
        proposal.toCountry == simId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: SovereignColors.blueSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(badgeText,
                        style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Spacer(),
              Text('K${proposal.createdQuarter} • ${proposal.id}',
                  style: const TextStyle(
                      color: SovereignColors.mutedDim, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_prettyId(proposal.fromCountry)} → ${_prettyId(proposal.toCountry)}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            '${_prettyId(proposal.commodityId)} • ${proposal.qty.toStringAsFixed(0)} × \$${proposal.pricePerUnit.toStringAsFixed(0)} = ${formatCompactUsd(proposal.totalValue)}',
            style: const TextStyle(
                color: SovereignColors.muted, fontSize: 13, height: 1.45),
          ),
          if (!involvesSim) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x0FFBBF24),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0x33FBBF24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 13, color: SovereignColors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Observasi (sim tetap $simName) — transit no-op.',
                      style: const TextStyle(
                          color: SovereignColors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isFinal) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isPending)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _accept(context),
                        icon: const Icon(Icons.check_rounded, size: 19),
                        label: const Text('Terima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SovereignColors.green,
                          foregroundColor: SovereignColors.deepNavy,
                        ),
                      ),
                    ),
                  ),
                if (isPending) const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(context),
                      icon: const Icon(Icons.close_rounded, size: 19),
                      label: const Text('Batalkan'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    final controller = context.read<GameController>();
    final ok = await showSovereignConfirmSheet(
      context: context,
      title: 'Terima proposal ${proposal.id}?',
      subtitle:
          'Kontrak mulai K${currentQuarter + 1} durasi 4 kuartal. Efek sim baru setelah Proses Kuartal.',
      comparisons: [
        ConfirmComparison(
            label: 'Rute',
            before: 'Draft',
            after:
                '${_prettyId(proposal.fromCountry)} → ${_prettyId(proposal.toCountry)}'),
        ConfirmComparison(
            label: 'Volume',
            before: '—',
            after:
                '${proposal.qty.toStringAsFixed(0)} × ${_prettyId(proposal.commodityId)}'),
        ConfirmComparison(
            label: 'Nilai',
            before: '—',
            after: formatCompactUsd(proposal.totalValue)),
      ],
      impacts: const [
        ConfirmImpact(
            text: 'Stok & devisa dicek jujur saat terima (gagal bila tak cukup).',
            tone: SovereignStatus.neutral),
      ],
      confirmLabel: 'Ya, terima',
    );
    if (!ok || !context.mounted) return;
    try {
      controller.acceptTrade(proposal.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Proposal diterima — kontrak K${currentQuarter + 1}–K${currentQuarter + 4} dibuat.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal terima: $e')),
      );
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showSovereignConfirmSheet(
      context: context,
      title: 'Batalkan proposal ${proposal.id}?',
      subtitle:
          'Kontrak terkait (bila ada) ikut dihapus agar tak diterapkan engine.',
      destructive: true,
      confirmLabel: 'Ya, batalkan',
    );
    if (!ok || !context.mounted) return;
    try {
      context.read<GameController>().cancelTrade(proposal.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal dibatalkan.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal batalkan: $e')),
      );
    }
  }
}

// ── Kartu kontrak ─────────────────────────────────────────────────────

class _ContractCard extends StatelessWidget {
  final TradeContract contract;
  final int currentQuarter;
  final String simId;
  final String simName;
  const _ContractCard({
    required this.contract,
    required this.currentQuarter,
    required this.simId,
    required this.simName,
  });

  @override
  Widget build(BuildContext context) {
    final live = contract.isActiveFor(currentQuarter);
    final upcoming = currentQuarter < contract.startQuarter;
    final badgeColor = live
        ? SovereignColors.green
        : upcoming
            ? SovereignColors.cyan
            : SovereignColors.muted;
    final badgeText = live
        ? 'Aktif K$currentQuarter • Hijau'
        : upcoming
            ? 'Terjadwal K${contract.startQuarter} • Antre'
            : 'Selesai • Abu';
    final badgeIcon = live
        ? Icons.play_circle_filled_rounded
        : upcoming
            ? Icons.schedule_rounded
            : Icons.archive_outlined;
    final involvesSim = contract.fromCountry == simId ||
        contract.toCountry == simId;
    final endQ = contract.startQuarter + contract.durationQuarters - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: SovereignColors.deepNavy,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(badgeText,
                        style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Spacer(),
              Text(contract.id,
                  style: const TextStyle(
                      color: SovereignColors.mutedDim, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_prettyId(contract.fromCountry)} → ${_prettyId(contract.toCountry)}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            '${_prettyId(contract.commodityId)} • ${contract.qty.toStringAsFixed(0)}/krt × \$${contract.pricePerUnit.toStringAsFixed(0)} • K${contract.startQuarter}–K$endQ (${contract.durationQuarters} krt)',
            style: const TextStyle(
                color: SovereignColors.muted, fontSize: 13, height: 1.5),
          ),
          Text(
            'Nilai/krt ${formatCompactUsd(contract.totalValue)}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (!involvesSim) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0x0FFBBF24),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0x33FBBF24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 14, color: SovereignColors.amber),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Observasi (sim tetap $simName) — kontrak transit, engine no-op. Tercatat, tak gerakkan sim.',
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 12,
                          height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════ Form negosiasi (bottom-sheet) ═════════

class _TradeFormSheet extends StatefulWidget {
  final String initialPartnerId;
  const _TradeFormSheet({required this.initialPartnerId});

  @override
  State<_TradeFormSheet> createState() => _TradeFormSheetState();
}

class _TradeFormSheetState extends State<_TradeFormSheet> {
  bool _isExport = true;
  String? _partnerId;
  String? _commodityId;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  bool _priceTouched = false;

  @override
  void initState() {
    super.initState();
    _partnerId = widget.initialPartnerId;
    _qtyCtrl = TextEditingController(text: '100');
    _priceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final s = controller.current;
    final effective = controller.allCountries.isNotEmpty
        ? controller.allCountries
        : _fallbackCountries;
    final byId = {for (final c in effective) c.id: c};
    final activeId = controller.activeCountryId;
    var partnerId = _partnerId;
    if (partnerId == null ||
        byId[partnerId] == null ||
        partnerId == activeId) {
      partnerId = effective
          .firstWhere((c) => c.id != activeId,
              orElse: () => effective.first)
          .id;
      _partnerId = partnerId;
    }
    final commodities = controller.commodities;
    var commodityId = _commodityId;
    if (commodityId == null ||
        !commodities.any((c) => c.id == commodityId)) {
      commodityId = commodities.isEmpty ? null : commodities.first.id;
      _commodityId = commodityId;
    }
    final basePrice = commodityId == null
        ? 0.0
        : commodities
            .firstWhere((c) => c.id == commodityId,
                orElse: () => commodities.first)
            .baseGlobalPrice;
    final marketPrice = commodityId == null
        ? 0.0
        : (s.prices[commodityId] ?? basePrice);
    if (!_priceTouched &&
        _priceCtrl.text.trim().isEmpty &&
        marketPrice > 0) {
      _priceCtrl.text = marketPrice.toStringAsFixed(0);
    }

    final qty = _parse(_qtyCtrl.text);
    final price = _parse(_priceCtrl.text);
    final total =
        (qty != null && price != null) ? qty * price : null;
    final outlookPartner =
        _outlookOf(controller, byId[partnerId]!);
    final outlookActive =
        _outlookOf(controller, byId[activeId] ?? byId[partnerId]!);
    final hint = _hintFor(
      commodityId: commodityId,
      isExport: _isExport,
      partnerOutlook: outlookPartner[commodityId] ?? 'netral',
      activeOutlook: outlookActive[commodityId] ?? 'netral',
    );

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final partnerItems = [
      for (final c in effective)
        if (c.id != activeId)
          DropdownMenuItem(value: c.id, child: Text(c.name)),
    ];
    // Bila hanya 1 negara (tanpa mitra), izinkan pilih aktif agar
    // validasi API yang bicara (snackbar alasan), bukan crash dropdown.
    if (partnerItems.isEmpty) {
      for (final c in effective) {
        partnerItems.add(DropdownMenuItem(value: c.id, child: Text(c.name)));
      }
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x1422C55E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SovereignColors.border),
                  ),
                  child: const Icon(Icons.handshake_outlined,
                      color: SovereignColors.green, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Penawaran dagang',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.25)),
                      SizedBox(height: 2),
                      Text(
                        'Atur komoditas, volume & harga — tinjau sebelum kirim.',
                        style: TextStyle(
                            color: SovereignColors.muted,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Tutup',
                  style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('ARAH',
                style: TextStyle(
                    color: SovereignColors.mutedDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DirectionButton(
                    selected: _isExport,
                    icon: Icons.north_east_rounded,
                    label: 'Ekspor',
                    sub: 'Aktif → mitra',
                    onTap: () =>
                        setState(() => _isExport = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DirectionButton(
                    selected: !_isExport,
                    icon: Icons.south_west_rounded,
                    label: 'Impor',
                    sub: 'Mitra → aktif',
                    onTap: () =>
                        setState(() => _isExport = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SheetDropdown<String>(
                    label: 'Mitra',
                    value: partnerItems
                            .any((e) => e.value == partnerId)
                        ? partnerId
                        : null,
                    hint: partnerItems.isEmpty
                        ? 'Tak ada mitra lain'
                        : 'Pilih mitra',
                    items: partnerItems,
                    onChanged: (v) =>
                        setState(() => _partnerId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SheetDropdown<String>(
              label:
                  'Komoditas (${commodities.length} tersedia)',
              value: commodityId,
              hint: commodities.isEmpty
                  ? 'Tak ada komoditas'
                  : 'Pilih komoditas',
              items: [
                for (final c in commodities)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                        '${_prettyId(c.id)} • \$${(s.prices[c.id] ?? c.baseGlobalPrice).toStringAsFixed(0)}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _commodityId = v;
                _priceTouched = false;
                _priceCtrl.text = '';
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SheetNumber(
                    label: 'Qty / kuartal',
                    controller: _qtyCtrl,
                    hint: 'cth 100',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetNumber(
                    label: 'Harga / unit (USD)',
                    controller: _priceCtrl,
                    hint: marketPrice > 0
                        ? 'Pasar \$${marketPrice.toStringAsFixed(0)}'
                        : 'cth 500',
                    onChanged: (_) => setState(() {
                      _priceTouched = true;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: SovereignColors.deepNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SovereignColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: SovereignColors.cyan, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              total == null
                  ? 'Total: — (isi qty & harga > 0)'
                  : 'Total/kuartal: ${formatCompactUsd(total)} • Mulai K${s.quarter + 1} × 4 krt',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: SovereignColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: SovereignSpacing.processButtonHeight,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (commodityId == null)
                    ? null
                    : () => _reviewAndSend(
                        context,
                        activeId: activeId,
                        partnerId: partnerId!,
                        commodityId: commodityId!,
                        marketPrice: marketPrice),
                icon: const Icon(Icons.fact_check_outlined, size: 20),
                label: const Text('Tinjau & kirim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SovereignColors.green,
                  foregroundColor: SovereignColors.deepNavy,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: SovereignSpacing.touchMin,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewAndSend(
    BuildContext context, {
    required String activeId,
    required String partnerId,
    required String commodityId,
    required double marketPrice,
  }) async {
    final controller = context.read<GameController>();
    final s = controller.current;
    final qty = _parse(_qtyCtrl.text);
    final price = _parse(_priceCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Qty harus angka > 0 (cth 100).')),
      );
      return;
    }
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harga harus angka > 0.')),
      );
      return;
    }
    final from = _isExport ? activeId : partnerId;
    final to = _isExport ? partnerId : activeId;
    final total = qty * price;
    final ok = await showSovereignConfirmSheet(
      context: context,
      title: 'Kirim penawaran dagang?',
      subtitle:
          'Draft tidak mengubah sim. Kontrak (bila diterima) mulai K${s.quarter + 1} durasi 4.',
      comparisons: [
        ConfirmComparison(
            label: 'Rute',
            before: '—',
            after: '${_prettyId(from)} → ${_prettyId(to)}'),
        ConfirmComparison(
            label: 'Komoditas',
            before: '—',
            after:
                '${_prettyId(commodityId)} • ${qty.toStringAsFixed(0)}/krt'),
        ConfirmComparison(
            label: 'Harga',
            before: 'Pasar \$${marketPrice.toStringAsFixed(0)}',
            after: '\$${price.toStringAsFixed(0)}/unit'),
        ConfirmComparison(
            label: 'Nilai/kuartal',
            before: '—',
            after: formatCompactUsd(total)),
      ],
      impacts: [
        if (_isExport)
          const ConfirmImpact(
              text: 'Ekspor butuh stok cukup saat diterima.',
              tone: SovereignStatus.neutral)
        else
          const ConfirmImpact(
              text: 'Impor butuh devisa cukup (0,1% nilai) saat diterima.',
              tone: SovereignStatus.neutral),
      ],
      costText:
          'Nilai ${formatCompactUsd(total)}/kuartal × 4 kuartal = ${formatCompactUsd(total * 4)} (gross, sebelum tarif & engine).',
      confirmLabel: 'Ya, kirim penawaran',
    );
    if (!ok || !context.mounted) return;
    try {
      controller.proposeTrade(
        fromCountry: from,
        toCountry: to,
        commodityId: commodityId,
        qty: qty,
        pricePerUnit: price,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Penawaran terkirim — pantau di tab Hubungan.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim: $e')),
      );
    }
  }
}

class _DirectionButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _DirectionButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $sub',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0x1422C55E)
                : SovereignColors.deepNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? SovereignColors.green
                    : SovereignColors.border),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? SovereignColors.green
                      : SovereignColors.muted),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? SovereignColors.green
                              : SovereignColors.ink)),
                  Text(sub,
                      style: const TextStyle(
                          color: SovereignColors.muted,
                          fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _SheetDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: SovereignColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SovereignColors.deepNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SovereignColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(hint ?? 'Pilih',
                  style: const TextStyle(
                      color: SovereignColors.mutedDim, fontSize: 13)),
              isExpanded: true,
              dropdownColor: SovereignColors.blueSlateElevated,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetNumber extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SheetNumber({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: SovereignColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: SovereignColors.deepNavy,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: SovereignColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: SovereignColors.border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Util ──────────────────────────────────────────────────────────────

Map<String, String> _outlookOf(
    GameController controller, Country partner) {
  final live = controller.outlookFor(partner.id);
  if (live.isNotEmpty) return live;
  // Fallback manual (resources→surplus dst) bila allCountries kosong.
  final out = <String, String>{};
  for (final c in controller.commodities) {
    if (partner.resources.contains(c.id)) {
      out[c.id] = 'surplus';
    } else if (partner.importNeeds.contains(c.id)) {
      out[c.id] = 'defisit';
    } else {
      out[c.id] = 'netral';
    }
  }
  return out;
}

String _hintFor({
  required String? commodityId,
  required bool isExport,
  required String partnerOutlook,
  required String activeOutlook,
}) {
  if (commodityId == null) return 'Pilih komoditas dulu.';
  final name = _prettyId(commodityId);
  if (isExport) {
    if (partnerOutlook == 'defisit' && activeOutlook == 'surplus') {
      return 'Cocok: kita surplus $name, mitra butuh $name — peluang diterima besar.';
    }
    if (partnerOutlook == 'defisit') {
      return 'Mitra butuh $name — cek stok kita cukup sebelum terima.';
    }
    if (activeOutlook != 'surplus') {
      return 'Kita tidak surplus $name — pastikan stok cukup, atau tawarkan volume kecil.';
    }
    return 'Kita surplus $name; mitra $partnerOutlook — masih layak ditawarkan.';
  }
  if (partnerOutlook == 'surplus' && activeOutlook == 'defisit') {
    return 'Cocok: mitra surplus $name, kita butuh $name — impor disarankan.';
  }
  if (partnerOutlook != 'surplus') {
    return 'Mitra tidak surplus $name — tanyakan volume kecil dulu.';
  }
  return 'Mitra surplus $name; kita $activeOutlook — cek devisa untuk biaya impor.';
}

double? _parse(String raw) {
  final t = raw.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  String normalized;
  if (t.contains('.') && t.contains(',')) {
    // Indonesia: "1.000,5" → "1000.5".
    normalized = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains(',')) {
    normalized = t.replaceAll(',', '.');
  } else {
    normalized = t;
  }
  final v = double.tryParse(normalized);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

String _prettyId(String id) {
  final s = id.replaceAll('_', ' ').trim();
  if (s.isEmpty) return id;
  return s
      .split(' ')
      .map((w) =>
          w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String _prettyIncome(String raw) {
  final s = raw.replaceAll('_', ' ');
  if (s.isEmpty) return s;
  final titled = s
      .split(' ')
      .map((w) =>
          w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
  return titled
      .replaceAll('Upper Middle Income', 'Menengah-atas')
      .replaceAll('High Income', 'Maju');
}

SovereignStatus _inflationStatus(double v) {
  if (v < 0.04) return SovereignStatus.good;
  if (v < 0.06) return SovereignStatus.warn;
  return SovereignStatus.bad;
}

SovereignStatus _unempStatus(double v) {
  if (v < 0.06) return SovereignStatus.good;
  if (v < 0.08) return SovereignStatus.warn;
  return SovereignStatus.bad;
}

String _toneWord(SovereignStatus s) =>
    s == SovereignStatus.good
        ? 'Terkendali • Baik'
        : s == SovereignStatus.warn
            ? 'Hangat • Waspada'
            : 'Tinggi • Kritis';

class _FlagDot extends StatelessWidget {
  final String code;
  final double size;
  final bool big;
  const _FlagDot(
      {required this.code, required this.size, this.big = false});

  @override
  Widget build(BuildContext context) {
    final initials = code.trim().isEmpty
        ? '??'
        : code.trim().substring(0, 2).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: big
            ? const LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFF1E3A52), Color(0xFF0B2237)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(big ? 16 : 12),
        border: Border.all(color: SovereignColors.border),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                fontSize: big ? 15 : 12,
                fontWeight: FontWeight.w800,
                color: big
                    ? SovereignColors.deepNavy
                    : SovereignColors.cyan)),
      ),
    );
  }
}
