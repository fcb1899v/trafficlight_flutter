import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'extension.dart';

/// For TTS
class TtsManager {

  final BuildContext context;
  TtsManager({required this.context});

  final FlutterTts flutterTts = FlutterTts();

  String normalFont() =>
      (context.lang() == "ja") ? "notoJP":
      // (context.lang() == "zh") ? "notoSC":
      // (context.lang() == "ko") ? "bmDohyeon":
      "roboto";
  String ttsLocale() =>
      (context.lang() == "ja") ? "ja-JP":
      // (context.lang() == "zh") ? "zh-CN":
      // (context.lang() == "ko") ? "ko-KR":
      // (context.lang() == "es") ? "es-ES":
      "en-US";

  String androidVoiceName() =>
      (context.lang() == "ja") ? "ja-JP-language":
      // (context.lang() == "zh") ? "zh-CN-language":
      // (context.lang() == "ko") ? "ko-KR-language":
      // (context.lang() == "es") ? "es-ES-language":
      "en-US-language";

  String iOSVoiceName() =>
      (context.lang() == "ja") ? "Kyoko":
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
    if (context.mounted) await flutterTts.setLanguage(context.lang());
    if (context.mounted) await flutterTts.isLanguageAvailable(context.lang());
    if (context.mounted) await setTtsVoice();
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(0.5);
  }
}

/// For Audio
class AudioManager {

  final List<AudioPlayer> audioPlayers;

  static const audioPlayerNumber = 2;
  AudioManager() : audioPlayers = List.generate(audioPlayerNumber, (_) => AudioPlayer());
  PlayerState playerState(int index) => audioPlayers[index].state;
  String playerTitle(int index) => "${["music sound", "button sound"][index]}Player";

  Future<void> playLoopSound({
    required int index,
    required String asset,
    required double volume,
    required isSound,
  }) async {
    if (isSound) {
      final player = audioPlayers[index];
      await player.setVolume(volume);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource(asset));
      "Loop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
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
      await player.setVolume(volume);
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(asset));
      "Play ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
    } else {
      "No sound setting".debugPrint();
    }
  }

  Future<void> stopSound(int index) async {
    await audioPlayers[index].stop();
    "Stop ${playerTitle(index)}: ${audioPlayers[index].state}".debugPrint();
  }

  Future<void> stopAll() async {
    for (final player in audioPlayers) {
      try {
        if (player.state == PlayerState.playing) {
          await player.stop();
          "Stop all players".debugPrint();
        }
      } catch (_) {}
    }
  }
}