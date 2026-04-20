import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() async {
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
                  const Icon(
                    Icons.account_circle,
                    size: 90,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Вхід в систему",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInput(
                    _nameController,
                    "Ім'я",
                    Icons.person,
                    (v) => v!.isEmpty ? "Введіть ім'я" : null,
                  ),
                  const SizedBox(height: 15),
                  _buildInput(
                    _emailController,
                    "Пошта",
                    Icons.email,
                    (v) => !v!.contains("@") ? "Невірний формат" : null,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  _buildInput(
                    _phoneController,
                    "Телефон",
                    Icons.phone,
                    (v) => v!.length < 10 ? "Введіть номер" : null,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    onPressed: _login,
                    child: const Text(
                      "УВІЙТИ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
        hintText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- ГОЛОВНЕ МЕНЮ ---
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              ),
            ),
            const SizedBox(height: 20),
            MenuButton(
              text: "ГЕНЕРУВАТИ",
              icon: Icons.edit,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GeneratorScreen(),
                ),
              ),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: const Text(
                "Вийти",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const MenuButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 70,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
        

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanned = false;
  Future<void> _connectToWifi(String code) async {
    // Парсимо назву мережі (SSID) та пароль (Password)
    // Приклад коду: WIFI:S:MyNetwork;P:12345678;T:WPA;;
    final String ssid = RegExp(r'S:(.*?);').firstMatch(code)?.group(1) ?? "";
    final String password =
        RegExp(r'P:(.*?);').firstMatch(code)?.group(1) ?? "";

    if (ssid.isEmpty) return;

    try {
      bool isConnected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA, // Більшість сучасних мереж WPA/WPA2
        joinOnce: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected ? "Підключення до $ssid..." : "Помилка підключення",
            ),
          ),
        );
      }
    } catch (e) {
      print("Помилка Wi-Fi: $e");
    }
  }

  // ВАША ФУНКЦІЯ: Відкриття посилань
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    // Додаємо перевірку canLaunchUrl для стабільності
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Це не посилання або неможливо відкрити"),
          ),
        );
      }
    }
  }

  void _showResultDialog(String code) {
    bool isUrl = code.startsWith("http");
    bool isWifi = code.startsWith("WIFI:");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isWifi ? "Мережа Wi-Fi" : "Результат",
          textAlign: TextAlign.center,
        ),
        content: Text(
          isWifi ? "Знайдено параметри підключення" : code,
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Якщо посилання — кнопка ВІДКРИТИ
              if (isUrl)
                Expanded(
                  child: OutlinedButton(
                    style: _buttonStyle(),
                    onPressed: () => _launchURL(code),
                    child: const Text("ВІДКРИТИ"),
                  ),
                ),

              // ЯКЩО WI-FI — КНОПКА ПІДКЛЮЧИТИСЬ
              if (isWifi)
                Expanded(
                  child: OutlinedButton(
                    style: _buttonStyle(), // Ваш стиль з чорною окантовкою
                    onPressed: () => _connectToWifi(code),
                    child: const Text("З'ЄДНАТИ"),
                  ),
                ),

              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton(
                  style: _buttonStyle(),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("ЩЕ РАЗ"),
                ),
              ),

              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton(
                  style: _buttonStyle(),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text("МЕНЮ"),
                ),
              ),
            ],
          ),
        ],
      ),
    ).then((_) => setState(() => _isScanned = false));
  }

  // Допоміжний метод для однакового стилю кнопок
  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black, // Чорний колір тексту
      side: const BorderSide(
        color: Colors.black,
        width: 1.5,
      ), // Чорна окантовка
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontSize: 12, // Трохи менший розмір, щоб влізло три кнопки в ряд
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Сканування")),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            setState(() => _isScanned = true);
            final String code = barcodes.first.rawValue ?? "Порожній код";
            _showResultDialog(code);
          }
        },
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
  final ScreenshotController _screenshotController = ScreenshotController();
  String _data = "";

  Future<void> _shareQrCode() async {
    // 1. Створюємо скріншот віджета
    final image = await _screenshotController.capture();
    if (image == null) return;

    // 2. Зберігаємо у тимчасову папку
    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/qr_code.png').create();
    await imagePath.writeAsBytes(image);

    // 3. Викликаємо меню "Поділитися"
    await Share.shareXFiles([XFile(imagePath.path)], text: 'Мій QR-код');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Генератор QR")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Введіть дані",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _data = v),
            ),
            const SizedBox(height: 30),
            if (_data.isNotEmpty) ...[
              // Обгортка для створення скріншота
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  color: Colors.white, // Важливо для гарного вигляду картинки
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                    data: _data,
                    version: QrVersions.auto,
                    size: 200.0,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _shareQrCode,
                    icon: const Icon(Icons.share),
                    label: const Text("Поділитись"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Заглушка для історії (можна додати пізніше)
class HistoryTabs extends StatelessWidget {
  const HistoryTabs({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Історія")),
    body: const Center(child: Text("Тут буде ваша історія")),
  );
}
