SOVEREIGN
THE RESOURCE ECONOMY
SPESIFIKASI UI ANDROID
Versi 1.0 · 14 Oktober 2026

Dokumen implementasi UI/UX untuk menerjemahkan konsep visual SOVEREIGN menjadi spesifikasi layar, komponen, navigasi, dan alur interaksi Android.


1. Tujuan dan prinsip desain
Dokumen ini menerjemahkan konsep visual SOVEREIGN menjadi pedoman implementasi yang dapat digunakan oleh UI/UX designer dan developer. Tujuan utamanya adalah membantu pemain memahami kondisi negara, menemukan masalah, memilih kebijakan, dan mengevaluasi dampak tanpa harus membuka terlalu banyak layar.
Informasi penting ditampilkan lebih dahulu; detail tersedia melalui drill-down.
Keputusan kebijakan memperlihatkan nilai saat ini, nilai usulan, dan estimasi dampak.
Warna status selalu disertai label atau ikon; jangan mengandalkan warna saja.
Spesifikasi ukuran adalah rekomendasi desain, bukan batasan yang sudah ditetapkan blueprint.
2. Fondasi desain
Aspek
Spesifikasi awal

Platform
Android; portrait sebagai orientasi default. Landscape didukung untuk peta dan analisis lebar.

Frame baseline
360 × 800 dp sebagai baseline desain; layout harus responsif.

Target sentuh
Minimal 48 × 48 dp untuk kontrol interaktif.

Margin horizontal
16 dp pada layar standar.

Navigasi utama
5 item: Beranda, Ekonomi, Sumber Daya, Diplomasi, Menu.

Satuan desain
dp untuk dimensi; sp untuk teks agar mendukung preferensi aksesibilitas Android.


2.1 Palet warna
Token
Hex
Penggunaan

Deep Navy
#071827
Latar utama dan area peta.

Blue Slate
#102C43
Kartu indikator, panel, dan permukaan sekunder.

Positive Green
#22C55E
Perbaikan dan aksi utama.

Warning Amber
#FBBF24
Risiko dan perhatian.

Critical Red
#F87171
Krisis dan kondisi memburuk.

Accent Cyan
#36C5F0
Aksen, fokus, dan elemen navigasi.


Warna bukan satu-satunya penanda. Sertakan teks status, ikon, dan/atau pola yang jelas untuk aksesibilitas.
2.2 Tipografi dan hierarki informasi
Tingkat
Konten
Ukuran rekomendasi

1 — Angka utama
GDP, inflasi, status krisis, saldo anggaran.
22–28 sp, semibold/bold

2 — Judul komponen
Nama indikator, komoditas, dan kejadian.
16–18 sp, medium/semibold

3 — Data pendukung
Perubahan, satuan, periode, dan status.
13–15 sp, regular/medium

4 — Keterangan
Tooltip, sumber data, dan penjelasan singkat.
12–13 sp, regular


3. Navigasi aplikasi
Menu utama
Subhalaman

Beranda
Peta dunia, indikator utama, notifikasi, laporan.

Ekonomi
Ringkasan, konsumsi, investasi, fiskal, moneter, grafik.

Sumber Daya
Komoditas, produksi, stok, industri, rantai pasok.

Diplomasi
Profil negara, mitra dagang, perjanjian, negosiasi.

Menu
Kebijakan, anggaran, kejadian, pencapaian, pengaturan, simpan/muat.


Bar navigasi bawah direkomendasikan setinggi 64–72 dp, di luar area system navigation. Ikon harus disertai label. Halaman detail menggunakan tombol kembali di kiri atas. Sediakan pintasan kebijakan dari dashboard saat ada masalah yang membutuhkan respons.
4. Spesifikasi layar
4.1 Beranda dan dashboard negara
Tujuan: pemain memahami kondisi negara dalam 5–10 detik.
Komponen
Ukuran/aturan

Header negara dan kuartal
56–64 dp

Kartu KPI GDP, inflasi, pengangguran
3 kolom; tinggi 76–88 dp

Peta dunia
Rasio sekitar 16:9; tinggi 170–210 dp

Kartu indikator tambahan
Grid 2 kolom; tinggi 68–84 dp

Peringatan krisis
Kartu penuh lebar, tampil saat relevan

Navigasi bawah
64–72 dp


Interaksi dan aturan
Ketuk kartu inflasi untuk membuka detail ekonomi.
Ketuk peta untuk membuka peta interaktif.
Ketuk peringatan untuk melihat penyebab dan opsi respons.
Dashboard menampilkan indikator inti dan masalah paling relevan, bukan semua statistik sekaligus.
4.2 Dashboard ekonomi
Tujuan: menjelaskan mengapa ekonomi berubah, bukan sekadar menampilkan angka.
Komponen
Ukuran/aturan

Header
56 dp

Tab kategori
40–48 dp; dapat digeser horizontal

Baris indikator
64–80 dp

Grafik tren
Tinggi 180–240 dp

Penjelasan penyebab
Kartu 72–120 dp atau sesuai isi


Interaksi dan aturan
Tab: Ringkasan, Konsumsi, Investasi, Perdagangan.
Setiap indikator menampilkan nilai sekarang, perubahan kuartal sebelumnya, tren, dan penjelasan singkat.
Ketuk indikator untuk analisis; ketuk titik grafik untuk nilai periode tertentu; ketuk penyebab untuk menelusuri hubungan sebab-akibat.
Grafik memiliki label sumbu, periode, dan satuan; jangan hanya mengandalkan warna garis.
4.3 Sumber daya dan industri
Tujuan: menunjukkan kecukupan sumber daya dan respons yang tersedia saat terjadi kekurangan.
Komponen
Ukuran/aturan

Tab kategori
40–48 dp

Kartu komoditas
Grid 2 kolom; tinggi 100–124 dp

Detail komoditas
Panel atau halaman terpisah

Bar kapasitas produksi
Tinggi 8–12 dp

Tombol Kelola Produksi
Tinggi 48–52 dp


Interaksi dan aturan
Tampilkan stok dan estimasi durasi, produksi dan konsumsi per kuartal, impor/ekspor, harga domestik/global, kapasitas produksi, serta industri pengguna.
Ketuk komoditas untuk detail; Kelola Produksi membuka pengaturan kapasitas, investasi, atau prioritas distribusi.
Minta konfirmasi jika tindakan memengaruhi kebutuhan domestik atau kontrak dagang.
4.4 Kebijakan
Tujuan: mengubah kebijakan tanpa kehilangan konteks ekonomi.
Komponen
Ukuran/aturan

Tab kebijakan
40–48 dp

Kartu kebijakan
Tinggi 72–96 dp

Kontrol nilai
Slider atau input numerik

Panel dampak
100–180 dp, sesuai indikator

Tombol Terapkan
52 dp; menempel di bawah saat mengedit


Interaksi dan aturan
Tab: Fiskal, Moneter, Perdagangan, Struktural.
Kartu menampilkan nama, nilai saat ini, status, dan konsekuensi utama.
Perubahan suku bunga memperlihatkan estimasi dampak pada inflasi, investasi, dan pengangguran.
Alur: buka kebijakan → ubah parameter → tinjau dampak → konfirmasi → antrekan untuk giliran berikutnya.
Bedakan nilai saat ini, nilai usulan, dan nilai setelah giliran diproses. Perubahan yang belum dikonfirmasi tidak memengaruhi simulasi.
4.5 Profil negara dan diplomasi
Tujuan: memeriksa kondisi negara lain dan membuat kesepakatan perdagangan.
Komponen
Ukuran/aturan

Header profil
100–140 dp

Tab Statistik/Sumber Daya/Hubungan
40–48 dp

Baris informasi
44–64 dp

Tombol aksi diplomatik
Minimum 48 dp


Interaksi dan aturan
Tampilkan bendera, populasi, GDP, GDP per kapita, profil ekonomi, keunggulan, kelemahan, komoditas, dan hubungan bilateral.
Alur: pilih negara → profil → periksa surplus/kebutuhan → negosiasi → atur komoditas, kuantitas, harga/ketentuan → tinjau → kirim.
Bedakan proposal, kesepakatan yang diterima, dan kontrak aktif.
4.6 Kejadian dan krisis
Tujuan: membantu pemain merespons kejadian ekonomi, sosial, lingkungan, atau global.
Komponen
Ukuran/aturan

Judul dan urgensi
Bagian atas layar

Penyebab dan kondisi pemicu
Kartu sesuai isi

Dampak terhadap negara
Kartu indikator

Pilihan respons
Daftar opsi yang dapat disentuh

Tombol aksi
Minimum 48 dp


Interaksi dan aturan
Tampilkan penyebab, dampak, biaya, manfaat, dan risiko setiap respons.
Alur: buka kejadian → bandingkan respons → pilih → lihat estimasi → konfirmasi → masukkan keputusan ke antrean simulasi.
Jika opsi tidak tersedia, jelaskan alasannya, misalnya cadangan devisa tidak cukup.
4.7 Konfirmasi keputusan
Tujuan: mencegah penerapan keputusan penting secara tidak sengaja.
Komponen
Ukuran/aturan

Ringkasan keputusan
Bagian atas

Nilai sekarang dan nilai baru
Kartu perbandingan

Estimasi dampak
Daftar indikator positif/negatif

Biaya langsung dan fiskal
Jika relevan

Konfirmasi/Batal
Tombol minimum 48 dp


Interaksi dan aturan
Gunakan panel bawah atau halaman penuh jika konsekuensi banyak; hindari dialog kecil untuk keputusan kompleks.
Konfirmasi mengunci pilihan untuk giliran berikutnya. Batal kembali ke pengeditan tanpa mengubah keputusan.
Konfirmasi tambahan hanya untuk keputusan berisiko tinggi.
4.8 Ringkasan akhir kuartal
Tujuan: menjelaskan perubahan setelah simulasi dan membantu menentukan langkah berikutnya.
Komponen
Ukuran/aturan

Baris indikator
44–56 dp

Kartu kejadian
Tinggi sesuai isi

Penjelasan penyebab
Kartu sesuai isi

Tombol Lanjutkan
52 dp


Interaksi dan aturan
Tampilkan GDP/pertumbuhan, inflasi, pengangguran, nilai tukar, devisa, anggaran, utang, pangan, energi, dan kejadian penting.
Alur: buka penjelasan → telusuri penyebab → menuju layar terkait → kembali ke ringkasan → lanjut ke kuartal berikutnya.
Ringkasan menjelaskan perubahan sebelum/sesudah simulasi, bukan sekadar mengulang dashboard.
5. Alur interaksi inti
5.1 Mengatasi inflasi
Beranda: peringatan inflasi meningkat.
Dashboard ekonomi: periksa energi, permintaan, dan nilai tukar.
Kebijakan moneter: ubah suku bunga dan tinjau estimasi dampak.
Konfirmasi keputusan.
Proses kuartal dan evaluasi inflasi, investasi, serta pengangguran.
5.2 Mengatasi kelangkaan pangan
Beranda: buka peringatan pangan.
Sumber Daya: buka detail komoditas.
Bandingkan stok, kebutuhan, produksi, dan pemasok.
Pilih impor, cadangan strategis, atau dukungan produksi.
Konfirmasi, proses kuartal, lalu evaluasi hasil.
5.3 Melakukan perdagangan
Peta dunia: pilih negara.
Profil negara: periksa surplus dan kebutuhan.
Buat penawaran: atur volume dan ketentuan.
Tinjau dan kirim penawaran.
Negosiasi sampai kontrak aktif.
6. Perilaku khusus Android
Aspek
Aturan implementasi

Safe area
Hormati status bar, camera cutout, dan navigation bar.

Target sentuh
Minimum 48 × 48 dp.

Scroll
Scroll vertikal untuk konten; horizontal untuk tab/grafik yang sesuai.

Navigasi kembali
Kembali ke layar sebelumnya; perubahan belum disimpan memicu konfirmasi.

Keyboard
Input angka memakai numeric keyboard dan tidak tertutup keyboard.

Orientasi
Portrait default; landscape untuk layar yang memerlukannya.

Responsivitas
Pada layar sempit, kartu dua kolom dapat berubah menjadi satu kolom.

Aksesibilitas
Label ikon, kontras memadai, teks mengikuti pengaturan sistem.

Performa
Batasi animasi dekoratif dan hindari grafik berat yang terus diperbarui.

Save/load
Simpan kampanye, keputusan, giliran, dan status simulasi secara konsisten.


Jetpack Compose dapat digunakan untuk implementasi native Android. Jika proyek memakai Unity atau Godot seperti yang dipertimbangkan dalam blueprint, prinsip visual dan ukuran tetap berlaku, tetapi implementasi komponen mengikuti engine terpilih.
7. Prioritas implementasi
Fase 01 — Fondasi UI
Sistem warna, tipografi, spacing, dan komponen dasar
Navigasi bawah dan header kuartal
Dashboard negara dengan KPI
Fase 02 — Inti keputusan
Dashboard ekonomi dan grafik
Detail komoditas dan stok
Panel kebijakan dan kontrol angka
Fase 03 — Siklus permainan
Konfirmasi keputusan
Proses akhir kuartal dan laporan hasil
Save/load dan pemulihan sesi
Fase 04 — Kedalaman strategi
Profil negara dan diplomasi
Kejadian global dan pilihan respons
Pengaturan, tutorial, dan aksesibilitas
8. Kriteria penerimaan UI
Pemain baru dapat memahami kondisi negara tanpa membuka banyak layar.
Pemain dapat menemukan penyebab masalah ekonomi dari indikator atau laporan.
Nilai saat ini, nilai usulan, dan nilai hasil simulasi dibedakan secara jelas.
Keputusan yang belum dikonfirmasi tidak mengubah simulasi.
Pemain dapat menyelesaikan satu siklus kuartal: analisis → kebijakan → proses → evaluasi.
Setiap grafik memiliki label, satuan, dan periode.
Status tidak hanya dibedakan dengan warna.
Navigasi kembali dan perubahan belum disimpan ditangani dengan benar.
UI tetap dapat digunakan pada layar Android yang lebih sempit dan dengan ukuran teks lebih besar.
9. Keputusan yang masih perlu ditetapkan
Engine implementasi: Unity, Godot, atau native Android.
Ukuran layar target minimum dan daftar perangkat uji.
Model interaksi peta dunia pada layar sentuh.
Format mata uang dan satuan untuk setiap skenario negara.
Apakah pemain dapat mengubah beberapa kebijakan sekaligus sebelum memproses kuartal.
Detail formula estimasi dampak kebijakan; formula ini belum ditetapkan dalam spesifikasi UI.

SOVEREIGN · THE RESOURCE ECONOMY
Acuan desain UI Android — v1.0
