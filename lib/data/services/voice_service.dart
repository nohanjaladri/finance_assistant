import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService with ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool get isListening => _isListening;
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      _isInitialized = await _speech.initialize(
        debugLogging: true,
        onError: (errorNotification) {
          debugPrint('SpeechToText onError: ${errorNotification.errorMsg} - permanent: ${errorNotification.permanent}');
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('SpeechToText onStatus: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
      debugPrint('SpeechToText initialized successfully: $_isInitialized');
      await _tts.setLanguage("id-ID");
    } catch (e) {
      debugPrint('SpeechToText initialization exception: $e');
    }
  }

  Future<void> startListening({
    required Function(String, bool) onResult,
  }) async {
    if (!_isInitialized) {
      debugPrint('SpeechToText not initialized. Re-initializing...');
      await init();
    }

    _isListening = true;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          debugPrint('SpeechToText result: "${result.recognizedWords}" (final: ${result.finalResult})');
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _isListening = false;
            notifyListeners();
          }
        },
        localeId: "id-ID", // Force Indonesian locale so it doesn't default to system locale (e.g. en_US)
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('SpeechToText listen exception: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
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
