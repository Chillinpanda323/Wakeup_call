import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playAlarmSound() async {
    if (!_isPlaying) {
      _isPlaying = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the sound
      await _audioPlayer.play(AssetSource('Russian.mp3')); // Play from assets
    }
  }

  static Future<void> stopAlarmSound() async {
    if (_isPlaying) {
      _isPlaying = false;
      await _audioPlayer.stop();
      await _audioPlayer.dispose(); // Add dispose to clean up resources
    }
  }

  // Add method to clean up resources
  static Future<void> dispose() async {
    await stopAlarmSound();
    await _audioPlayer.dispose();
  }
} 