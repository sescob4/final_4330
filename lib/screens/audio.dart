import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() => _instance;

  late final AudioPlayer player;

  AudioManager._internal() {
    player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await player.setSource(AssetSource('sound/back2.mp3'));
    await player.setReleaseMode(ReleaseMode.loop);
    await player.resume();
  }

  Future<void> toggleMute(bool mute) async {
    if (mute) {
      await player.pause();
    } else {
      await player.resume();
    }
  }

  Future<void> seekToStart() async {
    await player.seek(Duration.zero);
  }
}
