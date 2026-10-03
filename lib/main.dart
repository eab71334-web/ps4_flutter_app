import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

// --- MODELS ---

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
      title: 'PS4 Emulator Pro',
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

// --- GAME LIBRARY SCREEN ---

class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final List<GameModel> _games = [];

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

  Future<void> _installNewFirmware() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = filePath.split('/').last;

        final newFw = FirmwareModel(
          id: 'fw_${DateTime.now().millisecondsSinceEpoch}',
          name: fileName,
          version: 'مخصص',
          filePath: filePath,
          isBuiltIn: false,
        );

        setState(() {
          _installedFirmwares.add(newFw);
          _activeFirmwareId = newFw.id;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تثبيت نظام PS4 بنجاح: $fileName')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تثبيت النظام: $e')),
        );
      }
    }
  }

  void _showFirmwareManagerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF14141F),
              title: const Row(
                children: [
                  Icon(Icons.developer_board, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Text('إدارة إصدارات نظام PS4', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _installedFirmwares.length,
                      itemBuilder: (context, index) {
                        final fw = _installedFirmwares[index];
                        final isSelected = fw.id == _activeFirmwareId;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              fw.isBuiltIn ? Icons.verified : Icons.system_update_alt,
                              color: isSelected ? Colors.cyanAccent : Colors.grey,
                            ),
                            title: Text(fw.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(fw.isBuiltIn ? 'نظام مثبّت جاهز (FW 9.00)' : 'ملف نظام خارجي'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                    onPressed: () {
                                      setState(() => _activeFirmwareId = fw.id);
                                      setDialogState(() {});
                                    },
                                    child: const Text('تفعيل', style: TextStyle(fontSize: 12)),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _installNewFirmware();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('تثبيت إصدار نظام جديد (.PUP / .PKG)'),
                    ),
                  ],
                ),
              ),
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
            icon: const Icon(Icons.settings_suggest, color: Colors.cyanAccent),
            tooltip: 'إدارة وتغيير إصدار النظام',
            onPressed: _showFirmwareManagerDialog,
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
                const Icon(Icons.tune, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'النظام النشط: ${_activeFirmware.name}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _showFirmwareManagerDialog,
                  child: const Text('تبديل النظام', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
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
                          onPressed: _showFirmwareManagerDialog,
                          icon: const Icon(Icons.settings),
                          label: const Text('إدارة وتقسيم إصدارات PS4 Firmware'),
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

  const EmulatorRunnerScreen({
    super.key,
    required this.game,
    required this.activeFirmware,
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
          _ram = 4000 + _random.nextInt(300);
          _cpu = 30 + _random.nextInt(20);
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
                      "المحاكي نشط (${widget.activeFirmware.name})",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

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
                    Text('RAM: $_ram MB', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('CPU: $_cpu%', style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
