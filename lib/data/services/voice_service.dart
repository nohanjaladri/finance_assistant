import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'backend_ai_service.dart';

class VoiceService with ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool get isListening => _isListening;
  
  String? _audioFilePath;

  Future<void> init() async {
    await _tts.setLanguage("id-ID");
  }

  Future<void> startListening({
    required Function(String, bool) onResult,
  }) async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('VoiceService: Microphone permission denied');
        return;
      }

      _isListening = true;
      notifyListeners();

      final tempDir = Directory.systemTemp;
      _audioFilePath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      debugPrint('VoiceService: Starting recording to $_audioFilePath');
      
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), 
        path: _audioFilePath!,
      );
    } catch (e) {
      debugPrint('VoiceService startListening exception: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListeningAndTranscribe({
    required Function(String, bool) onResult,
  }) async {
    try {
      debugPrint('VoiceService: Stopping recording...');
      final path = await _recorder.stop();
      _isListening = false;
      notifyListeners();

      if (path != null) {
        onResult("Menerjemahkan suara...", false); // temporary status
        final text = await BackendAiService().transcribeAudio(path);
        if (text != null && text.trim().isNotEmpty) {
          onResult(text, true);
        } else {
          onResult("Gagal menerjemahkan suara.", true);
        }
      }
    } catch (e) {
      debugPrint('VoiceService stopListening exception: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _recorder.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }
}
