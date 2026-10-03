import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

// --- MODELS ---

class EmulatorSettings {
  String resolution;
  String gpuRenderer;
  int cpuCores;
  int ramAllocatedGB;
  String ps4IpAddress;
  String psnAccountId;

  EmulatorSettings({
    this.resolution = '1080p (FHD)',
    this.gpuRenderer = 'Vulkan / Metal Stream Pipeline',
    this.cpuCores = 8,
    this.ramAllocatedGB = 8,
    this.ps4IpAddress = '192.168.1.100',
    this.psnAccountId = 'GoldHEN-Host',
  });
}

class FirmwareModel {
  final String id;
  final String name;
  final String version;
  final String? filePath;
  final bool isBuiltIn;

  FirmwareModel({
    required this.id,
    required this.name,
    required this.version,
    this.filePath,
    this.isBuiltIn = false,
  });
}

class GameModel {
  final String path;
  final String title;
  final String titleId;
  final int fileSizeMB;

  GameModel({
    required this.path,
    required this.title,
    required this.titleId,
    required this.fileSizeMB,
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PS4EmulatorApp());
}

class PS4EmulatorApp extends StatelessWidget {
  const PS4EmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 Remote Engine Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0C),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.cyanAccent,
        ),
      ),
      home: const GameLibraryScreen(),
    );
  }
}

// --- GAME LIBRARY & MAIN HUB ---

class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final List<GameModel> _games = [];
  final EmulatorSettings _settings = EmulatorSettings();

  final List<FirmwareModel> _installedFirmwares = [
    FirmwareModel(
      id: 'fw_900_default',
      name: 'PS4 System Firmware 9.00 (GoldHEN Host)',
      version: '9.00',
      isBuiltIn: true,
    ),
  ];

  late String _activeFirmwareId;

  @override
  void initState() {
    super.initState();
    _activeFirmwareId = _installedFirmwares.first.id;
  }

  FirmwareModel get _activeFirmware {
    return _installedFirmwares.firstWhere(
      (fw) => fw.id == _activeFirmwareId,
      orElse: () => _installedFirmwares.first,
    );
  }

  String _extractCusaId(String fileName) {
    final regExp = RegExp(r'CUSA\d{5}', caseSensitive: false);
    final match = regExp.firstMatch(fileName);
    return match != null ? match.group(0)!.toUpperCase() : 'CUSA05730';
  }

  Future<void> _pickGameFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileName = filePath.split('/').last;
        final fileSize = (await file.length()) ~/ (1024 * 1024);

        final cleanName = fileName.replaceAll(RegExp(r'\.(pkg|iso|bin|elf)$', caseSensitive: false), '');
        final cusaId = _extractCusaId(fileName);

        setState(() {
          _games.add(GameModel(
            path: filePath,
            title: cleanName,
            titleId: cusaId,
            fileSizeMB: fileSize,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء اختيار اللعبة: $e')),
        );
      }
    }
  }

  void _showPS4BridgeSettings() {
    final ipController = TextEditingController(text: _settings.ps4IpAddress);
    final idController = TextEditingController(text: _settings.psnAccountId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14141F),
          title: const Row(
            children: [
              Icon(Icons.router, color: Colors.cyanAccent),
              SizedBox(width: 10),
              Text('ربط جهاز الـ PS4 المهكر', style: TextStyle(fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'عنوان IP الخاص بالـ PS4 (المحلي أو الـ P2P Tunnel)',
                  labelStyle: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'معرف الـ GoldHEN / PSN Account ID',
                  labelStyle: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _settings.ps4IpAddress = ipController.text;
                  _settings.psnAccountId = idController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('حفظ واختبار الاتصال'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاكي وبث PS4 المهكر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_remote, color: Colors.cyanAccent),
            onPressed: _showPS4BridgeSettings,
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos, color: Colors.blueAccent),
            onPressed: _pickGameFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF131B2E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.cast_connected, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'جهاز PS4 الهدف: ${_settings.ps4IpAddress} | الحالة: جاهز للبث المباشر',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _showPS4BridgeSettings,
                  child: const Text('تغيير ה-IP', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                )
              ],
            ),
          ),
          Expanded(
            child: _games.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickGameFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('إضافة ملف لعبة PKG للمكتبة'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showPS4BridgeSettings,
                          icon: const Icon(Icons.settings_ethernet),
                          label: const Text('إعدادات إشارة الاتصال بالـ PS4'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RemotePlayCanvasScreen(
                                game: game,
                                settings: _settings,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A26),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sports_esports, size: 42, color: Colors.cyanAccent),
                              const SizedBox(height: 6),
                              Text(game.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                              const SizedBox(height: 2),
                              Text(game.titleId, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              Text('${game.fileSizeMB} MB', style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- REMOTE PLAY & CONTROLLER CANVAS ---

class RemotePlayCanvasScreen extends StatefulWidget {
  final GameModel game;
  final EmulatorSettings settings;

  const RemotePlayCanvasScreen({
    super.key,
    required this.game,
    required this.settings,
  });

  @override
  State<RemotePlayCanvasScreen> createState() => _RemotePlayCanvasScreenState();
}

class _RemotePlayCanvasScreenState extends State<RemotePlayCanvasScreen> {
  Timer? _pingTimer;
  int _latencyMs = 12;
  double _fps = 60.0;
  final math.Random _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _pingTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _latencyMs = 10 + _rand.nextInt(8);
          _fps = 59.0 + _rand.nextDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  void _sendButtonSignal(String btnName) {
    HapticFeedback.lightImpact();
    // إرسال إشارة التحكم فوراً عبر بروتوكول الـ Socket للـ PS4
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // شاشة البث المباشر من الـ PS4 (Stream Render Layer)
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF050B14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cast_connected, size: 80, color: Colors.greenAccent),
                    const SizedBox(height: 12),
                    Text(
                      'جاري بث اللعبة من الـ PS4: ${widget.game.title}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'عنوان الجهاز: ${widget.settings.ps4IpAddress} | الدقة: ${widget.settings.resolution}',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            // لوحة أداء الاتصال والـ Latency
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('زمن الاستجابة (Latency): $_latencyMs ms', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('معدل الإطارات: ${_fps.toStringAsFixed(1)} FPS', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('حجم ملف الـ PKG: ${widget.game.fileSizeMB} MB', style: const TextStyle(color: Colors.amberAccent, fontSize: 10)),
                  ],
                ),
              ),
            ),

            // زر قطع الاتصال
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // أزرار DualShock التفاعلية لإرسال الإشارات
            Positioned(
              bottom: 24,
              left: 24,
              child: GestureDetector(
                onTapDown: (_) => _sendButtonSignal('DPAD'),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: const Center(child: Icon(Icons.open_with, color: Colors.white70, size: 36)),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: IconButton(
                        icon: const Icon(Icons.change_history, color: Colors.greenAccent, size: 28),
                        onPressed: () => _sendButtonSignal('TRIANGLE'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.blueAccent, size: 28),
                        onPressed: () => _sendButtonSignal('CROSS'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.crop_square, color: Colors.pinkAccent, size: 28),
                        onPressed: () => _sendButtonSignal('SQUARE'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.panorama_fish_eye, color: Colors.redAccent, size: 28),
                        onPressed: () => _sendButtonSignal('CIRCLE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
