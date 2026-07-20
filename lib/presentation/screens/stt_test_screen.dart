import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SttTestScreen extends StatefulWidget {
  const SttTestScreen({super.key});

  @override
  State<SttTestScreen> createState() => _SttTestScreenState();
}

class _SttTestScreenState extends State<SttTestScreen> {
  final SpeechToText _speechTest = SpeechToText();
  bool _isInit = false;
  bool _isListening = false;
  String _words = "";
  String _status = "Belum diinisialisasi";
  String _selectedLocale = "id_ID";

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog("Halaman Test STT dibuka.");
  }

  void _addLog(String msg) {
    final time = DateTime.now().toString().split('.').first.split(' ').last;
    setState(() {
      _logs.insert(0, "[$time] $msg");
    });
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    _addLog("Status Izin Mikrofon: $status");
    if (status.isDenied) {
      _addLog("Meminta Izin Mikrofon...");
      final res = await Permission.microphone.request();
      _addLog("Hasil Permintaan Izin: $res");
    }
  }

  Future<void> _initStt() async {
    await _checkPermission();
    _addLog("Memulai inisialisasi SpeechToText...");
    try {
      final ok = await _speechTest.initialize(
        onError: (err) {
          _addLog("OnError: ${err.errorMsg} (Permanent: ${err.permanent})");
          setState(() {
            _status = "Error: ${err.errorMsg}";
            _isListening = false;
          });
        },
        onStatus: (stat) {
          _addLog("OnStatus: $stat");
          setState(() {
            _status = stat;
            if (stat == 'notListening' || stat == 'done') {
              _isListening = false;
            }
          });
        },
        debugLogging: true,
      );
      setState(() {
        _isInit = ok;
        _status = ok ? "Inisialisasi Sukses" : "Inisialisasi Gagal";
      });
      _addLog("Hasil Inisialisasi: $ok");
    } catch (e) {
      _addLog("Exception saat init: $e");
      setState(() {
        _status = "Exception: $e";
      });
    }
  }

  Future<void> _startListening() async {
    if (!_isInit) {
      _addLog("Gagal: STT belum diinisialisasi.");
      return;
    }
    _addLog("Mulai mendengarkan dengan Locale: $_selectedLocale...");
    setState(() {
      _isListening = true;
      _words = "";
    });

    try {
      await _speechTest.listen(
        onResult: (result) {
          _addLog("OnResult: words='${result.recognizedWords}' (final: ${result.finalResult})");
          setState(() {
            _words = result.recognizedWords;
          });
        },
        localeId: _selectedLocale,
        cancelOnError: false,
      );
    } catch (e) {
      _addLog("Exception saat listen: $e");
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    _addLog("Menghentikan pendengaran...");
    await _speechTest.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        title: const Text("Pemeriksa STT Terisolasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("STATUS MESIN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isListening ? "Mendengarkan" : "Standby",
                            style: TextStyle(color: _isListening ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Locale Config
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Locale Bahasa", style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _selectedLocale,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: "id_ID", child: Text("id_ID (Underscore)")),
                        DropdownMenuItem(value: "id-ID", child: Text("id-ID (Hyphen)")),
                        DropdownMenuItem(value: "en_US", child: Text("en_US (English)")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLocale = val);
                          _addLog("Bahasa diubah ke: $val");
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Speech Results
            const Text("HASIL SUARA DITERJEMAHKAN:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              minHeight: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _words.isEmpty ? "(Mulai bicara untuk melihat hasil di sini...)" : _words,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: _words.isEmpty ? Colors.grey : Colors.black87
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _initStt,
                    icon: const Icon(Icons.power_settings_new_rounded),
                    label: const Text("Init STT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_isListening ? "Stop" : "Listen"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Console Logs
            const Text("LOG KONSOL MESIN (TERBARU DI ATAS):", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[idx],
                        style: const TextStyle(
                          color: Color(0xFF00FF66),
                          fontFamily: 'Courier',
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
