import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'common_extension.dart';
import 'constant.dart';

///App Tracking Transparency
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}

class AudioPlayerManager {
  // シングルトンインスタンス
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  final List<AudioPlayer> audioPlayers = [];
  // 4つの AudioPlayer インスタンスを初期化
  AudioPlayerManager._internal() {
    for (int i = 0; i < audioPlayerNumber; i++) {
      audioPlayers.add(AudioPlayer());
    }
  }
  /// 全ての AudioPlayer を dispose する
  Future<void> disposeAll() async {
    for (var player in audioPlayers) {
      try {
        await player.dispose();
      } catch (e) {
        'Error disposing AudioPlayer: $e'.debugPrint();
      }
    }
  }
}

// アプリが終了する際に disposeAll を呼び出す
void handleLifecycleChange(AppLifecycleState state) {
  if (state == AppLifecycleState.detached) {
    AudioPlayerManager().disposeAll();
  }
}