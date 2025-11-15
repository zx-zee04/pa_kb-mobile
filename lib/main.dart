import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';



void main() {
  runApp(const mangoscan_app());
}

class mango_color {
  static const green = Color(0xFF2E7D32);
  static const orange = Color(0xFFFFA000);
  static const bg = Color(0xFFF6F8F3);
  static const dark = Color(0xFF1B1B1B);
}

class mangoscan_app extends StatelessWidget {
  const mangoscan_app({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF4CAF50);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'mangoscan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed).copyWith(
          primary: mango_color.green,
          secondary: mango_color.orange,
          surface: mango_color.bg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: mango_color.bg,
          foregroundColor: mango_color.dark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: mango_color.dark,
          ),
        ),
        scaffoldBackgroundColor: mango_color.bg,
        useMaterial3: true,
      ),
      home: const home_root(),
    );
  }
}

class home_root extends StatefulWidget {
  const home_root({super.key});

  @override
  State<home_root> createState() => _home_root_state();
}

class _home_root_state extends State<home_root> {
  int idx = 0;
  File? gambar;
  String? hasil;

  void set_hasil(String v) {
    setState(() {
      hasil = v;
      idx = 1;
    });
  }

  void set_gambar(File? f) {
    setState(() {
      gambar = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      scan_page(onPick: set_gambar, onPredict: set_hasil, selected: gambar),
      hasil_page(gambar: gambar, hasil: hasil),
      panduan_page(),
      tentang_page(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Mangoscan')),
      body: pages[idx],
      bottomNavigationBar: navbar(idx: idx, onTap: (v) => setState(() => idx = v)),
    );
  }
}

class navbar extends StatelessWidget {
  final int idx;
  final ValueChanged<int> onTap;
  const navbar({super.key, required this.idx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: idx,
      onDestinationSelected: onTap,
      indicatorColor: mango_color.orange.withOpacity(.2),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'scan'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'hasil'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'panduan'),
        NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'tentang'),
      ],
    );
  }
}

class scan_page extends StatefulWidget {
  final void Function(File?) onPick;
  final void Function(String) onPredict;
  final File? selected;
  const scan_page({super.key, required this.onPick, required this.onPredict, required this.selected});

  @override
  State<scan_page> createState() => _scan_page_state();
}

class _scan_page_state extends State<scan_page> {
  CameraController? cam;
  List<CameraDescription>? cams;
  bool flash = false;
  bool proses = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    init_camera();
  }

  Future<void> init_camera() async {
    cams = await availableCameras();
    if (cams == null || cams!.isEmpty) return;
    cam = CameraController(cams!.first, ResolutionPreset.medium, enableAudio: false);
    await cam!.initialize();
    setState(() {});
  }

  Future<void> toggle_flash() async {
    if (cam == null) return;
    flash = !flash;
    await cam!.setFlashMode(flash ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> capture_image() async {
    if (cam == null || !cam!.value.isInitialized) return;
    setState(() => proses = true);
    final dir = await getTemporaryDirectory();
    final filePath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final xfile = await cam!.takePicture();
    await xfile.saveTo(filePath);
    final file = File(filePath);
    await proseskan(file);
  }

  Future<void> pick_from_gallery() async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x == null) return;
    await proseskan(File(x.path));
  }

Future<void> proseskan(File file) async {
  widget.onPick(file);
  setState(() => proses = true);

  try {
    var uri = Uri.parse(
      'https://unsedative-imponderably-jerry.ngrok-free.dev/predict'
    );
    print("=== MANGOSCAN API URL ===");
    print("API URL = $uri");

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var jsonResponse = await http.Response.fromStream(response);
      var data = json.decode(jsonResponse.body);

      String label = data['prediction'];
      double conf = data['confidence'] * 100;

      widget.onPredict("$label (${conf.toStringAsFixed(1)}%)");
    } else {
      widget.onPredict("Gagal memproses gambar (Error ${response.statusCode})");
    }
  } catch (e) {
    widget.onPredict("Terjadi kesalahan koneksi: $e");
  }

  setState(() => proses = false);
}

  @override
  void dispose() {
    cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cam == null || !cam!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(cam!),
        Positioned(
          bottom: 36,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(flash ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 30),
                onPressed: toggle_flash,
              ),
              GestureDetector(
                onTap: proses ? null : capture_image,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: proses ? Colors.grey : mango_color.orange),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                onPressed: proses ? null : pick_from_gallery,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class hasil_page extends StatelessWidget {
  final File? gambar;
  final String? hasil;
  const hasil_page({super.key, required this.gambar, required this.hasil});

  String getDeskripsi(String label) {
    switch (label) {
      case 'Early_ripe':
        return 'Mangga berada pada tahap awal kematangan. Tekstur masih agak keras namun mulai manis. Cocok untuk disimpan 1–2 hari sebelum dikonsumsi.';
      case 'Partially_ripe':
        return 'Mangga hampir matang. Daging mulai empuk dan rasa manis mulai terasa. Cocok dimakan besok atau dijadikan bahan olahan.';
      case 'Ripe':
        return 'Mangga sudah matang sempurna. Tekstur empuk, aroma harum, dan rasa manis maksimal. Siap disantap langsung.';
      case 'Rotten':
        return 'Mangga sudah melewati masa konsumsi. Tekstur sangat lembek, aroma menyengat, dan kemungkinan terdapat bercak busuk. Tidak layak makan.';
      case 'Unripe':
        return 'Mangga masih mentah. Tekstur keras dan rasa cenderung asam. Simpan beberapa hari agar matang.';
      default:
        return 'Tidak ada deskripsi untuk hasil ini.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil label tanpa persen, contoh:
    // "Ripe (98.5%)" → "Ripe"
    final labelBersih =
        hasil == null ? null : hasil!.split(" ").first.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasil != null)
          Center(
            child: Chip(
              label: Text(
                hasil!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              side: const BorderSide(color: Color(0xFFFFA000), width: 1.5),
              backgroundColor: const Color(0xFFFFA000).withOpacity(.15),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        const SizedBox(height: 12),

        // === GAMBAR ===
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color(0xFF2E7D32), width: 2),
          ),
          child: gambar == null
              ? Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 72,
                    color: Color(0xFF2E7D32).withOpacity(.4),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.file(
                    gambar!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),

        const SizedBox(height: 16),

        // === JUDUL DESKRIPSI ===
        Text(
          'Deskripsi',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // === ISI DESKRIPSI ===
        Text(
          hasil == null
              ? 'Belum ada hasil prediksi.'
              : getDeskripsi(labelBersih!),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class panduan_page extends StatelessWidget {
  panduan_page({super.key});

  final tips = const [
    {
      'judul': 'Perhatikan warna kulit',
      'isi': 'Mangga matang cenderung hijau kekuningan atau oranye pada beberapa varietas.',
      'image': 'assets/kulit.png'
    },
    {
      'judul': 'Raba tekstur',
      'isi': 'Sedikit empuk saat ditekan perlahan menandakan tingkat kematangan yang pas.',
      'image': 'assets/tekan.png'
    },
    {
      'judul': 'Cium aromanya',
      'isi': 'Aroma manis lembut di sekitar tangkai biasanya tanda siap santap.',
      'image': 'assets/aroma.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tips Memilih Mangga yang Manis dan Matang', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...tips.map((t) => card_tip(
          judul: t['judul']!,
          isi: t['isi']!,
          image: t['image']!,
        )).toList(),
      ],
    );
  }
}

class card_tip extends StatelessWidget {
  final String judul;
  final String isi;
  final String image;

  const card_tip({
    super.key,
    required this.judul,
    required this.isi,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: mango_color.green.withOpacity(.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: mango_color.green.withOpacity(.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mango_color.green.withOpacity(.25)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(isi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class tentang_page extends StatelessWidget {
  tentang_page({super.key});

  final tim = const [
    {'nama': 'Muhammad Nur Ramadhan', 'peran': 'Model CNN & API'},
    {'nama': 'Bagus Setianto', 'peran': 'UI & Integrasi Kamera'},
    {'nama': 'Marlina Yunus', 'peran': 'API Flask'},
    {'nama': 'June Alya Anantha', 'peran': 'UI & Hasil Prediksi'},
  ];

  void _launchURL() async {
    final url = Uri.parse("https://chat.whatsapp.com/LsIbz4yGf2jErt3pKnfiVj");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Tidak dapat membuka URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        Container(
          height: 160,
          child: Center(
            child: Image.asset(
              "assets/APPIcon.png",
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 25),
        Center(
          child: Text('Tentang Kami', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),), 
        const SizedBox(height: 2),
        ...tim.map((m) => ListTile(
              leading: CircleAvatar(backgroundColor: mango_color.green, child: const Icon(Icons.person, color: Colors.white)),
              title: Text(m['nama']!),
              subtitle: Text(m['peran']!),
              trailing: const Icon(Icons.chevron_right),
            )),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: mango_color.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _launchURL,
          child: const Text('hubungi kami'),
        )
      ],
    );
  }
}

class filled_button extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool full;
  const filled_button({super.key, required this.text, required this.icon, required this.color, required this.onPressed, this.full = false});

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    return full ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}