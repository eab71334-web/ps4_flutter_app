import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

// ==========================================
// 1. شاشة مكتبة الألعاب ومتصفح الملفات الحقيقي
// ==========================================
class GameLibraryScreen extends StatefulWidget {
  const GameLibraryScreen({super.key});

  @override
  State<GameLibraryScreen> createState() => _GameLibraryScreenState();
}

class _GameLibraryScreenState extends State<GameLibraryScreen> {
  final List<File> _gameFiles = [];

  void _openFilePicker() async {
    HapticFeedback.selectionClick();
    final Directory initialDir = Directory.current;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FileBrowserDialog(
        initialDirectory: initialDir,
        onFileSelected: (File file) {
          setState(() {
            if (!_gameFiles.any((f) => f.path == file.path)) {
              _gameFiles.add(file);
            }
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إضافة: ${file.path.split('/').last}'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاكي PS4 - مكتبة الألعاب', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF12121A),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, color: Colors.cyanAccent),
            onPressed: _openFilePicker,
            tooltip: 'تصفح وإضافة لعبة',
          ),
        ],
      ),
      body: _gameFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_esports, size: 90, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد ألعاب مضافة بعد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر ملف اللعبة من ذاكرة الهاتف (.pkg / .iso / .bin)',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openFilePicker,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('تصفح ملفات الهاتف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _gameFiles.length,
              itemBuilder: (context, index) {
                final file = _gameFiles[index];
                final fileName = file.path.split('/').last;
                return Card(
                  color: const Color(0xFF1E1E2A),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.gamepad, color: Colors.white),
                    ),
                    title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(file.path, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 40),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmulatorScreen(gameName: fileName),
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

// ==========================================
// 2. نافذة تصفح الملفات من الذاكرة
// ==========================================
class FileBrowserDialog extends StatefulWidget {
  final Directory initialDirectory;
  final Function(File) onFileSelected;

  const FileBrowserDialog({
    super.key,
    required this.initialDirectory,
    required this.onFileSelected,
  });

  @override
  State<FileBrowserDialog> createState() => _FileBrowserDialogState();
}

class _FileBrowserDialogState extends State<FileBrowserDialog> {
  late Directory _currentDir;
  List<FileSystemEntity> _entities = [];

  @override
  void initState() {
    super.initState();
    _currentDir = widget.initialDirectory;
    _loadDirectoryContents();
  }

  void _loadDirectoryContents() {
    try {
      setState(() {
        _entities = _currentDir.listSync().where((e) {
          if (e is Directory) return true;
          final path = e.path.toLowerCase();
          return path.endsWith('.pkg') || path.endsWith('.iso') || path.endsWith('.bin') || path.endsWith('.elf');
        }).toList();
      });
    } catch (_) {
      setState(() {
        _entities = [];
      });
    }
  }

  void _navigateTo(Directory dir) {
    setState(() {
      _currentDir = dir;
    });
    _loadDirectoryContents();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentDir.parent.path != _currentDir.path)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _navigateTo(_currentDir.parent),
                ),
              Expanded(
                child: Text(
                  _currentDir.path,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _entities.isEmpty
                ? const Center(child: Text('لا توجد ملفات ألعاب مدعومة في هذا المجلد'))
                : ListView.builder(
                    itemCount: _entities.length,
                    itemBuilder: (context, index) {
                      final entity = _entities[index];
                      final name = entity.path.split('/').last;
                      final isDir = entity is Directory;

                      return ListTile(
                        leading: Icon(
                          isDir ? Icons.folder : Icons.sports_esports,
                          color: isDir ? Colors.amber : Colors.cyanAccent,
                        ),
                        title: Text(name),
                        onTap: () {
                          if (isDir) {
                            _navigateTo(entity);
                          } else if (entity is File) {
                            widget.onFileSelected(entity);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. شاشة المحاكي الرئيسية واختيارات الإعدادات
// ==========================================
class EmulatorScreen extends StatefulWidget {
  final String gameName;
  const EmulatorScreen({super.key, required this.gameName});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> {
  // إعدادات المحاكي
  double _buttonOpacity = 0.45;
  String _resolution = '1080p';
  int _targetFPS = 60;
  String _lastInput = 'المحاكي جاهز للعب...';

  void _triggerInput(String label) {
    HapticFeedback.lightImpact(); // اهتزاز عند التفاعل
    setState(() {
      _lastInput = 'الزر المضغوط: $label';
    });
  }

  void _openSettingsDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => StatefulWidget(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Row(
              children: [
                Icon(Icons.settings, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('إعدادات المحاكي (Settings)'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('شفافية الأزرار (Button Opacity):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _buttonOpacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: Colors.blueAccent,
                    label: '${(_buttonOpacity * 100).round()}%',
                    onChanged: (val) {
                      setModalState(() => _buttonOpacity = val);
                      setState(() => _buttonOpacity = val);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  const Text('دقة العرض (Resolution):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: ['720p', '1080p'].map((res) {
                      return Expanded(
                        child: RadioListTile<String>(
                          title: Text(res, style: const TextStyle(fontSize: 12)),
                          value: res,
                          groupValue: _resolution,
                          onChanged: (val) {
                            setModalState(() => _resolution = val!);
                            setState(() => _resolution = val!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(color: Colors.white24),
                  const Text('معدل الإطارات (Target FPS):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [30, 60].map((fps) {
                      return Expanded(
                        child: RadioListTile<int>(
                          title: Text('$fps FPS', style: const TextStyle(fontSize: 12)),
                          value: fps,
                          groupValue: _targetFPS,
                          onChanged: (val) {
                            setModalState(() => _targetFPS = val!);
                            setState(() => _targetFPS = val!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تم', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // شاشة عرض اللعبة الرئيسية
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.gameName,
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الدقة: $_resolution | السرعة: $_targetFPS FPS',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 15),
                  Text(
                    _lastInput,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // أزرار الأكتاف العلوي (L1, L2, R1, R2)
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildButton('L2', () => _triggerInput('L2'), width: 55, height: 35),
                    const SizedBox(width: 8),
                    _buildButton('L1', () => _triggerInput('L1'), width: 55, height: 35),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('R1', () => _triggerInput('R1'), width: 55, height: 35),
                    const SizedBox(width: 8),
                    _buildButton('R2', () => _triggerInput('R2'), width: 55, height: 35),
                  ],
                ),
              ],
            ),
          ),

          // شريط الأزرار الوسطى والإعدادات (Share / Options / Settings / Exit)
          Positioned(
            top: 15,
            left: MediaQuery.of(context).size.width / 2 - 110,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
                _buildButton('SHARE', () => _triggerInput('SHARE'), width: 50, height: 28, fontSize: 10),
                const SizedBox(width: 6),
                _buildButton('PS', () => _triggerInput('PS'), width: 35, height: 28, fontSize: 10, color: Colors.blue),
                const SizedBox(width: 6),
                _buildButton('OPTIONS', () => _triggerInput('OPTIONS'), width: 55, height: 28, fontSize: 10),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.cyanAccent),
                  onPressed: _openSettingsDialog,
                ),
              ],
            ),
          ),

          // D-Pad + Left Joystick (L3) - الجهة اليسرى
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // D-Pad
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton('▲', () => _triggerInput('D-UP')),
                    Row(
                      children: [
                        _buildButton('◄', () => _triggerInput('D-LEFT')),
                        const SizedBox(width: 35),
                        _buildButton('►', () => _triggerInput('D-RIGHT')),
                      ],
                    ),
                    _buildButton('▼', () => _triggerInput('D-DOWN')),
                  ],
                ),
                const SizedBox(width: 25),
                // Left Joystick (L3)
                VirtualJoystick(
                  label: 'L3',
                  opacity: _buttonOpacity,
                  onDirectionChanged: (x, y) => _triggerInput('L-Stick ($x, $y)'),
                  onPressed: () => _triggerInput('L3 Press'),
                ),
              ],
            ),
          ),

          // Action Buttons + Right Joystick (R3) - الجهة اليمنى
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Right Joystick (R3)
                VirtualJoystick(
                  label: 'R3',
                  opacity: _buttonOpacity,
                  onDirectionChanged: (x, y) => _triggerInput('R-Stick ($x, $y)'),
                  onPressed: () => _triggerInput('R3 Press'),
                ),
                const SizedBox(width: 25),
                // Triangle, Square, Circle, Cross
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton('△', () => _triggerInput('TRIANGLE'), textColor: Colors.greenAccent),
                    Row(
                      children: [
                        _buildButton('□', () => _triggerInput('SQUARE'), textColor: Colors.pinkAccent),
                        const SizedBox(width: 35),
                        _buildButton('○', () => _triggerInput('CIRCLE'), textColor: Colors.redAccent),
                      ],
                    ),
                    _buildButton('✕', () => _triggerInput('CROSS'), textColor: Colors.blueAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء أزرار اللمس الشفافة التفاعلية
  Widget _buildButton(
    String label,
    VoidCallback onTap, {
    double width = 50,
    double height = 50,
    double fontSize = 18,
    Color textColor = Colors.white,
    Color color = Colors.white10,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(_buttonOpacity),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(_buttonOpacity), width: 1.2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. مكون عصا التحكم التناظرية (360 Joystick)
// ==========================================
class VirtualJoystick extends StatefulWidget {
  final String label;
  final double opacity;
  final Function(String x, String y) onDirectionChanged;
  final VoidCallback onPressed;

  const VirtualJoystick({
    super.key,
    required this.label,
    required this.opacity,
    required this.onDirectionChanged,
    required this.onPressed,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _dragOffset = Offset.zero;
  final double _radius = 45.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onPressed();
      },
      onPanUpdate: (details) {
        final newOffset = _dragOffset + details.delta;
        final distance = newOffset.distance;

        setState(() {
          if (distance <= _radius) {
            _dragOffset = newOffset;
          } else {
            _dragOffset = Offset.fromDirection(newOffset.direction, _radius);
          }
        });

        HapticFeedback.selectionClick();
        final normalizedX = (_dragOffset.dx / _radius).toStringAsFixed(2);
        final normalizedY = (_dragOffset.dy / _radius).toStringAsFixed(2);
        widget.onDirectionChanged(normalizedX, normalizedY);
      },
      onPanEnd: (_) {
        setState(() {
          _dragOffset = Offset.zero;
        });
        widget.onDirectionChanged('0.00', '0.00');
      },
      child: Container(
        width: _radius * 2,
        height: _radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(widget.opacity * 0.3),
          border: Border.all(color: Colors.white.withOpacity(widget.opacity), width: 1.5),
        ),
        child: Center(
          child: Transform.translate(
            offset: _dragOffset,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(widget.opacity * 0.8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
