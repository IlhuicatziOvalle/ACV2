import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final TtsService instance = TtsService._init();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService._init();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("es-ES"); // Default to Spanish
      await _flutterTts.setSpeechRate(0.5); // Normal speed
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Handle completion
      _flutterTts.setCompletionHandler(() {
        debugPrint("TTS Complete");
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("Error initializing TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    
    try {
      await _flutterTts.stop(); // Stop any previous speech
      if (text.isNotEmpty) {
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint("Error speaking: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Error stopping TTS: $e");
    }
  }
}
