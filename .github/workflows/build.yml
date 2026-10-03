import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const PS4EmulatorApp());
}

class PS4EmulatorApp extends StatelessWidget {
  const PS4EmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محاكي وبث PS4 المهكر',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090C15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF101424),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String ps4Ip = "172.20.10.2";
  String goldHenId = "57616861622d4c69";
  bool isConnected = true;

  void _showConnectionDialog() {
    TextEditingController ipController = TextEditingController(text: ps4Ip);
    TextEditingController idController = TextEditingController(text: goldHenId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.router, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text('ربط جهاز PS4 المهكر', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Text('عنوان IP الخاص الـ PS4 (المحلي أو P2P Tunnel)', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSideColor(Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSideColor(Color(0xFF00E676))),
              ),
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('معرف الـ GoldHEN / PSN Account ID', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            TextField(
              controller: idController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSideColor(Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSideColor(Color(0xFF00E676))),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C2541),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                setState(() {
                  ps4Ip = ipController.text;
                  goldHenId = idController.text;
                  isConnected = true;
                });
                Navigator.pop(context);
              },
              child: const Text('حفظ واختبار الاتصال', style: TextStyle(color: Color(0xFF2979FF))),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('محاكي وبث PS4 المهكر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast_connected, color: Color(0xFF00E676)),
            onPressed: _showConnectionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.blueAccent),
            onPressed: _showConnectionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black26,
            child: Row(
              children: [
                const Icon(Icons.cast, color: Color(0xFF00E676), size: 18),
                const SizedBox(width: 8),
                Text('الهدف: $ps4Ip | الحالة: جاهز للبث المباشر جهاز PS4', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                TextButton(
                  onPressed: _showConnectionDialog,
                  child: const Text('تغيير IP', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StreamScreen(ps4Ip: ps4Ip)),
                  );
                },
                child: Container(
                  width: 160,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101424),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sports_esports, size: 40, color: Color(0xFF00E676)),
                      SizedBox(height: 12),
                      Text(
                        '[PS4ID]-Runner 2 -\nFuture Legend of Rhyt...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      SizedBox(height: 6),
                      Text('CUSA05730', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamScreen extends StatelessWidget {
  final String ps4Ip;
  const StreamScreen({super.key, required this.ps4Ip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070E),
      body: SafeArea(
        child: Stack(
          children: [
            // Performance Overlay Top Left
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: const [
                    Text('زمن الاستجابة (Latency): 15 ms', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('معدل الإطارات FPS: 59.4', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    SizedBox(height: 2),
                    Text('حجم ملف الـ PKG: 272 MB', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ),

            // Top Right Power Button
            Positioned(
              top: 15,
              right: 15,
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Center Info & Game Stream Display
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cast_connected, size: 60, color: Color(0xFF00E676)),
                  const SizedBox(height: 15),
                  const Text(
                    '[PS4ID]-Runner 2 - Future Legend of Rhythm Alien\n[CUSA05730] [1.01]',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '(FHD) pعنوان الجهاز: $ps4Ip | الدقة: 1080',
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 11),
                  ),
                ],
              ),
            ),

            // Bottom Left D-Pad Control Visual
            Positioned(
              bottom: 25,
              left: 20,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_with, color: Colors.white70, size: 30),
              ),
            ),

            // Bottom Right PS Shapes (Triangle, Circle, Cross, Square)
            Positioned(
              bottom: 20,
              right: 25,
              child: Column(
                children: [
                  const Icon(Icons.change_history, color: Color(0xFF00E676), size: 22),
                  Row(
                    children: const [
                      Icon(Icons.crop_square, color: Colors.pinkAccent, size: 22),
                      SizedBox(width: 15),
                      Icon(Icons.panorama_fish_eye, color: Colors.redAccent, size: 22),
                    ],
                  ),
                  const Icon(Icons.close, color: Colors.blueAccent, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
