import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Handles base64 WAV audio → temp file → playback via just_audio
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  bool get isPlaying => _player.playing;

  /// Decode base64 audio, write to temp file, play it.
  Future<void> playBase64Audio(String base64Audio) async {
    if (base64Audio.isEmpty) return;

    await stop();

    final bytes = base64Decode(base64Audio);
    final tmpDir = await getTemporaryDirectory();
    final file = File(
        '${tmpDir.path}/medivoice_tts_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(bytes);

    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  void dispose() {
    _player.dispose();
  }
}
