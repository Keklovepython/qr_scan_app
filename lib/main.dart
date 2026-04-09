import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainMenu(),
    );
  }
}

// --- ГОЛОВНЕ МЕНЮ (2 КНОПКИ) ---
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2, size: 100, color: Colors.white),
            const SizedBox(height: 40),
            
            // КНОПКА СКАНУВАТИ
            MenuButton(
              text: "СКАНУВАТИ",
              icon: Icons.camera_alt,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen())),
            ),
            
            const SizedBox(height: 20),
            
            // КНОПКА ГЕНЕРУВАТИ
            MenuButton(
              text: "ГЕНЕРУВАТИ",
              icon: Icons.edit,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneratorScreen())),
            ),

            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryTabs())),
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text("Історія", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}

// Кастомний віджет кнопки для меню
class MenuButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const MenuButton({required this.text, required this.icon, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 70,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- ЕКРАН СКАНЕРА ---
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Кнопка назад у вигляді трикутника
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), 
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Сканування", style: TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_isScanned) return;
              final code = capture.barcodes.first.rawValue;
              if (code != null) {
                _isScanned = true;
                final prefs = await SharedPreferences.getInstance();
                List<String> history = prefs.getStringList('scan_history') ?? [];
                if (!history.contains(code)) {
                  history.insert(0, code);
                  await prefs.setStringList('scan_history', history);
                }
                if (!mounted) return;
                _showResult(code);
              }
            },
          ),
          // Рамка по центру
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResult(String code) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Код знайдено!"),
            const SizedBox(height: 10),
            Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => _launchURL(code), child: const Text("Відкрити")),
            TextButton(onPressed: () { Navigator.pop(context); setState(() => _isScanned = false); }, child: const Text("Сканувати ще")),
          ],
        ),
      ),
    );
  }
}

// --- ЕКРАН ГЕНЕРАТОРА ---
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _controller = TextEditingController();
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Кнопка назад
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Створити QR"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _data = v),
              decoration: const InputDecoration(
                labelText: "Введіть текст/посилання",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            if (_data.isNotEmpty) ...[
              QrImageView(data: _data, size: 200),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  List<String> history = prefs.getStringList('gen_history') ?? [];
                  history.insert(0, _data);
                  await prefs.setStringList('gen_history', history);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Збережено!")));
                },
                child: const Text("Зберегти в історію"),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// --- ЕКРАНИ ІСТОРІЇ (Аналогічно з кнопкою назад) ---
class HistoryTabs extends StatelessWidget {
  const HistoryTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Історія"),
          bottom: const TabBar(tabs: [Tab(text: "Скани"), Tab(text: "Генерації")]),
        ),
        body: const TabBarView(children: [
          HistoryList(storageKey: 'scan_history'),
          HistoryList(storageKey: 'gen_history'),
        ]),
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  final String storageKey;
  const HistoryList({required this.storageKey, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: SharedPreferences.getInstance().then((p) => p.getStringList(storageKey) ?? []),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Порожньо"));
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(snapshot.data![i], maxLines: 1),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14), // Ще один "трикутник"
            onTap: () => _launchURL(snapshot.data![i]),
          ),
        );
      },
    );
  }
}

Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint("Could not launch $url");
  }
}