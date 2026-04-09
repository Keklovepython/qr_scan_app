import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  // Необхідно для ініціалізації SharedPreferences до запуску додатка
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Якщо користувач увійшов — показуємо меню, якщо ні — екран логіну
      home: isLoggedIn ? const MainMenu() : const LoginScreen(),
    );
  }
}

// --- ЕКРАН АВТОРИЗАЦІЇ ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _nameController.text);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainMenu()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade600],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, size: 90, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Вхід в систему",
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildInput(_nameController, "Ім'я", Icons.person, (v) => v!.isEmpty ? "Введіть ім'я" : null),
                  const SizedBox(height: 15),
                  
                  _buildInput(_emailController, "Пошта", Icons.email, (v) => !v!.contains("@") ? "Невірний формат пошти" : null, type: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  
                  _buildInput(_phoneController, "Телефон", Icons.phone, (v) => v!.length < 10 ? "Введіть коректний номер" : null, type: TextInputType.phone),
                  
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _login,
                    child: const Text("УВІЙТИ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, String? Function(String?)? validator, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
        hintText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- ГОЛОВНЕ МЕНЮ (З КНОПКОЮ ВИХОДУ) ---
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
            
            MenuButton(
              text: "СКАНУВАТИ",
              icon: Icons.camera_alt,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen())),
            ),
            
            const SizedBox(height: 20),
            
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
            ),

            // КНОПКА ВИХОДУ
            TextButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              label: const Text("Вийти з акаунта", style: TextStyle(color: Colors.white70)),
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
            const Text("Код знайдено!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(code, textAlign: TextAlign.center),
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
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Збережено в історію!")));
                },
                child: const Text("Зберегти"),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// --- ІСТОРІЯ ---
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
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final history = snapshot.data!.getStringList(storageKey) ?? [];
        if (history.isEmpty) return const Center(child: Text("Історія порожня"));
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(history[index]),
            leading: const Icon(Icons.qr_code),
            onTap: () => _launchURL(history[index]),
          ),
        );
      },
    );
  }
}

// Функція для відкриття посилань
Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // Якщо не посилання, просто нічого не робимо або виводимо помилку
  }
}
