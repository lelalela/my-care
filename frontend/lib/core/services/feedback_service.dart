import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// 운동 완료 시 진동 및 축하 효과음 알림 서비스
class FeedbackService {
  FeedbackService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  /// 목표 시간 도달 / 운동 완료 시 진동 및 완료 팡파르 재생
  Future<void> playCompletionFeedback() async {
    // 1. 진동 축하 패턴 (강한 햅틱 2회 + 롱 진동)
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.vibrate();
    } catch (_) {}

    // 2. 완료 팡파르 멜로디 재생
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/complete.wav'));
    } catch (_) {
      // 오디오 출력 불가 환경(헤드리스 테스트 등)에서도 안전
    }
  }

  void dispose() {
    _player.dispose();
  }
}
