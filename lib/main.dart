import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // تثبيت الاتجاه الأفقي يناسب تجربة اللعب على الآيفون والأندرويد
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PS4EmulatorApp());
}

class PS4EmulatorApp extends StatelessWidget {
  const PS4EmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 Emulator iOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GameLibraryScreen(),
    );
  }
}

// شاشة مكتبة الألعاب لرفع واختيار ملفات اللعبة
class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final List<String> _loadedGames = [];

  void _addGameFile() {
    // محاكاة اختيار ملف لعبة PKG أو ISO
    setState(() {
      _loadedGames.add('Game_${_loadedGames.length + 1}.pkg');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة ملف اللعبة بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاكي PS4 - مكتبة الألعاب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addGameFile,
            tooltip: 'إضافة ملف لعبة (.pkg / .iso)',
          ),
        ],
      ),
      body: _loadedGames.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_esports, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد ألعاب مضافة بعد\nاضغط على (+) لاختيار ملف اللعبة (PKG / ISO)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addGameFile,
                    icon: const Icon(Icons.file_open),
                    label: const Text('اختيار ملف اللعبة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _loadedGames.length,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.gamepad, color: Colors.blueAccent, size: 36),
                    title: Text(_loadedGames[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('صيغة: PS4 PKG Package'),
                    trailing: const Icon(Icons.play_arrow, color: Colors.greenAccent, size: 32),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmulatorScreen(gameName: _loadedGames[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// شاشة المحاكي الرئيسية لتشغيل اللعبة وأزرار اللمس
class EmulatorScreen extends StatefulWidget {
  final String gameName;
  const EmulatorScreen({super.key, required this.gameName});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> {
  String _lastInput = 'جاهز لبدء المحاكاة...';

  void _onButtonPressed(String button) {
    setState(() {
      _lastInput = 'أمر الزر: $button';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // شاشة عرض اللعبة (Game Viewport)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF0D0D0D),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'جاري تشغيل: ${widget.gameName}',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 15),
                  Text(
                    _lastInput,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // أزرار التحكم العلوي (L1, L2, R1, R2)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTouchButton('L2', () => _onButtonPressed('L2'), isSmall: true),
                    const SizedBox(width: 8),
                    _buildTouchButton('L1', () => _onButtonPressed('L1'), isSmall: true),
                  ],
                ),
                Row(
                  children: [
                    _buildTouchButton('R1', () => _onButtonPressed('R1'), isSmall: true),
                    const SizedBox(width: 8),
                    _buildTouchButton('R2', () => _onButtonPressed('R2'), isSmall: true),
                  ],
                ),
              ],
            ),
          ),

          // D-Pad (الجهة اليسرى)
          Positioned(
            bottom: 30,
            left: 30,
            child: Column(
              children: [
                _buildTouchButton('▲', () => _onButtonPressed('D-UP')),
                Row(
                  children: [
                    _buildTouchButton('◄', () => _onButtonPressed('D-LEFT')),
                    const SizedBox(width: 35),
                    _buildTouchButton('►', () => _onButtonPressed('D-RIGHT')),
                  ],
                ),
                _buildTouchButton('▼', () => _onButtonPressed('D-DOWN')),
              ],
            ),
          ),

          // أزرار الأشكال (الجهة اليمنى)
          Positioned(
            bottom: 30,
            right: 30,
            child: Column(
              children: [
                _buildTouchButton('△', () => _onButtonPressed('TRIANGLE'), textColor: Colors.greenAccent),
                Row(
                  children: [
                    _buildTouchButton('□', () => _onButtonPressed('SQUARE'), textColor: Colors.pinkAccent),
                    const SizedBox(width: 35),
                    _buildTouchButton('○', () => _onButtonPressed('CIRCLE'), textColor: Colors.redAccent),
                  ],
                ),
                _buildTouchButton('✕', () => _onButtonPressed('CROSS'), textColor: Colors.blueAccent),
              ],
            ),
          ),

          // أزرار الخروج والنظام
          Positioned(
            top: 20,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                _buildTouchButton('PS', () => _onButtonPressed('PS_BUTTON'), isSmall: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchButton(String label, VoidCallback onTap, {bool isSmall = false, Color textColor = Colors.white}) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        width: isSmall ? 45 : 55,
        height: isSmall ? 35 : 55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: isSmall ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isSmall ? BorderRadius.circular(8) : null,
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: isSmall ? 12 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
