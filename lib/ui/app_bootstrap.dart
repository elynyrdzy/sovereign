// Bootstrap Fase 0: muat 4 config JSON, rakit GameController, sediakan via Provider.
// Engine tidak diubah; UI hanya membaca state via controller.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/commodity.dart';
import '../models/country.dart';
import '../models/game_event.dart';
import '../models/policy.dart';
import '../models/quarter_state.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'app_shell.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';

class _Loaded {
  final GameController controller;
  final Country country;
  const _Loaded(this.controller, this.country);
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  int _reloadNonce = 0;

  Future<_Loaded> _load(BuildContext context) async {
    final bundle = DefaultAssetBundle.of(context);
    final countriesRaw = await bundle.loadString('assets/config/countries.json');
    final commoditiesRaw = await bundle.loadString('assets/config/commodities.json');
    final policiesRaw = await bundle.loadString('assets/config/policies.json');
    final eventsRaw = await bundle.loadString('assets/config/events.json');

    final countries = (jsonDecode(countriesRaw) as List)
        .map((e) => Country.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final commodities = (jsonDecode(commoditiesRaw) as List)
        .map((e) => Commodity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final policies = (jsonDecode(policiesRaw) as List)
        .map((e) => PolicyDefinition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final events = (jsonDecode(eventsRaw) as List)
        .map((e) => GameEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final country = countries.first;
    final initial = QuarterState.initial(
      countryId: country.id,
      gdp: country.gdp,
      inflation: country.inflation,
      unemployment: country.unemployment,
      debtToGdp: country.debtToGdp,
      fxReserves: country.fxReserves,
      basePrices: {for (final c in commodities) c.id: c.baseGlobalPrice},
      initialStocks: {for (final c in commodities) c.id: 1000.0},
    );

    final controller = GameController(
      initial: initial,
      commodities: commodities,
      events: events,
      policyDefs: policies,
      allCountries: countries,
      // Seed tetap Fase 0 agar deterministik antar sesi.
      seed: 20261014,
    );
    return _Loaded(controller, country);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Loaded>(
      key: ValueKey(_reloadNonce),
      future: _load(context),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: SovereignColors.deepNavy,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: SovereignColors.cyan),
                    SizedBox(height: 16),
                    Text(
                      'Menyiapkan negara…',
                      style: TextStyle(color: SovereignColors.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Scaffold(
            backgroundColor: SovereignColors.deepNavy,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(SovereignSpacing.margin),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: SovereignColors.red, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat data awal.',
                        style: TextStyle(
                            color: SovereignColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.error ?? 'config tidak valid'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: SovereignColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: SovereignSpacing.touchMin,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _reloadNonce++),
                          child: const Text('Coba Lagi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        final loaded = snap.data!;
        return ChangeNotifierProvider<GameController>.value(
          value: loaded.controller,
          // Aksesibilitas global (lib/ui saja): skala font via textScaler
          // + penguat kontras. Prefs gagal = default, tidak blokir loading.
          child: _AccessApplier(
            child: _TutorialGate(
              child: AppShell(country: loaded.country),
            ),
          ),
        );
      },
    );
  }
}

/// Mendorong TutorialScreen sekali per instalasi, tanpa menunda AppShell.
/// Dijalankan post-frame agar loading config tidak terblokir; seluruh
/// kegagalan prefs ditelan (lihat TutorialScreen.isDone/markDone).
/// Penjaga sesi [_shownThisRun] mencegah dorongan ganda saat rebuild
/// (mis. rotate) bila prefs sedang gagal tulis/baca.
class _TutorialGate extends StatefulWidget {
  final Widget child;
  const _TutorialGate({required this.child});

  @override
  State<_TutorialGate> createState() => _TutorialGateState();
}

class _TutorialGateState extends State<_TutorialGate> {
  static bool _shownThisRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_shownThisRun) return;
    _shownThisRun = true;
    bool done = true;
    try {
      done = await TutorialScreen.isDone();
    } catch (_) {
      return;
    }
    if (!mounted || done) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TutorialScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Penerap aksesibilitas global (lib/ui saja, tanpa sentuh sim/main/theme).
/// Membaca AccessBus (SharedPreferences defensif): teks besar via
/// MediaQuery textScaler 1,3×, kontras tinggi via penguat Theme lokal.
/// Gate tutorial tetap di dalam agar urutan dorongan tidak berubah.
class _AccessApplier extends StatefulWidget {
  final Widget child;
  const _AccessApplier({required this.child});

  @override
  State<_AccessApplier> createState() => _AccessApplierState();
}

class _AccessApplierState extends State<_AccessApplier> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget defensif: gagal = default sesi ini.
    AccessBus.load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessState>(
      valueListenable: AccessBus.current,
      builder: (ctx, access, _) {
        final withScale = MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: TextScaler.linear(access.textScale),
          ),
          child: widget.child,
        );
        if (!access.highContrast) return withScale;
        final base = Theme.of(ctx);
        return Theme(
          data: base.copyWith(
            textTheme: base.textTheme.apply(
              bodyColor: const Color(0xFFFFFFFF),
              displayColor: const Color(0xFFFFFFFF),
            ),
            dividerColor: const Color(0xFF3A5A78),
            colorScheme: base.colorScheme.copyWith(
              outline: const Color(0xFF3A5A78),
            ),
          ),
          child: withScale,
        );
      },
    );
  }
}
