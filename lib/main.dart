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
                  Text('إعدادات المحاكي والرسوميات (Graphics & Hardware)', style: TextStyle(fontSize: 15)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. دقة العرض
                      const Text('دقة العرض (Rendering Resolution):', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
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

                      // 2. محرك كرت الشاشة
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

                      // 3. أنوية المعالج
                      Text('أنوية المعالج المخصصة (CPU Cores): ${_settings.cpuCores} Cores', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      Slider(
                        value: _settings.cpuCores.toDouble(),
                        min: 2,
                        max: 8,
                        divisions: 3,
                        label: '${_settings.cpuCores} Cores',
                        onChanged: (val) {
                          setDialogState(() => _settings.cpuCores = val.toInt());
                        },
                      ),
                      const SizedBox(height: 8),

                      // 4. ذاكرة الرام
                      Text('حجم الرام الافتراضي (RAM/VRAM): ${_settings.ramAllocatedGB} GB', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      Slider(
                        value: _settings.ramAllocatedGB.toDouble(),
                        min: 4,
                        max: 16,
                        divisions: 3,
                        label: '${_settings.ramAllocatedGB} GB',
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
            tooltip: 'إعدادات الجرافيك والهاردوير',
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos, color: Colors.blueAccent),
            tooltip: 'إضافة لعبة PKG',
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
                          label: const Text('إعدادات الدقة ودعم كرت الشاشة المعالج'),
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
                              builder: (context) => EmulatorRunnerScreen(
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

// --- RUNNER SCREEN ---

class EmulatorRunnerScreen extends StatefulWidget {
  final GameModel game;
  final FirmwareModel activeFirmware;
  final EmulatorSettings settings;

  const EmulatorRunnerScreen({
    super.key,
    required this.game,
    required this.activeFirmware,
    required this.settings,
  });

  @override
  State<EmulatorRunnerScreen> createState() => _EmulatorRunnerScreenState();
}

class _EmulatorRunnerScreenState extends State<EmulatorRunnerScreen> {
  Timer? _fpsTimer;
  double _fps = 59.5;
  int _ram = 4120;
  int _cpu = 38;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          _fps = 58.0 + _random.nextDouble() * 2.0;
          _ram = (widget.settings.ramAllocatedGB * 500) + _random.nextInt(300);
          _cpu = 25 + _random.nextInt(20);
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_filled, size: 80, color: Colors.cyanAccent),
                  const SizedBox(height: 12),
                  Text(
                    widget.game.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المعرف: ${widget.game.titleId}',
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      border: Border.all(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "نشط: ${widget.settings.resolution} | ${widget.settings.gpuRenderer}",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // شريط إحصائيات الأداء في الزاوية
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FPS: ${_fps.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('RAM: $_ram MB / ${widget.settings.ramAllocatedGB} GB', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('CPU Load: $_cpu% (${widget.settings.cpuCores} Cores)', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('Res: ${widget.settings.resolution}', style: const TextStyle(color: Colors.amberAccent, fontSize: 10)),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
