import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 81 il + bazı dünya şehirleri
const List<String> turkiyeSehirler = [
  'Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya','Ankara','Antalya',
  'Ardahan','Artvin','Aydın','Balıkesir','Bartın','Batman','Bayburt','Bilecik',
  'Bingöl','Bitlis','Bolu','Burdur','Bursa','Çanakkale','Çankırı','Çorum',
  'Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan','Erzurum','Eskişehir',
  'Gaziantep','Giresun','Gümüşhane','Hakkari','Hatay','Iğdır','Isparta','İstanbul',
  'İzmir','Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu','Kayseri','Kırıkkale',
  'Kırklareli','Kırşehir','Kilis','Kocaeli','Konya','Kütahya','Malatya','Manisa',
  'Mardin','Mersin','Muğla','Muş','Nevşehir','Niğde','Ordu','Osmaniye','Rize',
  'Sakarya','Samsun','Siirt','Sinop','Sivas','Şanlıurfa','Şırnak','Tekirdağ',
  'Tokat','Trabzon','Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak',
];

const Map<String, String> vakitAdlari = {
  'Fajr': 'İmsak',
  'Sunrise': 'Güneş',
  'Dhuhr': 'Öğle',
  'Asr': 'İkindi',
  'Maghrib': 'Akşam',
  'Isha': 'Yatsı',
};

const List<String> vakitSirasi = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

final Map<String, IconData> vakitIkonlari = {
  'Fajr': Icons.nightlight_round,
  'Sunrise': Icons.wb_twilight,
  'Dhuhr': Icons.wb_sunny,
  'Asr': Icons.cloud_queue,
  'Maghrib': Icons.dark_mode,
  'Isha': Icons.nights_stay,
};

void main() {
  runApp(const EzanVaktiApp());
}

class EzanVaktiApp extends StatelessWidget {
  const EzanVaktiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ezan Vakti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3D2E),
          primary: const Color(0xFF0B3D2E),
          secondary: const Color(0xFFFFC107),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F1E5),
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  String sehir = 'İstanbul';
  Map<String, String> vakitler = {};
  String hicriTarih = '';
  String miladiTarih = '';
  bool yukleniyor = true;
  String hata = '';
  Duration kalanSure = Duration.zero;
  String sonrakiVakitKey = '';
  Timer? _timer;
  DateTime? _sonrakiVakitZamani;

  @override
  void initState() {
    super.initState();
    _sehirYukle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sehirYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sehir = prefs.getString('sehir') ?? 'İstanbul';
    });
    await vakitleriGetir();
  }

  Future<void> _sehirKaydet(String yeniSehir) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sehir', yeniSehir);
  }

  Future<void> vakitleriGetir() async {
    setState(() {
      yukleniyor = true;
      hata = '';
    });
    try {
      final now = DateTime.now();
      final tarihStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      // method=13 -> Diyanet İşleri Başkanlığı, Türkiye
      final uri = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity/$tarihStr?city=$sehir&country=Turkey&method=13');
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Sunucu hatası: ${resp.statusCode}');
      }
      final data = json.decode(resp.body);
      final timings = Map<String, dynamic>.from(data['data']['timings']);
      final date = data['data']['date'];
      final hijri = date['hijri'];
      final miladi = date['gregorian'];

      final Map<String, String> temiz = {};
      for (final k in vakitSirasi) {
        final raw = (timings[k] ?? '').toString();
        // "05:30 (EET)" -> "05:30"
        temiz[k] = raw.split(' ').first;
      }

      setState(() {
        vakitler = temiz;
        hicriTarih =
            '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} Hicri';
        miladiTarih =
            '${miladi['day']} ${miladi['month']['en']} ${miladi['year']}';
        yukleniyor = false;
      });
      _sonrakiVaktiHesapla();
      _timeriBaslat();
    } catch (e) {
      setState(() {
        yukleniyor = false;
        hata = 'Vakitler alınamadı. İnternetinizi kontrol edin.\n$e';
      });
    }
  }

  void _timeriBaslat() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sonrakiVaktiHesapla();
    });
  }

  void _sonrakiVaktiHesapla() {
    if (vakitler.isEmpty) return;
    final now = DateTime.now();
    DateTime? nextTime;
    String? nextKey;

    for (final key in vakitSirasi) {
      final t = vakitler[key];
      if (t == null || t.isEmpty) continue;
      final parts = t.split(':');
      if (parts.length < 2) continue;
      final dt = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (dt.isAfter(now)) {
        nextTime = dt;
        nextKey = key;
        break;
      }
    }
    // Hepsi geçtiyse yarınki imsak (yaklaşık)
    if (nextTime == null) {
      final t = vakitler['Fajr'] ?? '05:30';
      final parts = t.split(':');
      final tomorrow = now.add(const Duration(days: 1));
      nextTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day,
          int.parse(parts[0]), int.parse(parts[1]));
      nextKey = 'Fajr';
    }
    setState(() {
      _sonrakiVakitZamani = nextTime;
      sonrakiVakitKey = nextKey ?? '';
      kalanSure = nextTime!.difference(now);
    });
  }

  String _kalanSureText() {
    if (_sonrakiVakitZamani == null) return '--:--:--';
    final d = kalanSure;
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _sehirSecDialog() {
    String arama = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          final filtre = turkiyeSehirler
              .where((s) =>
                  s.toLowerCase().contains(arama.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            builder: (_, ctrl) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Şehir Seç',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Şehir ara...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setModal(() => arama = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: ctrl,
                        itemCount: filtre.length,
                        itemBuilder: (_, i) {
                          final s = filtre[i];
                          final secili = s == sehir;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: secili
                                  ? const Color(0xFF0B3D2E)
                                  : Colors.grey[200],
                              child: Icon(Icons.location_city,
                                  color: secili
                                      ? const Color(0xFFFFC107)
                                      : Colors.grey[600]),
                            ),
                            title: Text(s,
                                style: TextStyle(
                                    fontWeight: secili
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            trailing: secili
                                ? const Icon(Icons.check,
                                    color: Color(0xFF0B3D2E))
                                : null,
                            onTap: () async {
                              setState(() => sehir = s);
                              await _sehirKaydet(s);
                              if (mounted) Navigator.pop(context);
                              vakitleriGetir();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vakitleriGetir,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: const Color(0xFF0B3D2E),
              flexibleSpace: FlexibleSpaceBar(
                background: _ustPanel(),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mosque,
                        color: Color(0xFF0B3D2E), size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ezan Vakti',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: vakitleriGetir,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sehirKarti(),
                    const SizedBox(height: 12),
                    if (yukleniyor)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hata.isNotEmpty)
                      _hataKarti()
                    else
                      ...vakitSirasi.map(_vakitKarti),
                    const SizedBox(height: 16),
                    _bilgiKarti(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ustPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B3D2E),
            Color(0xFF145A43),
            Color(0xFF1B7A5A),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sarı cami ikonu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.mosque,
                    size: 42, color: Color(0xFF0B3D2E)),
              ),
              const SizedBox(height: 10),
              Text(
                sonrakiVakitKey.isEmpty
                    ? '...'
                    : '${vakitAdlari[sonrakiVakitKey]}’ne kalan',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                _kalanSureText(),
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                sonrakiVakitKey.isEmpty
                    ? ''
                    : '${vakitAdlari[sonrakiVakitKey]} • ${vakitler[sonrakiVakitKey] ?? ''}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                miladiTarih.isEmpty ? '' : '$miladiTarih  •  $hicriTarih',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sehirKarti() {
    return InkWell(
      onTap: _sehirSecDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF0B3D2E)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Konum',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(sehir,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Değiştir',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vakitKarti(String key) {
    final aktif = key == sonrakiVakitKey;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: aktif ? const Color(0xFF0B3D2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: aktif
            ? Border.all(color: const Color(0xFFFFC107), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: aktif
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF0B3D2E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(vakitIkonlari[key],
                color: aktif
                    ? const Color(0xFF0B3D2E)
                    : const Color(0xFF0B3D2E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              vakitAdlari[key] ?? key,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: aktif ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (aktif)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Sıradaki',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          Text(
            vakitler[key] ?? '--:--',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: aktif
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF0B3D2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hataKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(hata, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: vakitleriGetir,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _bilgiKarti() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3D2E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF0B3D2E)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vakitler Diyanet takvimine (method 13) göre Aladhan API ile hesaplanır. İnternet gerektirir.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
