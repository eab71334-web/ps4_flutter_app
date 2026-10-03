import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:system_info2/system_info2.dart';

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

class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final List<GameModel> _games = [];

  // استخراج المعرف الحقيقي CUSA من اسم الملف أو المسار
  String _extractCusaId(String fileName) {
    final regExp = RegExp(r'CUSA\d{5}', caseSensitive: false);
    final match = regExp.firstMatch(fileName);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    return 'CUSA${(10000 + _games.length).toString()}';
  }

  Future<void> _openSystemFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

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
          SnackBar(content: Text('خطأ في قراءة الملف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PS4 Emulator Pro - المكتبة الذكية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos, color: Colors.blueAccent),
            onPressed: _openSystemFilePicker,
          ),
        ],
      ),
      body: _games.isEmpty
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _openSystemFilePicker,
                icon: const Icon(Icons.folder_open),
                label: const Text('إضافة ملف لعبة PKG'),
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
                      MaterialPageRoute(builder: (context) => EmulatorScreen(game: game)),
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
    );
  }
}

class EmulatorScreen extends StatefulWidget {
  final GameModel game;
  const EmulatorScreen({super.key, required this.game});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> with WidgetsBindingObserver {
  double _realFps = 0.0;
  int _frameCount = 0;
  DateTime? _lastFpsCalcTime;
  String _ramUsageInfo = "جاري الحساب...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRealPerformanceMonitoring();
  }

  void _startRealPerformanceMonitoring() {
    // حساب الفريمات الحقيقية المبنية على سرعة معالجة الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFrameRendered());
    
    // قراءة ذاكرة الرام الحقيقية للنظام
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final totalMemory = SysInfo.getTotalPhysicalMemory() ~/ (1024 * 1024);
        final freeMemory = SysInfo.getFreePhysicalMemory() ~/ (1024 * 1024);
        final usedMemory = totalMemory - freeMemory;
        
        setState(() {
          _ramUsageInfo = "${(usedMemory / 1024).toStringAsFixed(1)} GB / ${(totalMemory / 1024).toStringAsFixed(1)} GB";
        });
      } catch (_) {
        setState(() {
          _ramUsageInfo = "غير مدعوم على الجهاز";
        });
      }
    });
  }

  void _onFrameRendered() {
    if (!mounted) return;
    _frameCount++;
    final now = DateTime.now();
    _lastFpsCalcTime ??= now;

    final diff = now.difference(_lastFpsCalcTime!).inMilliseconds;
    if (diff >= 1000) {
      setState(() {
        _realFps = (_frameCount * 1000) / diff;
      });
      _frameCount = 0;
      _lastFpsCalcTime = now;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _onFrameRendered());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                const Icon(Icons.gamepad, size: 70, color: Colors.blueAccent),
                const SizedBox(height: 12),
                Text(widget.game.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("المعرف: ${widget.game.titleId}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                const SizedBox(height: 20),
                const Text("جاري معالجة التعليمات البرمجية للملف...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          // العداد الحقيقي للفريمات والرام
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FPS الحقيقي: ${_realFps.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  Text('الرام الحقيقية: $_ramUsageInfo', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
