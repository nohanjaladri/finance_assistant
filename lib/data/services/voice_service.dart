import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;

  // FITUR BARU: Status aktif/mati suara TTS
  bool _isTtsEnabled = true;
  bool get isTtsEnabled => _isTtsEnabled;

  Future<void> init() async {
    await _speechToText.initialize();
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Memuat pengaturan terakhir dari memori HP
    final prefs = await SharedPreferences.getInstance();
    _isTtsEnabled = prefs.getBool('tts_enabled') ?? true;
  }

  // FITUR BARU: Fungsi untuk mengubah status suara dari Pengaturan
  Future<void> toggleTts(bool value) async {
    _isTtsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', value);
    if (!value) stop(); // Jika dimatikan saat sedang bicara, langsung diam
  }

  void startListening({required Function(String, bool) onResult}) async {
    if (!_speechToText.isAvailable) return;
    _isListening = true;
    notifyListeners();

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _isListening = false;
          notifyListeners();
        }
      },
      localeId: "id_ID",
    );
  }

  void stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    // FITUR BARU: Cek gembok TTS sebelum bersuara
    if (!_isTtsEnabled) return;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
