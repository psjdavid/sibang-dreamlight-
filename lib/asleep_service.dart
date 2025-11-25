import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class AsleepService {
  static const platform = MethodChannel('com.example.dreamlight/asleep');
  final String apiKey;
  final String userId;
  final String baseUrl = 'https://api.asleep.ai';

  AsleepService({
    required this.apiKey,
    required this.userId,
  });

  Future<String?> initAsleep(String apiKey, {String? userId}) async {
    try {
      final result = await platform.invokeMethod('initAsleep', {
        'apiKey': apiKey,
        'userId': userId,
      });
      return result['userId'] as String?;
    } catch (e) {
      print('초기화 실패: $e');
      return null;
    }
  }

  // 수면 추적 시작
  Future<String?> beginTracking() async {
    try {
      final result = await platform.invokeMethod('beginTracking');
      return result['sessionId'] as String?;
    } catch (e) {
      print('추적 시작 실패: $e');
      return null;
    }
  }

  // 수면 추적 종료
  Future<bool> endTracking() async {
    try {
      await platform.invokeMethod('endTracking');
      return true;
    } catch (e) {
      print('추적 종료 실패: $e');
      return false;
    }
  }

  // 리포트 가져오기
  Future<Map<String, dynamic>?> getReport(String sessionId) async {
    try {
      final result = await platform.invokeMethod('getReport', {
        'sessionId': sessionId,
      });
      return result['report'] as Map<String, dynamic>?;
    } catch (e) {
      print('리포트 가져오기 실패: $e');
      return null;
    }
  }

  Future<void> debugTestApiKeyAndUser() async {
    final url = Uri.parse('$baseUrl/data/v1/sessions');

    final response = await http.get(
      url,
      headers: {
        'x-api-key': apiKey,
        'x-user-id': userId,
        'timezone': 'Asia/Seoul',
      },
    );

    print('🔎 [debugTestApiKeyAndUser]');
    print('  status: ${response.statusCode}');
    print('  body:   ${response.body}');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'x-user-id': userId,
    };
  }

  Future<String> createSleepSession() async {
    try {
      final now = DateTime.now();
      final response = await http.post(
        Uri.parse('$baseUrl/v1/sleep-sessions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'session_start_time': now.toIso8601String(),
          'timezone': 'Asia/Seoul',

          // 🔴 새로 추가
          // 정확한 enum 값은 Asleep 쪽 내부 스펙이라 문서에 안 나와 있음.
          // 보통은 오디오 업로드 방식 표시에 쓰이니까,
          // 우선 임시로 'AUDIO' 같이 의미 있는 값을 보내보고,
          // 안 되면 에러 메시지로 허용 값 목록을 알려줄 가능성이 높아.
          'upload_data_type': 'AUDIO',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sessionId = data['session_id'] ?? data['id'];
        print('✅ 수면 세션 생성: $sessionId');
        return sessionId;
      } else {
        throw Exception('세션 생성 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating sleep session: $e');
      rethrow;
    }
  }

  Future<String> getLatestSessionId() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/v1/sessions?limit=1&order_by=DESC'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['session_id'] ?? data[0]['id'];
        } else if (data is Map && data['sessions'] != null) {
          final sessions = data['sessions'] as List;
          if (sessions.isNotEmpty) {
            return sessions[0]['session_id'] ?? sessions[0]['id'];
          }
        }
        throw Exception('수면 세션이 없습니다.');
      } else {
        throw Exception('세션 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting latest session: $e');
      rethrow;
    }
  }

  /// 오디오 데이터 업로드 (실제 API)
  Future<bool> uploadAudioData(String sessionId, Uint8List audioData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/v1/sessions/$sessionId/audio'),
        headers: {
          'x-api-key': apiKey,
          'x-user-id': userId,
          'Content-Type': 'application/octet-stream',
        },
        body: audioData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ 오디오 업로드 성공 (${audioData.length} bytes)');
        return true;
      } else {
        print('⚠️  오디오 업로드 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 오디오 업로드 에러: $e');
      return false;
    }
  }

  Future<SleepRealtimeData?> getRealTimeSleepData(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data/v3/sessions/$sessionId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SleepRealtimeData.fromJson(data);
      } else if (response.statusCode == 404) {
        print('아직 분석 데이터가 없습니다.');
        return null;
      } else {
        throw Exception('실시간 데이터 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting realtime data: $e');
      return null;
    }
  }

  Future<void> endSleepSession(String sessionId) async {
    try {
      final now = DateTime.now();
      final response = await http.patch(
        Uri.parse('$baseUrl/ai/v1/data/sessions/$sessionId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'session_end_time': now.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ 수면 세션 종료: $sessionId');
      } else {
        print('⚠️  세션 종료 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error ending session: $e');
    }
  }

  Future<SleepReport?> pollSleepReport(
      String sessionId, {
        int maxAttempts = 60,
        int intervalSeconds = 10,
      }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/data/v3/sessions/$sessionId'),
          headers: _getHeaders(),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['state'] == 'COMPLETED') {
            return SleepReport.fromJson(data);
          } else {
            print('분석 중... (${i + 1}/$maxAttempts)');
          }
        }
      } catch (e) {
        print('리포트 조회 중 오류: $e');
      }

      await Future.delayed(Duration(seconds: intervalSeconds));
    }

    return null;
  }

  Future<SleepStage?> getCurrentSleepStage(String sessionId) async {
    final data = await getRealTimeSleepData(sessionId);
    return data?.getCurrentStage();
  }
}

enum SleepStage {
  awake,
  rem,
  light,
  deep,
  unknown,
}

class SleepRealtimeData {
  final String state;
  final List<SleepSegment> stages;

  SleepRealtimeData({
    required this.state,
    required this.stages,
  });

  factory SleepRealtimeData.fromJson(Map<String, dynamic> json) {
    final stagesList = json['stages'] ?? json['segments'] ?? [];
    return SleepRealtimeData(
      state: json['state'] ?? 'PROCESSING',
      stages: (stagesList as List)
          .map((s) => SleepSegment.fromJson(s))
          .toList(),
    );
  }

  SleepStage? getCurrentStage() {
    if (stages.isEmpty) return null;
    return stages.last.stage;
  }
}

class SleepSegment {
  final DateTime startTime;
  final DateTime endTime;
  final SleepStage stage;

  SleepSegment({
    required this.startTime,
    required this.endTime,
    required this.stage,
  });

  factory SleepSegment.fromJson(Map<String, dynamic> json) {
    return SleepSegment(
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      stage: _parseSleepStage(json['stage']),
    );
  }

  static SleepStage _parseSleepStage(String? stageStr) {
    switch (stageStr?.toLowerCase()) {
      case 'awake':
      case 'wake':
        return SleepStage.awake;
      case 'rem':
        return SleepStage.rem;
      case 'light':
      case 'light_sleep':
        return SleepStage.light;
      case 'deep':
      case 'deep_sleep':
        return SleepStage.deep;
      default:
        return SleepStage.unknown;
    }
  }
}

class SleepReport {
  final DateTime startTime;
  final DateTime endTime;
  final int totalSleepMinutes;
  final int remSleepMinutes;
  final int lightSleepMinutes;
  final int deepSleepMinutes;
  final int wakeMinutes;
  final double sleepEfficiency;
  final int sleepLatency;
  final int wakeCount;
  final List<SleepSegment> segments;

  SleepReport({
    required this.startTime,
    required this.endTime,
    required this.totalSleepMinutes,
    required this.remSleepMinutes,
    required this.lightSleepMinutes,
    required this.deepSleepMinutes,
    required this.wakeMinutes,
    required this.sleepEfficiency,
    required this.sleepLatency,
    required this.wakeCount,
    required this.segments,
  });

  factory SleepReport.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] ?? {};
    final segmentsList = json['segments'] ?? json['stages'] ?? [];

    return SleepReport(
      startTime: DateTime.parse(json['session_start_time']),
      endTime: DateTime.parse(json['session_end_time']),
      totalSleepMinutes: stats['total_sleep_time'] ?? 0,
      remSleepMinutes: stats['rem_sleep_time'] ?? 0,
      lightSleepMinutes: stats['light_sleep_time'] ?? 0,
      deepSleepMinutes: stats['deep_sleep_time'] ?? 0,
      wakeMinutes: stats['wake_time'] ?? 0,
      sleepEfficiency: (stats['sleep_efficiency'] ?? 0.0).toDouble(),
      sleepLatency: stats['sleep_latency'] ?? 0,
      wakeCount: stats['wake_count'] ?? 0,
      segments: (segmentsList as List)
          .map((s) => SleepSegment.fromJson(s))
          .toList(),
    );
  }

  List<SleepSegment> getNextREMPeriods() {
    return segments.where((s) => s.stage == SleepStage.rem).toList();
  }

  int calculateSleepScore() {
    double score = 0;

    final totalHours = totalSleepMinutes / 60;
    if (totalHours >= 7 && totalHours <= 8) {
      score += 30;
    } else if (totalHours >= 6 && totalHours < 7) {
      score += 20;
    } else if (totalHours > 8 && totalHours <= 9) {
      score += 25;
    }

    score += sleepEfficiency * 30;

    final deepSleepRatio = deepSleepMinutes / totalSleepMinutes;
    if (deepSleepRatio >= 0.15 && deepSleepRatio <= 0.25) {
      score += 20;
    } else if (deepSleepRatio >= 0.10) {
      score += 15;
    }

    final remRatio = remSleepMinutes / totalSleepMinutes;
    if (remRatio >= 0.20 && remRatio <= 0.25) {
      score += 20;
    } else if (remRatio >= 0.15) {
      score += 15;
    }

    return score.round().clamp(0, 100);
  }
}