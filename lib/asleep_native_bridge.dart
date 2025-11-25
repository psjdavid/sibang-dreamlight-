import 'package:flutter/services.dart';

class AsleepNativeBridge {
  static const _channel = MethodChannel('com.example.dreamlight/asleep');

  /// SDK 초기화 (initAsleepConfig)
  Future<({bool success, String? userId})> initAsleep({
    required String apiKey,
    String? userId,
  }) async {
    final result =
    await _channel.invokeMethod<Map<dynamic, dynamic>>('initAsleep', {
      'apiKey': apiKey,
      'userId': userId,
    });

    final success = result?['success'] == true;
    final sdkUserId = result?['userId'] as String?;

    return (success: success, userId: sdkUserId);
  }

  /// beginSleepTracking() → sessionId 반환
  Future<String> beginTracking() async {
    final sessionId =
    await _channel.invokeMethod<String>('beginTracking');

    if (sessionId == null) {
      throw Exception('beginTracking에서 sessionId가 null입니다.');
    }
    return sessionId;
  }

  /// endSleepTracking()
  Future<void> endTracking() async {
    await _channel.invokeMethod('endTracking');
  }

  /// 단순 SDK 체크용
  Future<String> testSDK() async {
    final res = await _channel.invokeMethod<String>('testSDK');
    return res ?? 'NO_RESULT';
  }
}
