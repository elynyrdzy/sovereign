# Balancing tuas kebijakan (Fase 0 — SEMENTARA)
> Semua formula placeholder linier; tuning final menyusul (blueprint §12).
> Sumber: `lib/sim/formulas.dart`, `lib/sim/engine.dart`, `assets/config/policies.json`.

| Tuas | Efek kode (satu baris) | Rentang config | Eksploit ekstrem | Clamp |
|---|---|---|---|---|
| pajak | `revenue=gdp*rate*0.8`; `consumption=base*(1-rate*0.5)` | 0.05–0.35, def 0.15 | min 0.05 + belanja max → defisit/utang meledak | floor `max(0,·)`; range via `validate` |
| belanja | `GDP+=G` langsung; `defisit=G-revenue`; `debt+=defisit/gdp`; `fx-=defisit*0.05` | 0–200M USD/kuartal, def 80M | max 200M → pompa-G, utang tanpa batas atas | `fx>=0`; debt tanpa clamp atas |
| bunga | `invest=base*(1-(r-0.06)*2.5)`; `rateEffect=-(r-0.06)*0.35` | 0.0–0.2, def 0.06 (=`baseRateRef`) | r=0.2 → investasi → nol; r=0 → stimulus gratis | invest floor 0; inflasi clamp [-0.1, 0.5] |
| tarif_impor | impor darurat: `effPrice=price*(1+tarif)`; `M+=vol*effPrice` (auto-trade saja) | 0.0–0.5, def 0.1 | tarif 0.5 → M bengkak, GDP tergerus via (X−M) | floor `max(0,tarif)`; tanpa clamp atas |
| subsidi_ekspor | ekspor surplus: `X+=vol*price*(1+subsidi*0.8)` (auto-trade saja) | 0.0–0.3, def 0.05 | 0.3 → X +24% tanpa biaya fiskal | tanpa biaya/defisit terkait; tanpa clamp |
| trade_terms | kontrak bilateral saja: `fxEks*=(1-t*0.5)`, `fxImp*=(1+t)`; auto-trade kebal | 0.0–0.5, def 0.1; default kode 0.0 | t=0.5 → impor mahal +50% fx, ekspor −25% fx | `terms>=0` else throw; default 0 = no-op |

Catatan: default config `trade_terms` (0.1) ≠ default kode (0.0, ora-2(4)) — tanpa kunci eksplisit tak ternerf.
Clamp global: inflasi [-0.1, 0.5], pengangguran [0, 0.35], `fx>=0`, prosperitas [0, 100], `debtToGdp` tanpa batas atas.
Mekanisme `PolicySet.validate` (throw vs clamp) di luar scope 3 file — belum diverifikasi.

## Butuh uji runtime
1. Pajak min + belanja max N kuartal: debtToGdp tumbuh tanpa batas?
2. Bunga 0.2 persisten: investasi → 0 dan inflasi mentok floor −0.1?
3. Subsidi 0.3 + surplus persisten: X tumbuh gratis tanpa biaya fiskal?
4. Kontrak dua arah trade_terms 0.5: laju drain vs gain fx?
5. Belanja max: pompa-G vs prosperitas (bobot utang 0.25)?
