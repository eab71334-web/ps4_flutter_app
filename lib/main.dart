import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const PS4HybridEngineApp());
}

class PS4HybridEngineApp extends StatelessWidget {
  const PS4HybridEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PS4 Hybrid Engine & Controller',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090C15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF101424),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedModeIndex = 0; // 0: Remote Stream, 1: Local Emulator Engine
  String ps4Ip = "172.20.10.2";
  String goldHenId = "57616861622d4c69";
  String pairingCode = "849201";

  List<Map<String, dynamic>> connectedDevices = [
    {"name": "iPhone 11 (Host Device)", "ip": "172.20.10.3", "status": "نشط (Master)", "allowed": true},
    {"name": "Samsung Galaxy A05s", "ip": "172.20.10.5", "status": "انتظار الموافقة", "allowed": false},
  ];

  void _showDevicesManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulWidget(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF101424),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.devices, color: Color(0xFF00E676)),
              SizedBox(width: 10),
              Text('إدارة الأجهزة والأمان', style: TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('كود اقتران الجهاز (Pairing Code): $pairingCode',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                        onPressed: () {
                          setDialogState(() {
                            pairingCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
                          });
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('الأجهزة المتصلة حالياً بالـ PS4 Server:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: connectedDevices.length,
                    itemBuilder: (context, index) {
                      final dev = connectedDevices[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(dev['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text('IP: ${dev['ip']} | ${dev['status']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          trailing: Switch(
                            value: dev['allowed'],
                            activeColor: const Color(0xFF00E676),
                            onChanged: (val) {
                              setDialogState(() {
                                dev['allowed'] = val;
                                dev['status'] = val ? "نشط" : "تم الإيقاف";
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        ),
      ),
    );
  }

  void _showInstallPkgDialog() {
    TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101424),
        title: Row(
          children: const [
            Icon(Icons.download_for_offline, color: Color(0xFF00E676)),
            SizedBox(width: 8),
            Text('تنصيب PKG تلقائياً على PS4', style: TextStyle(fontSize: 15, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل رابط ملف الـ PKG أو اختره من ذاكرة الهاتف لإرساله وتثبيته مباشرة على البلايستيشن:',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'http://172.20.10.3/game.pkg',
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري إرسال أمر التثبيت التلقائي إلى الـ PS4 Host...')),
              );
            },
            child: const Text('بدء التثبيت عن بُعد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.install_mobile, color: Color(0xFF00E676)),
            tooltip: 'تنصيب PKG تلقائياً',
            onPressed: _showInstallPkgDialog,
          ),
          IconButton(
            icon: const Icon(Icons.security, color: Colors.blueAccent),
            tooltip: 'إدارة الأجهزة المتصلة والكود',
            onPressed: _showDevicesManagementDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector Bar for Mode switching
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF101424),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedModeIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedModeIndex == 0 ? const Color(0xFF00E676) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'بث عن بعد (PS4 Remote)',
                          style: TextStyle(
                            color: _selectedModeIndex == 0 ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedModeIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedModeIndex == 1 ? const Color(0xFF2979FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'تشغيل محلي (Local Engine)',
                          style: TextStyle(
                            color: _selectedModeIndex == 1 ? Colors.white : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status & Information Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black26,
            child: Row(
              children: [
                Icon(_selectedModeIndex == 0 ? Icons.cast_connected : Icons.phone_iphone,
                    color: _selectedModeIndex == 0 ? const Color(0xFF00E676) : Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedModeIndex == 0
                        ? 'الهدف: $ps4Ip | الحجم: 272 MB PKG | جاهز للبث'
                        : 'المحاكي المحلي: معالج iOS نشط | الألعاب الخفيفة والمترجمة',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Game Launch Card
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StreamScreen(
                        ps4Ip: ps4Ip,
                        isLocalMode: _selectedModeIndex == 1,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101424),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _selectedModeIndex == 0 ? const Color(0xFF00E676).withOpacity(0.4) : Colors.blueAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedModeIndex == 0 ? Icons.sports_esports : Icons.videogame_asset,
                        size: 45,
                        color: _selectedModeIndex == 0 ? const Color(0xFF00E676) : Colors.blueAccent,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '[PS4ID]-Runner 2 -\nFuture Legend of Rhythm Alien',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedModeIndex == 0 ? '[CUSA05730] [1.01]' : 'Local Internal Build',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
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
  final bool isLocalMode;

  const StreamScreen({super.key, required this.ps4Ip, required this.isLocalMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070E),
      body: SafeArea(
        child: Stack(
          children: [
            // Performance Overlay Box
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isLocalMode ? Colors.blueAccent : const Color(0xFF00E676)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      isLocalMode ? 'الوضع: تشغيل محلي على الهاتف' : 'زمن الاستجابة (Latency): 15 ms',
                      style: TextStyle(
                        color: isLocalMode ? Colors.blueAccent : const Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('FPS: 59.4 | Vulkan Engine', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      isLocalMode ? 'RAM: 4064 MB / 8 GB (Local CPU)' : 'PKG: 272 MB | PS4 Host Active',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
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

            // Center Display Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLocalMode ? Icons.important_devices : Icons.cast_connected,
                    size: 60,
                    color: isLocalMode ? Colors.blueAccent : const Color(0xFF00E676),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '[PS4ID]-Runner 2 - Future Legend of Rhythm Alien\n[CUSA05730] [1.01]',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLocalMode ? 'بيئة اللعب نشطة: Local Engine 1080p' : '(FHD) pعنوان الجهاز: $ps4Ip | الدقة: 1080',
                    style: TextStyle(color: isLocalMode ? Colors.blueAccent : const Color(0xFF00E676), fontSize: 11),
                  ),
                ],
              ),
            ),

            // D-Pad Controller
            Positioned(
              bottom: 25,
              left: 20,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                child: const Icon(Icons.open_with, color: Colors.white70, size: 30),
              ),
            ),

            // PS Buttons Matrix
            Positioned(
              bottom: 20,
              right: 25,
              child: Column(
                children: [
                  const Icon(Icons.change_history, color: Color(0xFF00E676), size: 22),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
