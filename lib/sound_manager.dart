import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'extension.dart';

/// For TTS
class TtsManager {

  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();

  String ttsLocale() =>
      // (context.lang() == "ja") ? "ja-JP":
      // (context.lang() == "zh") ? "zh-CN":
      // (context.lang() == "ko") ? "ko-KR":
      // (context.lang() == "es") ? "es-ES":
      "en-US";

  String androidVoiceName() =>
      // (context.lang() == "ja") ? "ja-JP-language":
      // (context.lang() == "zh") ? "zh-CN-language":
      // (context.lang() == "ko") ? "ko-KR-language":
      // (context.lang() == "es") ? "es-ES-language":
      "en-US-language";

  String iOSVoiceName() =>
      // (context.lang() == "ja") ? "Kyoko":
      // (context.lang() == "zh") ? "婷婷":
      // (context.lang() == "ko") ? "유나":
      // (context.lang() == "es") ? "Mónica":
      "Samantha";

  String defaultVoiceName() =>
      (Platform.isIOS || Platform.isMacOS) ? iOSVoiceName(): androidVoiceName();

  Future<void> setTtsVoice() async {
    final voices = await flutterTts.getVoices;
    List<dynamic> localFemaleVoices = (Platform.isIOS || Platform.isMacOS) ? voices.where((voice) {
      final isLocalMatch = voice['locale'].toString().contains(ttsLocale());
      final isFemale = voice['gender'].toString().contains('female');
      return isLocalMatch && isFemale;
    }).toList(): [];
    "localFemaleVoices: $localFemaleVoices".debugPrint();
    if (context.mounted) {
      final voiceName = (localFemaleVoices.isNotEmpty) ? localFemaleVoices[0]['name']: defaultVoiceName();
      final voiceLocale = (localFemaleVoices.isNotEmpty) ? localFemaleVoices[0]['locale']: ttsLocale();
      final result = await flutterTts.setVoice({'name': voiceName, 'locale': voiceLocale,});
      "setVoice: $voiceName, result: $result".debugPrint();
    }
  }

  Future<void> speakText(String text, bool isSoundOn) async {
    if (isSoundOn) {
      await flutterTts.stop();
      await flutterTts.speak(text);
      text.debugPrint();
    } else {
      "No sound setting".debugPrint();
    }
  }

  Future<void> stopTts() async {
    await flutterTts.stop();
    "Stop TTS".debugPrint();
  }

  Future<void> initTts() async {
    await flutterTts.setSharedInstance(true);
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ]
      );
    }
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.awaitSynthCompletion(true);
    // if (context.mounted) await flutterTts.setLanguage(context.lang());
    // if (context.mounted) await flutterTts.isLanguageAvailable(context.lang());
    if (context.mounted) await setTtsVoice();
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(0.5);
  }
}

/// Audio via just_audio (audioplayers breaks under AGP 9). Index 0 is the looping
/// music, index 1 the one shot button sound; two players keep an effect from cutting the loop
class AudioManager {

  final List<AudioPlayer> audioPlayers;

  static const audioPlayerNumber = 2;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());

  bool isPlaying(int index) => audioPlayers[index].playing;
  String playerTitle(int index) => "${["music sound", "button sound"][index]}Player";

  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
    required isSound,
  }) async {
    if (isSound) {
      final player = audioPlayers[index];
      // Stop first: setAsset on a playing source keeps the old position
      if (player.playing) await player.stop();
      await player.setVolume(volume);
      await player.setLoopMode(LoopMode.one);
      await player.setAsset(asset);
      // Not awaited: play() completes only when playback ends, and a looping
      // source never does, so awaiting would block for the whole loop
      player.play();
      "Loop ${playerTitle(index)}: playing=${player.playing}".debugPrint();
    } else {
      "No sound setting".debugPrint();
    }
  }

  Future<void> playEffectSound({
    required int index,
    required String asset,
    required double volume,
    required isSound,
  }) async {
    if (isSound) {
      final player = audioPlayers[index];
      if (player.playing) await player.stop();
      await player.setVolume(volume);
      await player.setLoopMode(LoopMode.off);
      await player.setAsset(asset);
      // Not awaited: play() completes when the clip ends, and a button sound
      // must not block the tap handler for its whole duration
      player.play();
      "Play ${playerTitle(index)}".debugPrint();
    } else {
      "No sound setting".debugPrint();
    }
  }

  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: playing=${audioPlayers[index].playing}".debugPrint();
  }

  Future<void> stopAll() async {
    for (final player in audioPlayers) {
      try {
        if (player.playing) {
          await player.stop();
          "Stop all players".debugPrint();
        }
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    for (final player in audioPlayers) {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
