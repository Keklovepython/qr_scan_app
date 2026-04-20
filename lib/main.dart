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
import 'package:flutter/services.dart'; // Потрібно для буфера


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
            MenuButton(
              text: "ІСТОРІЯ",
              icon: Icons.history,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ), // Ваш новий екран
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

            // 1. Отримуємо текст коду
            final String code = barcodes.first.rawValue ?? "Порожній код";

            // 2. ЗБЕРІГАЄМО В ІСТОРІЮ (використовуємо правильну змінну 'code')
            saveToHistory(code, 'scan_history');

            // 3. Показуємо діалог
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

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Дві вкладки
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Історія кодів"),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmClearHistory(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Сканування", icon: Icon(Icons.qr_code_scanner)),
              Tab(text: "Генерація", icon: Icon(Icons.history_edu)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HistoryListView(storageKey: 'scan_history'), // Список для сканів
            HistoryListView(storageKey: 'gen_history'), // Список для генерацій
          ],
        ),
      ),
    );
  }
}

class HistoryListView extends StatelessWidget {
  final String storageKey;
  const HistoryListView({super.key, required this.storageKey});

  Future<List<String>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey) ?? [];
  }

 @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _loadHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) return const Center(child: Text("Історія порожня"));

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return ListTile(
              leading: Icon(storageKey == 'scan_history' ? Icons.qr_code_scanner : Icons.edit),
              title: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: const Text("Натисніть, щоб відкрити"),
              onTap: () => _showDetails(context, item), // ОСЬ ТУТ ВИКЛИК
            );
          },
        );
      },
    ); 
  }
  // --- ДОДАЙТЕ ЦЕЙ МЕТОД НИЖЧЕ ---
  void _showDetails(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Результат"),
        content: SingleChildScrollView(
          child: SelectableText(data), // Можна виділити текст
        ),
        actions: [
          // Кнопка копіювання
          TextButton(
            onPressed: () {
              
              Clipboard.setData(ClipboardData(text: data));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Скопійовано!")),
              );
            },
            child: const Text("КОПІЮВАТИ"),
          ),
          // Кнопка закриття
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ОК"),
          ),
        ],
      ),
    );
  }


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

Future<void> saveToHistory(String value, String key) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList(key) ?? [];

  // Щоб не було дублікатів підряд
  if (history.isNotEmpty && history.first == value) return;

  history.insert(0, value); // Нове — на початок
  if (history.length > 50) history.removeLast(); // Обмежуємо до 50 записів

  await prefs.setStringList(key, history);
}



void _confirmClearHistory(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Очистити все?"),
      content: const Text("Ви впевнені, що хочете видалити всю історію сканувань та генерацій?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("СКАСУВАТИ")),
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('scan_history');
            await prefs.remove('gen_history');
            if (context.mounted) Navigator.pop(context);
            // Тут можна додати логіку оновлення екрана
          },
          child: const Text("ВИДАЛИТИ", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
