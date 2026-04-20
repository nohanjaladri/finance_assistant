import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSttInitialized = false;

  // Variabel pengontrol suara (Untuk Settings Screen)
  bool _isTtsEnabled = true;

  // Getter
  bool get isTtsEnabled => _isTtsEnabled;

  // Fungsi toggle
  void toggleTts(bool value) {
    _isTtsEnabled = value;
    if (!_isTtsEnabled) stop();
    notifyListeners();
  }

  Future<void> init() async {
    _isSttInitialized = await _speechToText.initialize();

    // ==========================================
    // MAGIC TWEAK: MENGHILANGKAN KESAN ROBOTIK
    // ==========================================
    await _flutterTts.setLanguage("id-ID");

    // Menaikkan nada dasar (Pitch) ke 1.3 membuat suara wanita bawaan Android
    // terdengar lebih imut, ceria, dan tidak terlalu kaku.
    await _flutterTts.setPitch(1.3);

    // Memperlambat kecepatan bicara sedikit agar artikulasinya jelas
    await _flutterTts.setSpeechRate(0.45);
  }

  Future<void> speak(String text) async {
    // Jika TTS dimatikan di pengaturan, atau teks kosong, jangan bersuara
    if (!_isTtsEnabled || text.isEmpty) return;

    // Mesin bawaan OS akan langsung membaca teks secara offline
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void startListening({required Function(String, bool) onResult}) async {
    if (!_isSttInitialized) {
      _isSttInitialized = await _speechToText.initialize();
    }
    if (_isSttInitialized) {
      await stop(); // Suruh AI diam saat Anda mulai berbicara
      _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        localeId: 'id_ID',
      );
    }
  }
}
