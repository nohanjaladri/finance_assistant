import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService with ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> init() async {
    await _speech.initialize();
    await _tts.setLanguage("id-ID");
  }

  Future<void> startListening({
    required Function(String, bool) onResult,
  }) async {
    _isListening = true;
    notifyListeners();
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _isListening = false;
          notifyListeners();
        }
      },
      localeId: "id-ID",
    );
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
