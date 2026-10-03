import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PS4HybridApp());
}

class PS4HybridApp extends StatelessWidget {
  const PS4HybridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PS4 Remote & Cloud Portal',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00439C),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = '';
  List<dynamic> _gamesList = [];

  // التحقق من صحة عنوان الـ IP قبل إرسال الطلب
  bool _isValidIP(String ip) {
    final regExp = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    return regExp.hasMatch(ip);
  }

  Future<void> _connectToPS4() async {
    final ip = _ipController.text.trim();
    if (!_isValidIP(ip)) {
      setState(() {
        _statusMessage = 'يرجى إدخال عنوان IP صحيح (مثال: 192.168.1.10)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري الاتصال بجهاز البلايستيشن...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://$ip:9025/api/games'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isConnected = true;
          _gamesList = data['games'] ?? [];
          _statusMessage = 'تم الاتصال بنجاح!';
        });
      } else {
        setState(() {
          _statusMessage = 'فشل الاتصال: رمز الاستجابة ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'تعذر الاتصال. تأكد من تشغيل التطبيق في البلايستيشن وأن الجهازين على نفس الشبكة.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PS4 Remote & Cloud Hub'),
        backgroundColor: const Color(0xFF00439C),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isConnected ? _buildDashboard() : _buildPairingView(),
      ),
    );
  }

  // واجهة الاقتران وإدخال البيانات
  Widget _buildPairingView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.tv_rounded, size: 80, color: Color(0xFF00439C)),
          const SizedBox(height: 16),
          const Text(
            'اقتران جهاز PS4',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'قم بتشغيل التطبيق على البلايستيشن وادخل عنوان الـ IP الموضّح على الشاشة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عنوان PS4 IP',
              hintText: '192.168.1.X',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.wifi),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'رمز الاقتران (PIN Code)',
              hintText: '123456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _connectToPS4,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00439C),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('ربط الجهاز والاتصال', style: TextStyle(fontSize: 16)),
          ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // واجهة التحكم ومكتبة الألعاب بعد الاتصال
  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'مكتبة ألعاب PS4',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _connectToPS4,
            )
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _gamesList.isEmpty
              ? const Center(child: Text('لا توجد ألعاب متوفرة أو جاري التحميل...'))
              : ListView.builder(
                  itemCount: _gamesList.length,
                  itemBuilder: (context, index) {
                    final game = _gamesList[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.sports_esports, color: Color(0xFF00439C)),
                        title: Text(game['name'] ?? 'Game Title'),
                        subtitle: Text('Title ID: ${game['title_id']}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تشغيل ${game['name']}...')),
                            );
                          },
                          child: const Text('تشغيل'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
