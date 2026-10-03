import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

// --- FFI STRUCTS & TYPEDEFS ---

final class EmulatorStatsStruct extends Struct {
  @Float()
  external double currentFps;

  @Int32()
  external int ramUsageMb;

  @Int32()
  external int cpuLoadPercent;

  @Int32()
  external int isRunning;
}

typedef NativeInitAndBoot = Int32 Function(Pointer<Utf8> gamePath, Pointer<Utf8> fwPath);
typedef DartInitAndBoot = int Function(Pointer<Utf8> gamePath, Pointer<Utf8> fwPath);

typedef NativeGetStats = Void Function(Pointer<EmulatorStatsStruct> outStats);
typedef DartGetStats = void Function(Pointer<EmulatorStatsStruct> outStats);

typedef NativeStop = Void Function();
typedef DartStop = void Function();

class PS4NativeEngine {
  DynamicLibrary? _lib;
  DartInitAndBoot? _bootFunc;
  DartGetStats? _getStatsFunc;
  DartStop? _stopFunc;

  bool isLoaded = false;

  PS4NativeEngine() {
    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open("libps4_emulator_core.so");
        isLoaded = true;
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.process();
        isLoaded = true;
      }

      if (isLoaded && _lib != null) {
        _bootFunc = _lib!
            .lookup<NativeFunction<NativeInitAndBoot>>("PS4Core_InitAndBoot")
            .asFunction<DartInitAndBoot>();
        _getStatsFunc = _lib!
            .lookup<NativeFunction<NativeGetStats>>("PS4Core_GetStats")
            .asFunction<DartGetStats>();
        _stopFunc = _lib!
            .lookup<NativeFunction<NativeStop>>("PS4Core_Stop")
            .asFunction<DartStop>();
      }
    } catch (e) {
      isLoaded = false;
    }
  }

  int boot(String gamePath, String? fwPath) {
    if (!isLoaded || _bootFunc == null) return -1;
    final pGame = gamePath.toNativeUtf8();
    final pFw = fwPath != null ? fwPath.toNativeUtf8() : nullptr;

    final res = _bootFunc!(pGame, pFw.cast<Utf8>());

    calloc.free(pGame);
    if (pFw != nullptr) calloc.free(pFw);
    return res;
  }

  void getStats(Pointer<EmulatorStatsStruct> stats) {
    if (isLoaded && _getStatsFunc != null) {
      _getStatsFunc!(stats);
    }
  }

  void stop() {
    if (isLoaded && _stopFunc != null) {
      _stopFunc!();
    }
  }
}

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

// --- MAIN APP ---

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final List<GameModel> _games = [];
  final PS4NativeEngine _engine = PS4NativeEngine();

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
          SnackBar(content: Text('خطأ في إضافة اللعبة: $e')),
        );
      }
    }
  }

  Future<void> _installNewFirmware() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
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
            SnackBar(content: Text('تم تثبيت نظام PS4 وتفعيله بنجاح: $fileName')),
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
        return StatefulWidget(
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
                            subtitle: Text(fw.isBuiltIn ? 'نظام مثبّت جاهز (FW 9.00)' : 'ملف خارجي: ${fw.filePath}'),
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
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
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
                              builder: (context) => NativeEmulatorRunnerScreen(
                                game: game,
                                activeFirmware: _activeFirmware,
                                engine: _engine,
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
                              const Icon(Icons.sports_esports, size: 48, color: Colors.cyanAccent),
                              const SizedBox(height: 8),
                              Text(game.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                              const SizedBox(height: 4),
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

// --- EMULATOR RUNNER SCREEN ---

class NativeEmulatorRunnerScreen extends StatefulWidget {
  final GameModel game;
  final FirmwareModel activeFirmware;
  final PS4NativeEngine engine;

  const NativeEmulatorRunnerScreen({
    super.key,
    required this.game,
    required this.activeFirmware,
    required this.engine,
  });

  @override
  State<NativeEmulatorRunnerScreen> createState() => _NativeEmulatorRunnerScreenState();
}

class _NativeEmulatorRunnerScreenState extends State<NativeEmulatorRunnerScreen> {
  Timer? _statsTimer;
  Pointer<EmulatorStatsStruct>? _statsPointer;

  double _fps = 0.0;
  int _ram = 0;
  int _cpu = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _statsPointer = calloc<EmulatorStatsStruct>();

    widget.engine.boot(widget.game.path, widget.activeFirmware.filePath);

    _statsTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted && _statsPointer != null) {
        widget.engine.getStats(_statsPointer!);
        setState(() {
          _fps = _statsPointer!.ref.currentFps;
          _ram = _statsPointer!.ref.ramUsageMb;
          _cpu = _statsPointer!.ref.cpuLoadPercent;
          _isRunning = _statsPointer!.ref.isRunning == 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    widget.engine.stop();
    if (_statsPointer != null) calloc.free(_statsPointer!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_filled, size: 90, color: Colors.cyanAccent),
                const SizedBox(height: 12),
                Text(
                  widget.game.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'المعرف: ${widget.game.titleId}',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isRunning ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    border: Border.all(color: _isRunning ? Colors.greenAccent : Colors.redAccent),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isRunning ? "المحاكي نشط (${widget.activeFirmware.name})" : "جاري التهيئة...",
                    style: TextStyle(color: _isRunning ? Colors.greenAccent : Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

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
                  Text('FPS الحقيقي: ${_fps.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('استهلاك الرام: $_ram MB', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('استهلاك المعالج: $_cpu%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('النظام المثبت: ${widget.activeFirmware.version}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                ],
              ),
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            child: Opacity(
              opacity: 0.6,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Center(child: Icon(Icons.open_with, color: Colors.white, size: 36)),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Opacity(
              opacity: 0.6,
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: const [
                    Align(alignment: Alignment.topCenter, child: Icon(Icons.change_history, color: Colors.greenAccent, size: 26)),
                    Align(alignment: Alignment.bottomCenter, child: Icon(Icons.clear, color: Colors.blueAccent, size: 26)),
                    Align(alignment: Alignment.centerLeft, child: Icon(Icons.crop_square, color: Colors.pinkAccent, size: 26)),
                    Align(alignment: Alignment.centerRight, child: Icon(Icons.panorama_fish_eye, color: Colors.redAccent, size: 26)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
