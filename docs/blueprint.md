# BLUEPRINT GAME: SOVEREIGN — THE RESOURCE ECONOMY
## Dokumen Desain Game & Panduan Pengembangan

**Versi:** 1.0  
**Tanggal:** 14 Oktober 2026  
**Genre:** Turn-Based Grand Strategy / Economic Management Simulation  
**Platform target:** PC (Steam), dengan potensi porting ke mobile/tablet  
**Mode:** Single-player, dengan arsitektur siap untuk multiplayer asynchronous  
**Bahasa antarmuka awal:** Indonesia dan Inggris  

---

## 1. VISI GAME

### 1.1 Premis

Pemain berperan sebagai **Menteri Keuangan / kepala tim ekonomi sebuah negara nyata**. Tugas pemain adalah mengelola sumber daya terbatas untuk memenuhi kebutuhan domestik, menjaga stabilitas ekonomi, membangun pertumbuhan jangka panjang, dan menghadapi ketergantungan ekonomi antarnegara.

Game ini bukan sekadar game negara atau game politik. Fokus utamanya adalah **ekonomi sebagai sistem**: produksi, konsumsi, perdagangan, harga, tenaga kerja, utang, energi, pangan, teknologi, dan kebijakan publik.

### 1.2 Tujuan pengalaman pemain

Pemain harus merasakan bahwa setiap keputusan memiliki trade-off:

- Menurunkan pajak meningkatkan konsumsi, tetapi mengurangi pendapatan negara.
- Menaikkan suku bunga menekan inflasi, tetapi memperlambat investasi dan menciptakan pengangguran.
- Mensubsidi pangan dan energi menenangkan rakyat, tetapi membebani anggaran.
- Mengekspor bahan mentah menghasilkan devisa cepat, tetapi dapat menghambat industrialisasi.
- Melindungi industri lokal dengan tarif menaikkan harga barang bagi konsumen.
- Membangun infrastruktur tidak langsung menghasilkan, tetapi meningkatkan produktivitas jangka panjang.

### 1.3 Pernyataan desain

> “Setiap negara adalah sebuah sistem ekonomi yang saling bergantung. Pemain harus memenuhi kebutuhan hari ini tanpa mengorbankan kemampuan negara untuk tumbuh di masa depan.”

### 1.4 Pilar desain

1. **Realistis namun dapat dipahami** — memakai konsep ekonomi nyata, tetapi disederhanakan agar tetap menyenangkan.
2. **Keputusan bermakna** — tidak ada pilihan yang sepenuhnya benar; semua kebijakan memiliki konsekuensi.
3. **Interdependensi global** — negara tidak berdiri sendiri; krisis, harga komoditas, dan rantai pasok dunia memengaruhi semua pemain.
4. **Belajar melalui masalah** — pemain memahami inflasi, utang, atau kelangkaan lewat konsekuensi langsung, bukan teks teori panjang.
5. **Progresi jangka panjang** — kebijakan infrastruktur, pendidikan, dan teknologi memberi hasil bertahap, bukan instan.
6. **Replayability** — negara, sumber daya, kondisi awal, dan kejadian dunia yang berbeda menciptakan pengalaman baru.

---

## 2. KONSEP INTI GAMEPLAY

### 2.1 Peran pemain

Pemain adalah **economic decision-maker** negara, bukan presiden atau diktator. Pemain mengendalikan kebijakan ekonomi dan alokasi sumber daya, tetapi harus mempertimbangkan:

- Reaksi pasar.
- Opini publik.
- Kapasitas fiskal negara.
- Tekanan politik.
- Hubungan diplomatik.
- Guncangan eksternal.

### 2.2 Struktur waktu

- **1 giliran = 1 kuartal (3 bulan)** untuk mode standar.
- Alternatif mode cepat: **1 giliran = 1 tahun**.
- Kampanye dasar berlangsung **10 tahun = 40 giliran**.
- Mode sandbox dapat berlangsung tanpa batas waktu.

Setiap giliran terdiri atas:

1. Menerima laporan ekonomi.
2. Menganalisis kebutuhan dan risiko.
3. Menetapkan kebijakan.
4. Menegosiasikan perdagangan atau investasi.
5. Memproses simulasi ekonomi.
6. Menerima hasil, kejadian, dan umpan balik.

### 2.3 Tujuan pemain

Tujuan utama bukan sekadar “menjadi kaya”, melainkan mencapai **prosperity score** atau **Indeks Kemakmuran Berkelanjutan**.

Indeks ini dihitung dari:

- Pertumbuhan GDP riil.
- Inflasi yang rendah dan stabil.
- Pengangguran yang rendah.
- Rasio utang terhadap GDP yang terkendali.
- Cadangan devisa yang memadai.
- Akses pangan dan energi.
- Kualitas infrastruktur.
- Tingkat pendidikan dan inovasi.
- Ketimpangan pendapatan.
- Stabilitas sosial-politik.
- Keberlanjutan lingkungan.

Pemain gagal atau memasuki **krisis nasional** jika mengalami:

- Hiperinflasi.
- Default utang.
- Kelangkaan pangan atau energi parah.
- Keruntuhan nilai tukar.
- Kerusuhan sosial besar.
- Kehilangan kepercayaan pasar.

---

## 3. SISTEM EKONOMI

### 3.1 Model ekonomi dasar

Simulasi menggunakan pendekatan makroekonomi sederhana:

\[
GDP = C + I + G + (X - M)
\]

Keterangan:

- \(C\) = konsumsi rumah tangga.
- \(I\) = investasi swasta.
- \(G\) = belanja pemerintah.
- \(X\) = ekspor.
- \(M\) = impor.

### 3.2 Konsumsi rumah tangga

Konsumsi dipengaruhi oleh:

- Pendapatan riil.
- Pengangguran.
- Inflasi.
- Suku bunga.
- Kepercayaan konsumen.
- Harga pangan dan energi.
- Kebijakan pajak.

Jika harga pangan dan energi naik tajam, daya beli riil turun. Jika pengangguran naik, konsumsi agregat melemah.

### 3.3 Investasi

Investasi swasta dipengaruhi oleh:

- Suku bunga.
- Stabilitas politik.
- Kualitas infrastruktur.
- Peraturan bisnis.
- Ketersediaan tenaga kerja terampil.
- Akses energi.
- Harga modal dan bahan baku.
- Ekspektasi pertumbuhan.

Investasi meningkatkan kapasitas produksi jangka panjang, tetapi sering membutuhkan waktu beberapa giliran sebelum memberi hasil.

### 3.4 Belanja pemerintah

Pemain mengalokasikan anggaran ke sektor:

- Pendidikan.
- Kesehatan.
- Infrastruktur.
- Pertanian.
- Energi.
- Riset dan teknologi.
- Pertahanan.
- Kesejahteraan sosial.
- Administrasi negara.
- Pembayaran bunga utang.
- Cadangan darurat.

Belanja pemerintah meningkatkan permintaan agregat, tetapi jika melebihi kapasitas fiskal akan menaikkan defisit dan utang.

### 3.5 Perdagangan internasional

Setiap negara memiliki:

- Produksi domestik.
- Kebutuhan domestik.
- Stok komoditas.
- Kapasitas pelabuhan dan logistik.
- Tarif impor/ekspor.
- Perjanjian dagang.
- Hubungan diplomatik.
- Ketergantungan pada mitra tertentu.

Jika produksi domestik tidak mencukupi kebutuhan, negara harus mengimpor. Jika produksi melimpah, negara dapat mengekspor dan memperoleh devisa.

### 3.6 Inflasi

Inflasi dipengaruhi oleh:

- Permintaan agregat yang terlalu tinggi.
- Kenaikan harga energi dan pangan impor.
- Depresiasi mata uang.
- Kenaikan upah.
- Gangguan rantai pasok.
- Ekspektasi inflasi.
- Pencetakan uang atau defisit yang dibiayai moneter.

Inflasi tinggi menurunkan daya beli, meningkatkan ketidakpuasan publik, dan memaksa bank sentral menaikkan suku bunga.

### 3.7 Pengangguran

Pengangguran dipengaruhi oleh:

- Pertumbuhan ekonomi.
- Investasi.
- Otomatisasi dan teknologi.
- Struktur industri.
- Keterampilan tenaga kerja.
- Kebijakan upah minimum.
- Kondisi sektor ekspor.

Pengangguran tinggi menurunkan konsumsi, menaikkan belanja sosial, dan menurunkan stabilitas politik.

### 3.8 Nilai tukar dan devisa

Nilai tukar dipengaruhi oleh:

- Neraca perdagangan.
- Arus modal masuk/keluar.
- Suku bunga domestik dibanding negara lain.
- Inflasi relatif.
- Cadangan devisa.
- Peringkat kredit.
- Kepercayaan investor.

Depresiasi mata uang:

- Membuat ekspor lebih kompetitif.
- Membuat impor lebih mahal.
- Meningkatkan inflasi impor.
- Memperberat utang berdenominasi valuta asing.

### 3.9 Utang publik

Utang memiliki:

- Jangka waktu.
- Mata uang.
- Suku bunga.
- Jadwal jatuh tempo.
- Peringkat kredit.

Utang tidak selalu buruk. Utang untuk infrastruktur produktif dapat meningkatkan kapasitas ekonomi. Namun utang berlebihan untuk konsumsi atau subsidi dapat memicu krisis fiskal.

### 3.10 Kepercayaan publik

Kepercayaan publik dipengaruhi oleh:

- Harga pangan dan energi.
- Pengangguran.
- Kualitas layanan publik.
- Ketimpangan.
- Korupsi.
- Keberhasilan krisis.
- Keputusan yang dianggap tidak adil.

Kepercayaan rendah dapat menyebabkan protes, mogok kerja, penurunan investasi, dan kehilangan legitimasi politik.

---

## 4. KEBIJAKAN YANG DAPAT DIKENDALIKAN PEMAIN

### 4.1 Kebijakan fiskal

| Kebijakan | Efek positif | Risiko |
|---|---|---|
| Menurunkan pajak | Konsumsi dan investasi naik | Defisit membesar |
| Menaikkan pajak | Pendapatan negara naik | Konsumsi dan investasi turun |
| Menambah belanja infrastruktur | Produktivitas dan lapangan kerja naik | Defisit dan utang naik |
| Subsidi pangan/energi | Stabilitas sosial naik | Beban fiskal tinggi |
| Bantuan sosial | Ketimpangan turun, konsumsi naik | Biaya anggaran besar |
| Investasi pendidikan | Human capital dan produktivitas naik | Hasil baru terasa jangka panjang |
| Investasi R&D | Teknologi dan daya saing naik | Tidak selalu berhasil |
| Pemotongan anggaran | Defisit turun | Layanan publik dan pertumbuhan melemah |

### 4.2 Kebijakan moneter

Pemain dapat mengatur suku bunga acuan melalui bank sentral.

| Suku bunga | Efek |
|---|---|
| Naik | Inflasi turun, nilai tukar cenderung menguat, investasi dan konsumsi turun |
| Turun | Investasi dan konsumsi naik, tetapi inflasi dan depresiasi mata uang berisiko naik |

### 4.3 Kebijakan perdagangan

| Kebijakan | Efek |
|---|---|
| Tarif impor | Melindungi industri lokal, tetapi harga konsumen naik |
| Subsidi ekspor | Ekspor naik, tetapi dapat memicu balasan dagang |
| Perjanjian dagang | Akses pasar lebih baik, tetapi industri tertentu bisa terdesak |
| Pembatasan ekspor bahan mentah | Mendorong industri olahan domestik, tetapi dapat mengurangi devisa |
| Kontrol devisa | Menstabilkan mata uang, tetapi menurunkan kepercayaan investor |

### 4.4 Kebijakan struktural

- Membangun jalan, pelabuhan, bandara, dan rel.
- Membangun pembangkit listrik dan jaringan energi.
- Membangun irigasi dan sistem pangan.
- Membangun universitas, sekolah vokasi, dan pusat riset.
- Memberi insentif industri strategis.
- Mereformasi birokrasi dan mengurangi korupsi.
- Mengembangkan kota industri dan kawasan ekonomi khusus.

---

## 5. SUMBER DAYA DAN KOMODITAS

### 5.1 Kategori sumber daya

Game memakai empat kategori utama:

1. **Energi** — minyak, gas alam, batu bara, listrik, energi terbarukan.
2. **Pangan** — beras, gandum, jagung, kedelai, daging, ikan, pupuk.
3. **Material industri** — besi/baja, tembaga, aluminium, nikel, litium, semen, kayu.
4. **Teknologi dan barang modal** — semikonduktor, mesin industri, perangkat lunak, obat, kendaraan.

### 5.2 Contoh komoditas MVP

| Komoditas | Fungsi utama |
|---|---|
| Minyak | Transportasi, industri, pembangkit listrik |
| Gas alam | Listrik, industri, pemanas |
| Batu bara | Listrik dan industri |
| Listrik | Semua sektor produksi |
| Beras | Pangan pokok di Asia |
| Gandum | Pangan pokok global |
| Jagung | Pangan, pakan ternak, industri |
| Pupuk | Produksi pertanian |
| Besi/baja | Konstruksi, infrastruktur, manufaktur |
| Tembaga | Listrik, elektronik, konstruksi |
| Nikel | Baterai dan industri logam |
| Litium | Baterai dan energi terbarukan |
| Semen | Infrastruktur dan konstruksi |
| Kayu | Konstruksi dan industri |
| Semikonduktor | Elektronik, otomotif, industri modern |
| Mesin industri | Kapasitas produksi |
| Obat | Kesehatan publik |

### 5.3 Stok, produksi, dan konsumsi

Setiap negara memiliki data:

- **Produksi domestik per kuartal.**
- **Konsumsi domestik per kuartal.**
- **Kapasitas produksi maksimum.**
- **Stok strategis.**
- **Biaya produksi.**
- **Kualitas/tingkat teknologi produksi.**
- **Ketergantungan impor.**
- **Kapasitas ekspor.**

Jika:

\[
Produksi + Impor + Stok < Kebutuhan
\]

maka terjadi **kelangkaan**. Kelangkaan menyebabkan:

- Harga domestik naik.
- Produksi industri terganggu.
- Ketidakpuasan publik meningkat.
- Pemerintah dipaksa mengimpor darurat dengan harga mahal.

### 5.4 Rantai pasok sederhana

Contoh rantai baterai listrik:

1. Nikel dan litium ditambang.
2. Nikel/litium diolah menjadi bahan baterai.
3. Bahan baterai diproduksi menjadi sel baterai.
4. Sel baterai dipakai pabrik kendaraan listrik.
5. Kendaraan listrik diekspor atau dipakai domestik.

Pemain dapat memilih strategi:

- Ekspor nikel mentah untuk devisa cepat.
- Membangun smelter dan pabrik baterai untuk nilai tambah.
- Mengimpor teknologi dan tenaga ahli.
- Melindungi industri domestik dengan insentif.

---

## 6. NEGARA, KESULITAN, DAN PROFIL EKONOMI

### 6.1 Prinsip kesulitan

Kesulitan tidak hanya ditentukan oleh kemiskinan atau kekayaan negara. Setiap negara harus memiliki **profil tantangan** yang berbeda.

| Tipe negara | Kekuatan awal | Tantangan utama | Tingkat kesulitan |
|---|---|---|---|
| Negara maju | Modal besar, teknologi, institusi kuat | Pertumbuhan lambat, populasi menua, utang, transisi energi | Menengah |
| Negara berkembang | Pertumbuhan tinggi, tenaga kerja besar | Infrastruktur, ketimpangan, ketergantungan impor, kualitas institusi | Menengah-sulit |
| Negara berpendapatan rendah | Sumber daya alam, ruang pertumbuhan | Pangan, energi, modal, utang, lemahnya institusi | Sulit |
| Negara ekspor komoditas | Devisa dari ekspor | Rentan harga komoditas, Dutch disease, industrialisasi | Menengah-sulit |
| Negara industri | Produksi dan teknologi tinggi | Ketergantungan energi dan bahan baku impor | Menengah |
| Negara pulau/kecil | Fleksibilitas kebijakan | Pasar kecil, logistik mahal, ketergantungan impor | Sulit |

### 6.2 Contoh negara MVP

| Negara | Profil | Sumber daya/keunggulan | Tantangan |
|---|---|---|---|
| Indonesia | Negara berkembang, ekspor komoditas | Nikel, batu bara, minyak, gas, kelapa sawit, populasi besar | Impor pangan tertentu, teknologi, infrastruktur |
| Jepang | Negara maju, industri | Teknologi, manufaktur, modal, produktivitas | Energi dan pangan impor, populasi menua |
| Jerman | Negara maju, industri | Mesin, otomotif, kimia, teknologi | Ketergantungan energi impor |
| Amerika Serikat | Negara maju besar | Energi, pertanian, teknologi, modal | Ketimpangan, utang, biaya produksi |
| Brasil | Negara berkembang | Besi, minyak, pangan, air, lahan pertanian | Logistik, ketimpangan, fluktuasi komoditas |
| Chile | Negara berkembang, ekspor mineral | Tembaga, litium | Ketergantungan komoditas dan air |
| Nigeria | Negara berkembang, ekspor minyak | Minyak, gas, populasi muda | Diversifikasi, listrik, infrastruktur |
| India | Negara berkembang besar | Tenaga kerja, layanan digital, pertanian | Infrastruktur, energi, ketimpangan |
| Vietnam | Negara berkembang manufaktur | Tenaga kerja, ekspor manufaktur | Ketergantungan impor bahan baku dan teknologi |
| Afrika Selatan | Negara berkembang mineral | Mineral, industri relatif maju | Pengangguran, energi, ketimpangan |

### 6.3 Data negara yang perlu dimodelkan

Untuk setiap negara, tim developer perlu menyiapkan:

- Populasi dan pertumbuhan penduduk.
- GDP dan struktur sektor.
- Inflasi awal.
- Pengangguran awal.
- Utang publik dan utang luar negeri.
- Cadangan devisa.
- Nilai tukar awal.
- Tarif dasar.
- Konsumsi energi.
- Produksi dan konsumsi pangan.
- Komoditas ekspor dan impor.
- Kualitas infrastruktur.
- Tingkat pendidikan.
- Indeks korupsi atau kualitas institusi.
- Kerentanan bencana dan iklim.
- Hubungan dagang awal.

### 6.4 Sumber data yang disarankan

- **World Bank** — GDP, inflasi, utang, klasifikasi pendapatan, indikator pembangunan.
- **IMF** — data makroekonomi dan stabilitas keuangan.
- **USGS Mineral Commodity Summaries** — produksi mineral global.
- **FAO** — pangan, pertanian, dan ketahanan pangan.
- **IEA** — energi dan transisi energi.
- **UN Comtrade** — perdagangan antarnegara.
- **ILO** — tenaga kerja dan pengangguran.
- **OECD** — data negara maju dan kebijakan publik.

---

## 7. SISTEM DUNIA DAN INTERDEPENDENSI

### 7.1 Pasar dunia

Setiap komoditas memiliki harga global yang bergerak berdasarkan:

- Total produksi global.
- Total permintaan global.
- Stok global.
- Kejadian geopolitik.
- Bencana alam.
- Sanksi ekonomi.
- Perubahan teknologi.
- Spekulasi pasar.

### 7.2 Hubungan antarnegara

Negara dapat memiliki hubungan:

- Mitra dagang.
- Sekutu ekonomi.
- Kompetitor.
- Pemasok kritis.
- Negara penerima utang/bantuan.
- Negara sanksi atau disanksi.

### 7.3 Kejadian global

Contoh kejadian:

- Kenaikan harga minyak global.
- Kekeringan besar di negara produsen gandum.
- Gangguan rantai pasok semikonduktor.
- Resesi di negara maju.
- Kenaikan suku bunga global.
- Sanksi terhadap negara eksportir energi.
- Pandemi.
- Bencana alam.
- Inovasi teknologi energi.
- Perang dagang.

### 7.4 Efek domino

Contoh:

1. Negara A mengalami kekeringan.
2. Produksi gandum dunia turun.
3. Harga gandum global naik.
4. Negara importir mengalami inflasi pangan.
5. Pemerintah menaikkan subsidi pangan.
6. Defisit anggaran naik.
7. Nilai tukar melemah.
8. Impor energi dan obat menjadi lebih mahal.

Efek domino inilah yang membuat dunia terasa hidup dan saling bergantung.

---

## 8. ANTARMUKA PEMAIN

### 8.1 Layar utama: Dashboard Negara

Dashboard harus menampilkan informasi penting tanpa membingungkan pemain:

- GDP dan pertumbuhan.
- Inflasi.
- Pengangguran.
- Nilai tukar.
- Cadangan devisa.
- Utang publik.
- Defisit/surplus anggaran.
- Indeks kepercayaan publik.
- Status pangan dan energi.
- Peringkat kredit.
- Peringatan krisis.

### 8.2 Panel kebijakan

Pemain membuka panel untuk mengatur:

- Pajak.
- Belanja negara.
- Subsidi.
- Suku bunga.
- Tarif.
- Investasi.
- Perdagangan.
- Kebijakan energi.
- Kebijakan pangan.
- Kebijakan sosial.

### 8.3 Peta ekonomi dunia

Peta dunia menampilkan:

- Negara pemain.
- Negara mitra dagang.
- Jalur ekspor/impor.
- Harga komoditas global.
- Zona krisis.
- Negara dengan surplus atau defisit komoditas.

### 8.4 Layar pasar komoditas

Menampilkan:

- Harga global.
- Harga domestik.
- Produksi domestik.
- Konsumsi domestik.
- Stok.
- Impor.
- Ekspor.
- Negara pemasok utama.
- Tren harga.

### 8.5 Layar anggaran

Menampilkan:

- Total pendapatan negara.
- Total belanja.
- Defisit atau surplus.
- Alokasi per sektor.
- Utang dan bunga.
- Proyeksi fiskal beberapa giliran ke depan.

### 8.6 Layar laporan ekonomi

Setiap giliran, pemain menerima ringkasan seperti:

- “Inflasi naik karena harga energi impor meningkat.”
- “Investasi menurun akibat suku bunga tinggi.”
- “Ekspor nikel meningkat, tetapi nilai tambah domestik rendah.”
- “Cadangan devisa turun ke level berisiko.”
- “Harga pangan domestik naik; kepercayaan publik menurun.”

---

## 9. SISTEM KEJADIAN

### 9.1 Jenis kejadian

1. **Kejadian ekonomi** — resesi, inflasi, krisis utang, boom komoditas.
2. **Kejadian politik** — pemilu, protes, perubahan koalisi, tekanan parlemen.
3. **Kejadian sosial** — mogok kerja, demonstrasi, urbanisasi, ketimpangan.
4. **Kejadian lingkungan** — kekeringan, banjir, gempa, kebakaran hutan.
5. **Kejadian global** — perang dagang, pandemi, sanksi, krisis energi.
6. **Kejadian teknologi** — otomatisasi, energi murah, inovasi pertanian.

### 9.2 Contoh kejadian

**Krisis Energi Global**  
Harga minyak dan gas naik 40%. Negara importir energi mengalami inflasi dan tekanan nilai tukar. Pemain harus memilih: subsidi energi, menaikkan tarif, mempercepat energi terbarukan, atau membiarkan harga naik.

**Gagal Panen**  
Produksi pangan domestik turun 20%. Harga pangan naik. Pemain dapat mengimpor, membuka cadangan pangan, memberi subsidi, atau mengekspor komoditas lain untuk mendanai impor.

**Boom Nikel**  
Harga nikel global naik tajam. Negara eksportir memperoleh devisa besar. Pemain memilih: mengekspor lebih banyak bahan mentah, membangun smelter, atau membatasi ekspor untuk mendorong industri domestik.

**Krisis Utang**  
Nilai tukar turun dan utang luar negeri menjadi mahal. Pemain harus memilih restrukturisasi utang, pemotongan anggaran, kenaikan pajak, atau bantuan internasional.

### 9.3 Prinsip kejadian

- Kejadian harus memiliki penyebab yang terlihat.
- Pemain harus diberi beberapa pilihan respons.
- Setiap pilihan harus memiliki konsekuensi jangka pendek dan panjang.
- Kejadian tidak boleh terasa murni acak dan tidak adil.

---

## 10. SISTEM PROGRESI DAN KEMENANGAN

### 10.1 Indeks Kemakmuran Berkelanjutan

Skor akhir dihitung dari bobot:

| Komponen | Bobot indikatif |
|---|---|
| Pertumbuhan GDP riil | 20% |
| Stabilitas inflasi | 15% |
| Pengangguran | 15% |
| Keberlanjutan fiskal | 15% |
| Ketahanan pangan dan energi | 10% |
| Infrastruktur dan produktivitas | 10% |
| Kesejahteraan dan ketimpangan | 10% |
| Stabilitas sosial-politik | 5% |

### 10.2 Peringkat akhir

- **S** — Ekonomi kuat, stabil, inklusif, dan berkelanjutan.
- **A** — Pertumbuhan baik dengan risiko terkendali.
- **B** — Ekonomi stabil tetapi belum optimal.
- **C** — Pertumbuhan ada, tetapi ketimpangan, utang, atau inflasi bermasalah.
- **D** — Krisis fiskal atau sosial mulai terjadi.
- **F** — Default, hiperinflasi, atau keruntuhan stabilitas.

### 10.3 Mode permainan

1. **Campaign Negara** — pilih satu negara dan kelola ekonominya selama 10–20 tahun.
2. **Scenario Challenge** — misi tertentu, misalnya mengatasi krisis energi atau keluar dari ketergantungan impor pangan.
3. **Sandbox Global** — atur semua parameter, pilih negara, dan mainkan tanpa batas.
4. **Multiplayer Asynchronous** — beberapa pemain mengelola negara berbeda dalam dunia yang sama.
5. **Mode CEO** — pemain mengelola perusahaan multinasional di dalam ekonomi yang dikendalikan AI atau pemain lain.

---

## 11. SISTEM KECERDASAN BUATAN NEGARA LAIN

Negara non-pemain harus berperilaku rasional, bukan sekadar latar belakang.

AI negara harus:

- Mengimpor barang yang tidak cukup diproduksi domestik.
- Mengekspor surplus komoditas.
- Menyesuaikan tarif terhadap tekanan politik.
- Menyimpan cadangan devisa.
- Bereaksi terhadap harga global.
- Menegosiasikan perjanjian dagang.
- Mengalami krisis jika kelola ekonominya buruk.
- Dapat menjadi mitra atau pesaing pemain.

AI tidak perlu terlalu kompleks di MVP. Cukup gunakan aturan berbasis prioritas:

1. Jaga pangan dan energi.
2. Jaga cadangan devisa.
3. Kurangi kelangkaan.
4. Maksimalkan ekspor surplus.
5. Kelola utang dan inflasi.
6. Respons terhadap kejadian global.

---

## 12. SISTEM BALANCING

### 12.1 Prinsip balancing

- Tidak ada strategi tunggal yang selalu menang.
- Kebijakan populer jangka pendek harus memiliki biaya jangka panjang.
- Ekspor komoditas harus menguntungkan tetapi berisiko.
- Industrialisasi harus mahal dan lambat, tetapi memberi nilai tambah lebih besar.
- Subsidi harus efektif tetapi tidak boleh menjadi solusi permanen tanpa biaya.
- Krisis harus dapat diatasi, tetapi tidak boleh terlalu mudah.

### 12.2 Parameter yang perlu di-tuning

- Elastisitas permintaan terhadap harga.
- Dampak suku bunga terhadap investasi.
- Kecepatan efek infrastruktur.
- Sensitivitas inflasi terhadap nilai tukar.
- Dampak tarif terhadap harga domestik.
- Biaya dan hasil R&D.
- Laju pertumbuhan penduduk dan tenaga kerja.
- Frekuensi dan keparahan kejadian.
- Harga komoditas global.

### 12.3 Tools balancing

Tim developer disarankan membuat:

- Spreadsheet model ekonomi.
- Simulasi headless tanpa UI.
- Data-driven configuration untuk negara dan komoditas.
- Replay/log keputusan pemain.
- Dashboard debug untuk melihat semua variabel ekonomi.

---

## 13. UI/UX DAN PEMBELAJARAN

### 13.1 Prinsip pembelajaran

Pemain tidak perlu tahu istilah ekonomi di awal. Game harus menjelaskan lewat konsekuensi.

Contoh:

- Pemain menaikkan suku bunga → inflasi turun → investasi turun → pengangguran naik.
- Pemain memberi subsidi bahan bakar → harga energi stabil → defisit naik → utang naik.
- Pemain mengekspor nikel mentah → devisa naik → industri lokal kekurangan bahan baku.
- Pemain membangun pelabuhan → biaya logistik turun → ekspor meningkat.

### 13.2 Sistem tips kontekstual

Saat pemain menghadapi masalah, tampilkan penjelasan singkat:

- “Inflasi meningkat karena harga energi impor naik.”
- “Cadangan devisa menipis karena impor melebihi ekspor.”
- “Pengangguran naik karena sektor manufaktur melemah.”
- “Utang berisiko karena bunga utang luar negeri meningkat.”

### 13.3 Encyclopedia ekonomi

Sediakan ensiklopedia dalam game yang menjelaskan:

- GDP.
- Inflasi.
- Pengangguran.
- Kebijakan moneter.
- Kebijakan fiskal.
- Nilai tukar.
- Neraca perdagangan.
- Comparative advantage.
- Supply chain.
- Utang publik.
- Subsidi.
- Tarif.
- Productivity.
- Human capital.

Penjelasan harus singkat, memakai contoh dari keputusan pemain sendiri.

---

## 14. ARSITEKTUR TEKNIS

### 14.1 Arsitektur data-driven

Semua negara, komoditas, kebijakan, dan kejadian harus disimpan sebagai data, bukan hard-coded.

Struktur data minimal:

```json
{
  "country": {
    "id": "indonesia",
    "name": "Indonesia",
    "population": 280000000,
    "gdp": 1400000000000,
    "inflation": 0.032,
    "unemployment": 0.053,
    "debt_to_gdp": 0.39,
    "fx_reserves": 140000000000,
    "income_group": "upper_middle_income",
    "resources": ["nickel", "coal", "oil", "gas", "palm_oil"],
    "import_needs": ["wheat", "machinery", "semiconductors"]
  }
}
```

```json
{
  "commodity": {
    "id": "nickel",
    "category": "industrial_material",
    "base_global_price": 18000,
    "unit": "USD_per_ton",
    "strategic_importance": 0.8,
    "used_by": ["battery_material", "stainless_steel"],
    "producers": ["indonesia", "philippines", "russia"]
  }
}
```

### 14.2 Modul simulasi

| Modul | Tanggung jawab |
|---|---|
| Country Model | Populasi, GDP, tenaga kerja, kapasitas produksi |
| Fiscal Model | Pajak, belanja, defisit, utang |
| Monetary Model | Suku bunga, inflasi, nilai tukar |
| Trade Model | Ekspor, impor, tarif, harga global |
| Resource Model | Produksi, konsumsi, stok, kelangkaan |
| Industry Model | Pabrik, teknologi, rantai pasok |
| Event Engine | Kejadian global, nasional, dan acak |
| AI Country Engine | Perilaku negara non-pemain |
| UI Layer | Dashboard, peta, laporan, keputusan |
| Save System | Save/load, replay, log keputusan |

### 14.3 Rekomendasi teknologi

- **Unity (C#)** — cocok untuk game strategy dengan UI kompleks dan porting lintas platform.
- **Godot (GDScript/C#)** — open-source, ringan, cocok untuk tim kecil-menengah.
- **Unreal Engine** — kuat secara visual, tetapi kemungkinan terlalu berat untuk game berbasis data dan UI.
- **Backend opsional** — untuk multiplayer asynchronous dan leaderboard.

Untuk MVP, Unity atau Godot adalah pilihan paling realistis.

### 14.4 Penyimpanan data

Gunakan format:

- JSON untuk konfigurasi game.
- CSV untuk data ekonomi historis dan balancing.
- SQLite atau file save lokal untuk progres pemain.
- Server database hanya jika multiplayer atau leaderboard diaktifkan.

---

## 15. ROADMAP PENGEMBANGAN

### Fase 0: Prototype ekonomi

Durasi: 4–8 minggu.

Tujuan: membuktikan model ekonomi berjalan dan menyenangkan.

Fitur:

- 1 negara fiktif atau 1 negara nyata.
- 5 komoditas.
- Pajak, belanja negara, suku bunga, impor, ekspor.
- GDP, inflasi, pengangguran, utang.
- 10 giliran.
- UI dashboard sederhana.

### Fase 1: Vertical slice

Durasi: 2–3 bulan.

Fitur:

- 3 negara nyata.
- 10 komoditas.
- Pasar dunia sederhana.
- Perdagangan antarnegara.
- 10–15 kejadian.
- Peta dunia dasar.
- Sistem tutorial.
- Save/load.

### Fase 2: Alpha

Durasi: 3–5 bulan.

Fitur:

- 8–12 negara.
- 15–20 komoditas.
- Rantai pasok dasar.
- AI negara non-pemain.
- Sistem krisis.
- Indeks kemakmuran.
- Scenario mode.
- Balancing awal.

### Fase 3: Beta

Durasi: 3–4 bulan.

Fitur:

- Polishing UI/UX.
- Tutorial lengkap.
- Encyclopedia ekonomi.
- Lokalisasi.
- Optimasi performa.
- Playtest eksternal.
- Perbaikan balancing.

### Fase 4: Rilis MVP

Fitur minimum rilis:

- Minimal 8 negara nyata.
- Minimal 15 komoditas.
- Kampanye 10 tahun.
- Sistem perdagangan global.
- Sistem krisis dan kejadian.
- Tutorial interaktif.
- Save/load.
- Data ekonomi realistis.
- Mode sandbox.

---

## 16. RISIKO PENGEMBANGAN

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Simulasi terlalu rumit | Pemain bingung | Mulai dari model sederhana, tambahkan kompleksitas bertahap |
| Data tidak akurat | Game terasa tidak kredibel | Gunakan sumber World Bank, IMF, USGS, FAO, IEA |
| Balancing buruk | Ada strategi paling dominan | Buat simulation headless dan uji ribuan jalur keputusan |
| UI terlalu padat | Pemain kewalahan | Gunakan dashboard bertingkat dan visualisasi sederhana |
| Kejadian terasa acak | Pemain frustrasi | Pastikan kejadian memiliki penyebab dan peringatan dini |
| Scope creep | Pengembangan lambat | Fokus pada MVP: 8 negara, 15 komoditas, 1 siklus 10 tahun |
| Sensitivitas politik | Kontroversi | Gunakan data netral, hindari propaganda, beri konteks edukatif |

---

## 17. DEFINISI SUCCESS METRICS

Game dianggap berhasil jika:

- Pemain dapat menyelesaikan satu kampanye 10 tahun tanpa kebingungan besar.
- Pemain memahami minimal lima konsep ekonomi setelah bermain.
- Terdapat lebih dari satu strategi yang dapat membawa pemain menuju skor tinggi.
- Keputusan ekonomi terasa memiliki konsekuensi nyata.
- Pemain ingin mencoba negara atau strategi berbeda setelah kampanye pertama.
- Rata-rata sesi playtest menghasilkan umpan balik bahwa game “menantang tetapi bisa dipahami”.

---

## 18. KESIMPULAN UNTUK TIM DEVELOPER

Bangun game ini sebagai **simulator sistem ekonomi**, bukan sekadar game angka-angka. Inti pengalaman adalah membuat pemain memahami bahwa pemerintahan ekonomi adalah seni mengelola keterbatasan.

Tim developer harus memprioritaskan:

1. Model ekonomi yang konsisten.
2. Sistem sumber daya dan kelangkaan.
3. Perdagangan antarnegara.
4. Dampak kebijakan fiskal dan moneter.
5. Kejadian dunia yang saling terhubung.
6. UI yang membuat data ekonomi mudah dipahami.
7. Balancing yang membuat semua strategi memiliki risiko.

Jika inti sistem ini kuat, game dapat dikembangkan menjadi game edukasi, game strategi komersial, atau platform pembelajaran ekonomi untuk sekolah dan universitas.
