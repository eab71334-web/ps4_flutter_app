import 'package:flutter/material.dart';
import 'http/http.dart' as http;

void main() {
  runApp(const PS4HybridApp());
}

class PS4HybridApp extends StatelessWidget {
  const PS4HybridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PS4 Hybrid Control',
      theme: ThemeData.dark(),
      home: const StreamScreen(),
    );
  }
}

class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.100');
  String _status = 'Disconnected';
  bool _isLoading = false;

  Future<void> _checkServerStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Connecting...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://${_ipController.text}:9025/status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _status = 'Connected: ${response.body}';
        });
      } else {
        setState(() {
          _status = 'Server Error (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection Failed: $e';
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
        title: const Text('PS4 Controller & Remote'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'PS4 IP Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkServerStatus,
              child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Connect to PS4'),
            ),
            const SizedBox(height: 24),
            Text(
              'Status:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
