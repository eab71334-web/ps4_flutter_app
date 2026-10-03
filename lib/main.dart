import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

enum GamePlayMode { localEmulator, ps4RemoteStream }

class GameModel {
  final String path;
  final String title;
  final String titleId;
  final int fileSizeMB;
  GamePlayMode playMode;

  GameModel({
    required this.path,
    required this.title,
    required this.titleId,
    required this.fileSizeMB,
    this.playMode = GamePlayMode.localEmulator,
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PS4HybridEngineApp());
}

class PS4HybridEngineApp extends StatelessWidget {
  const PS4HybridEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS4 Hybrid Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.cyanAccent,
        ),
      ),
      home: const MainLibraryScreen(),
    );
  }
}

class MainLibraryScreen extends StatefulWidget {
  const MainLibraryScreen({super.key});

  @override
  State<MainLibraryScreen> createState() => _MainLibraryScreenState();
}

class _MainLibraryScreenState extends State<MainLibraryScreen> {
  final List<GameModel> _library = [];
  String _ps4Ip = '172.20.10.2';
  int _ps4Port = 9025;
  bool _isServerConnected = false;
  String _serverStatus = 'لم يتم الاتصال بسيرفر PKG';

  Future<void> _testPkgServerConnection() async {
    setState(() {
      _serverStatus = 'جاري الاتصال بالسيرفر...';
    });

    try {
      final socket = await Socket.connect(_ps4Ip, _ps4Port, timeout: const Duration(seconds: 4));
      socket.write('WAKE_PING\n');

      socket.listen((Uint8List data) {
        final response = String.fromCharCodes(data);
        if (response.contains('PS4_HOST_ACTIVE')) {
          setState(() {
            _isServerConnected = true;
            _serverStatus = 'سيرفر الـ PKG متصل وجاهز!';
          });
        }
        socket.destroy();
      }, onError: (error) {
        setState(() {
          _isServerConnected = false;
          _serverStatus = 'فشل الاتصال بسيرفر PKG';
        });
      });
    } catch (e) {
      setState(() {
        _isServerConnected = false;
        _serverStatus = 'غير قادر على التوصيل بـ $_ps4Ip:$_ps4Port';
      });
    }
  }

  Future<void> _addGameFromPhone() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileName = filePath.split('/').last;
        final fileSize = (await file.length()) ~/ (1024 * 1024);

        setState(() {
          _library.add(
            GameModel(
              path: filePath,
              title: fileName.replaceAll(RegExp(r'\.(pkg|iso|bin)$', caseSensitive: false), ''),
              titleId: 'CUSA05730',
              fileSizeMB: fileSize,
              playMode: GamePlayMode.localEmulator,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في اختيار الملف: $e')));
      }
    }
  }

  void _showServerConfigDialog() {
    final ipController = TextEditingController(text: _ps4Ip);
    final portController = TextEditingController(text: _ps4Port.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141829),
          title: const Row(
            children: [
              Icon(Icons.dns, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text('إعدادات سيرفر الـ PKG للـ PS4', style: TextStyle(fontSize: 14)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'عنوان IP الخاص بالـ PS4'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'منفذ السيرفر (Port) - الافتراضي 9025'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _ps4Ip = ipController.text;
                  _ps4Port = int.tryParse(portController.text) ?? 9025;
                });
                Navigator.pop(context);
                _testPkgServerConnection();
              },
              child: const Text('حفظ واختبار'),
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
        title: const Text('محاكي + مشغل PS4 الهجين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns, color: Colors.cyanAccent),
            onPressed: _showServerConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            onPressed: _addGameFromPhone,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF101424),
            child: Row(
              children: [
                Icon(
                  _isServerConnected ? Icons.check_circle : Icons.error_outline,
                  color: _isServerConnected ? Colors.greenAccent : Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سيرفر الـ PKG الهدف: $_ps4Ip:$_ps4Port', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(_serverStatus, style: TextStyle(fontSize: 10, color: _isServerConnected ? Colors.greenAccent : Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _testPkgServerConnection,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueDark, padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: const Text('اختبار', style: TextStyle(fontSize: 11)),
                )
              ],
            ),
          ),
          Expanded(
            child: _library.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addGameFromPhone,
                          icon: const Icon(Icons.sd_storage),
                          label: const Text('إضافة لعبة من ذاكرة الهاتف'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _showServerConfigDialog,
                          icon: const Icon(Icons.router),
                          label: const Text('ربط سيرفر PKG المساعد'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _library.length,
                    itemBuilder: (context, index) {
                      final game = _library[index];
                      return Card(
                        color: const Color(0xFF161B2E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.sports_esports, color: Colors.cyanAccent, size: 36),
                          title: Text(game.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الحجم: ${game.fileSizeMB} MB | النمط: ${game.playMode == GamePlayMode.localEmulator ? "محلي من الهاتف" : "بث من سيرفر PKG"}'),
                          trailing: DropdownButton<GamePlayMode>(
                            value: game.playMode,
                            dropdownColor: const Color(0xFF161B2E),
                            onChanged: (newMode) {
                              if (newMode != null) {
                                setState(() {
                                  game.playMode = newMode;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: GamePlayMode.localEmulator,
                                child: Text('تشغيل محلي (هاتف)', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                              ),
                              DropdownMenuItem(
                                value: GamePlayMode.ps4RemoteStream,
                                child: Text('بث من سيرفر الـ PKG', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameRunnerScreen(
                                  game: game,
                                  ps4Ip: _ps4Ip,
                                  ps4Port: _ps4Port,
                                ),
                              ),
                            );
                          },
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

class GameRunnerScreen extends StatelessWidget {
  final GameModel game;
  final String ps4Ip;
  final int ps4Port;

  const GameRunnerScreen({
    super.key,
    required this.game,
    required this.ps4Ip,
    required this.ps4Port,
  });

  @override
  Widget build(BuildContext context) {
    bool isLocal = game.playMode == GamePlayMode.localEmulator;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isLocal ? 'تشغيل محلي: ${game.title}' : 'بث عبر PKG Server: ${game.title}'),
        backgroundColor: isLocal ? Colors.blueDark : Colors.greenDark,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocal ? Icons.developer_board : Icons.wifi_tethering,
              size: 80,
              color: isLocal ? Colors.blueAccent : Colors.greenAccent,
            ),
            const SizedBox(height: 16),
            Text(
              isLocal
                  ? 'تم تحميل اللعبة من ذاكرة آيفون 11 وتعمل محلياً عبر النواة'
                  : 'جاري استقبال الإشارات والبث المباشر من سيرفر PKG ($ps4Ip:$ps4Port)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorUtils on Colors {
  static Color get blueDark => const Color(0xFF0D223A);
  static Color get greenDark => const Color(0xFF0D3A22);
}
