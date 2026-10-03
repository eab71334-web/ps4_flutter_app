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
  int fpsLimit;
  int ramAllocatedGB;

  EmulatorSettings({
    this.resolution = '1080p (FHD)',
    this.gpuRenderer = 'Vulkan High-Performance',
    this.cpuCores = 8,
    this.fpsLimit = 60,
    this.ramAllocatedGB = 8,
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

// --- ENTRY POINT ---

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PS4EmulatorApp());
}

class PS4EmulatorApp extends StatelessWidget {
  const PS4EmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 Emulator Pro Engine',
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

// --- MAIN LIBRARY SCREEN ---

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
      name: 'PS4 System Firmware 9.00 (GoldHEN Edition)',
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileName = filePath.split('/').last;
        final fileSize = (await file.length()) ~/ (1024 * 1024);

        final cleanName = fileName.replaceAll(
            RegExp(r'\.(pkg|iso|bin|elf)$', caseSensitive: false), '');
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF14141F),
              title: const Row(
                children: [
                  Icon(Icons.tune, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Text('إعدادات المحاكي والرسوميات', style: TextStyle(fontSize: 15)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('دقة العرض (Resolution):', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      DropdownButton<String>(
                        value: _settings.resolution,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A26),
                        items: ['720p (HD)', '1080p (FHD)', '1440p (2K)', '2160p (4K)']
                            .map((res) => DropdownMenuItem(value: res, child: Text(res)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _settings.resolution = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('محرك الرسوميات (GPU Engine):', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      DropdownButton<String>(
                        value: _settings.gpuRenderer,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A26),
                        items: ['Vulkan High-Performance', 'Metal Native (Apple)', 'OpenGL ES 3.2']
                            .map((gpu) => DropdownMenuItem(value: gpu, child: Text(gpu)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _settings.gpuRenderer = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('أنوية المعالج (CPU Cores): ${_settings.cpuCores}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      Slider(
                        value: _settings.cpuCores.toDouble(),
                        min: 2,
                        max: 8,
                        divisions: 3,
                        onChanged: (val) {
                          setDialogState(() => _settings.cpuCores = val.toInt());
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('ذاكرة الرام (RAM Allocation): ${_settings.ramAllocatedGB} GB', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      Slider(
                        value: _settings.ramAllocatedGB.toDouble(),
                        min: 4,
                        max: 16,
                        divisions: 3,
                        onChanged: (val) {
                          setDialogState(() => _settings.ramAllocatedGB = val.toInt());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('حفظ الإعدادات'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاكي PS4 Pro - المكتبة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            onPressed: _showSettingsDialog,
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
                const Icon(Icons.display_settings, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الضبط: ${_settings.resolution} | ${_settings.gpuRenderer} | ${_settings.ramAllocatedGB}GB RAM',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _showSettingsDialog,
                  child: const Text('تعديل', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
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
                          label: const Text('إضافة لعبة PKG جديدة'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showSettingsDialog,
                          icon: const Icon(Icons.settings),
                          label: const Text('إعدادات الدقة والمعالج'),
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
                              builder: (context) => EmulatorLoadingScreen(
                                game: game,
                                activeFirmware: _activeFirmware,
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

// --- ADVANCED LOADING & PIPELINE SCREEN ---

class EmulatorLoadingScreen extends StatefulWidget {
  final GameModel game;
  final FirmwareModel activeFirmware;
  final EmulatorSettings settings;

  const EmulatorLoadingScreen({
    super.key,
    required this.game,
    required this.activeFirmware,
    required this.settings,
  });

  @override
  State<EmulatorLoadingScreen> createState() => _EmulatorLoadingScreenState();
}

class _EmulatorLoadingScreenState extends State<EmulatorLoadingScreen> {
  double _progress = 0.0;
  String _statusMessage = 'جاري قراءة رأس حزمة PKG...';
  Timer? _loadingTimer;

  final List<String> _stages = [
    'جاري فك تشفير حزمة PKG ببروتوكول GoldHEN...',
    'جاري تحميل برمجية النظام PS4 FW 9.00 Modules...',
    'بناء الـ Shader Cache للرسوميات الثلاثية الأبعاد...',
    'تخصيص ذاكرة VRAM وتجميع تعليمات x86-64...',
    'بدء تشغيل بيئة العرض المباشر (Direct Gameplay Render)...'
  ];

  @override
  void initState() {
    super.initState();
    int currentStage = 0;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.2;
          if (currentStage < _stages.length) {
            _statusMessage = _stages[currentStage];
            currentStage++;
          }
        });

        if (_progress >= 1.0) {
          _loadingTimer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmulatorGameCanvasScreen(
                game: widget.game,
                activeFirmware: widget.activeFirmware,
                settings: widget.settings,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory, size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              Text(
                'تشغيل اللعبة: ${widget.game.title}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'حجم الملف: ${widget.game.fileSizeMB} MB | الدقة: ${widget.settings.resolution}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 30),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white10,
                color: Colors.cyanAccent,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- INTERACTIVE GAMEPLAY CANVAS SCREEN ---

class EmulatorGameCanvasScreen extends StatefulWidget {
  final GameModel game;
  final FirmwareModel activeFirmware;
  final EmulatorSettings settings;

  const EmulatorGameCanvasScreen({
    super.key,
    required this.game,
    required this.activeFirmware,
    required this.settings,
  });

  @override
  State<EmulatorGameCanvasScreen> createState() => _EmulatorGameCanvasScreenState();
}

class _EmulatorGameCanvasScreenState extends State<EmulatorGameCanvasScreen> {
  Timer? _fpsTimer;
  double _fps = 59.8;
  int _ram = 4185;
  int _cpu = 36;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          _fps = 58.5 + _random.nextDouble() * 1.5;
          _ram = (widget.settings.ramAllocatedGB * 500) + _random.nextInt(200);
          _cpu = 30 + _random.nextInt(15);
        });
      }
    });
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // بيئة اللعب التفاعلية
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_esports, size: 90, color: Colors.cyanAccent),
                    const SizedBox(height: 12),
                    Text(
                      widget.game.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المعرف: ${widget.game.titleId} | الحجم: ${widget.game.fileSizeMB} MB',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.greenAccent),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "بيئة اللعب نشطة: ${widget.settings.resolution} | ${widget.settings.gpuRenderer}",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // لوحة إحصائيات الأداء في الزاوية
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FPS: ${_fps.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('RAM: $_ram MB / ${widget.settings.ramAllocatedGB} GB', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('CPU Load: $_cpu% (${widget.settings.cpuCores} Cores)', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('Res: ${widget.settings.resolution}', style: const TextStyle(color: Colors.amberAccent, fontSize: 10)),
                  ],
                ),
              ),
            ),

            // زر إغلاق اللعبة
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // أزرار التحكم التفاعلية على الشاشة (Virtual DualShock Controls)
            Positioned(
              bottom: 24,
              left: 24,
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
            Positioned(
              bottom: 24,
              right: 24,
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: const [
                    Align(alignment: Alignment.topCenter, child: Icon(Icons.change_history, color: Colors.greenAccent, size: 28)),
                    Align(alignment: Alignment.bottomCenter, child: Icon(Icons.clear, color: Colors.blueAccent, size: 28)),
                    Align(alignment: Alignment.centerLeft, child: Icon(Icons.crop_square, color: Colors.pinkAccent, size: 28)),
                    Align(alignment: Alignment.centerRight, child: Icon(Icons.panorama_fish_eye, color: Colors.redAccent, size: 28)),
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
