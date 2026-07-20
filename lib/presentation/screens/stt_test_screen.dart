import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';

class SttTestScreen extends StatefulWidget {
  const SttTestScreen({super.key});

  @override
  State<SttTestScreen> createState() => _SttTestScreenState();
}

class _SttTestScreenState extends State<SttTestScreen> {
  final VoskFlutter _vosk = VoskFlutter.instance;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isInit = false;
  bool _isListening = false;
  String _words = "";
  String _status = "Model belum diunduh";

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog("Halaman Test STT (Vosk Offline) dibuka.");
    _checkModelStatus();
  }

  void _addLog(String msg) {
    final time = DateTime.now().toString().split('.').first.split(' ').last;
    setState(() {
      _logs.insert(0, "[$time] $msg");
    });
  }

  Future<String> _getModelPath() async {
    final tempDir = Directory.systemTemp;
    return "${tempDir.path}/vosk-model-small-id-0.3";
  }

  Future<void> _checkModelStatus() async {
    final path = await _getModelPath();
    final dir = Directory(path);
    if (await dir.exists()) {
      setState(() {
        _status = "Model offline tersedia. Siap di-Inisialisasi.";
      });
      _addLog("Model ditemukan di: $path");
    } else {
      setState(() {
        _status = "Model belum diunduh. Silakan unduh model (15MB).";
      });
      _addLog("Model tidak ditemukan. Diperlukan unduhan.");
    }
  }

  Future<void> _downloadAndUnzipModel() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _status = "Mengunduh model bahasa Indonesia (15MB)...";
    });
    _addLog("Memulai unduhan model...");

    final tempDir = Directory.systemTemp;
    final zipPath = "${tempDir.path}/vosk_model_id.zip";
    final destPath = tempDir.path;

    try {
      final dio = Dio();
      await dio.download(
        "https://alphacephei.com/vosk/models/vosk-model-small-id-0.3.zip",
        zipPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      _addLog("Unduhan selesai. Mengekstrak zip...");
      setState(() {
        _status = "Mengekstrak model...";
      });

      // Extract ZIP using archive package
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('$destPath/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('$destPath/$filename').createSync(recursive: true);
        }
      }

      // Cleanup ZIP file
      try {
        await File(zipPath).delete();
      } catch (_) {}

      _addLog("Ekstraksi selesai.");
      await _checkModelStatus();
    } catch (e) {
      _addLog("Gagal mengunduh/ekstrak: $e");
      setState(() {
        _status = "Gagal mengunduh model: $e";
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    _addLog("Izin Mikrofon: $status");
    if (status.isDenied) {
      _addLog("Meminta izin mikrofon...");
      await Permission.microphone.request();
    }
  }

  Future<void> _initVosk() async {
    await _checkPermission();
    final modelPath = await _getModelPath();
    
    _addLog("Menginisialisasi Model Vosk dari: $modelPath...");
    setState(() {
      _status = "Menginisialisasi mesin suara...";
    });

    try {
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!, 
        sampleRate: 16000,
      );
      
      // Setup recognizer options (optional, can enable grammar/words)
      _recognizer!.setWords(true);
      
      _speechService = await _vosk.createSpeechService(_recognizer!);
      
      // Bind listeners
      _speechService!.onPartial().listen((partial) {
        // Result is in JSON format from Vosk
        debugPrint("Vosk partial: $partial");
        // Extract partial text (regex or simple parse)
        final match = RegExp(r'"partial" : "([^"]*)"').firstMatch(partial);
        if (match != null) {
          setState(() {
            _words = match.group(1) ?? "";
          });
        }
      });

      _speechService!.onResult().listen((result) {
        debugPrint("Vosk result: $result");
        final match = RegExp(r'"text" : "([^"]*)"').firstMatch(result);
        if (match != null) {
          final recognizedText = match.group(1) ?? "";
          if (recognizedText.isNotEmpty) {
            _addLog("Final recognized: '$recognizedText'");
            setState(() {
              _words = recognizedText;
            });
          }
        }
      });

      setState(() {
        _isInit = true;
        _status = "Mesin Offline Siap";
      });
      _addLog("Inisialisasi Vosk Sukses.");
    } catch (e) {
      _addLog("Gagal init Vosk: $e");
      setState(() {
        _status = "Inisialisasi Gagal: $e";
      });
    }
  }

  Future<void> _startListening() async {
    if (!_isInit || _speechService == null) {
      _addLog("Gagal: Vosk belum diinisialisasi.");
      return;
    }

    _addLog("Mulai mendengarkan...");
    try {
      final success = await _speechService!.start();
      setState(() {
        _isListening = success;
        _words = "";
        _status = "Sedang mendengarkan suara Anda...";
      });
      _addLog("Hasil start: $success");
    } catch (e) {
      _addLog("Gagal start listening: $e");
    }
  }

  Future<void> _stopListening() async {
    _addLog("Menghentikan perekaman...");
    try {
      final success = await _speechService!.stop();
      setState(() {
        _isListening = false;
        _status = "Mesin Offline Siap";
      });
      _addLog("Hasil stop: $success");
    } catch (e) {
      _addLog("Gagal stop listening: $e");
    }
  }

  @override
  void dispose() {
    _speechService?.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        title: const Text("Vosk Offline STT Test", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text("STATUS OFFLINE ENGINE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
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
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (_isDownloading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                      const SizedBox(height: 4),
                      Text("Mengunduh: ${(_downloadProgress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Speech Results
            const Text("HASIL TRANSRIKPSI REAL-TIME:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _words.isEmpty ? "(Bicaralah di sini, Vosk akan menterjemahkan offline...)" : _words,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: _words.isEmpty ? Colors.grey : Colors.black87
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isInit) ...[
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadAndUnzipModel,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text("1. Unduh Model Bahasa (15MB)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _voskModelDownloaded() ? _initVosk : null,
                    icon: const Icon(Icons.power_settings_new_rounded),
                    label: const Text("2. Hubungkan & Inisialisasi Vosk"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.mic_off_rounded : Icons.mic_rounded),
                    label: Text(_isListening ? "Hentikan Perekaman" : "Mulai Perekaman"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Console Logs
            const Text("LOG PROSES VOSK OFFLINE:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
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

  bool _voskModelDownloaded() {
    return _status.contains("offline tersedia") || _status.contains("Mesin Offline");
  }
}
