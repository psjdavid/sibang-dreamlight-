import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart' show TimeOfDay;   // ✅ 추가
import 'asleep_service.dart';
import 'asleep_native_bridge.dart';

class SleepDataStore {
  static final SleepDataStore _instance = SleepDataStore._internal();
  factory SleepDataStore() => _instance;
  SleepDataStore._internal();

  SleepReport? lastReport;
  List<SleepSegment> realtimeSegments = [];
}

class SleepTrackingService {
  final AsleepService asleepService;
  final AsleepNativeBridge _nativeBridge = AsleepNativeBridge();

  String? _currentSessionId;
  bool _isTracking = false;
  Timer? _monitoringTimer;

  TimeOfDay? targetAlarmTime;
  int smartAlarmWindowMinutes = 30;

  Function(SleepStage)? onSleepStageChanged;
  Function(String)? onAlarmTriggered;

  SleepTrackingService({required this.asleepService});

  /// 마이크 권한 요청
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      print('✅ 마이크 권한 허용됨');
      return true;
    } else if (status.isPermanentlyDenied) {
      print('❌ 마이크 권한이 영구적으로 거부됨');
      await openAppSettings();
      return false;
    } else {
      print('❌ 마이크 권한 거부됨');
      return false;
    }
  }

  /// SDK 방식 수면 추적 시작
  Future<bool> startSleepTracking({
    required TimeOfDay alarmTime,
    int smartWindowMinutes = 30,
  }) async {
    if (_isTracking) {
      print('⚠️  이미 수면 추적 중입니다.');
      return false;
    }

    try {
      // 1. 권한 확인
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('마이크 권한이 필요합니다.');
      }

      // 2. Asleep SDK 초기화
      print('📝 Asleep SDK 초기화 중...');
      final initResult = await _nativeBridge.initAsleep(
        apiKey: asleepService.apiKey,
        userId: asleepService.userId,
      );

      if (!initResult.success) {
        throw Exception('Asleep SDK 초기화 실패');
      }

      if (kDebugMode) {
        print('✅ SDK init userId: ${initResult.userId}');
      }

      // 3. SDK로 수면 추적 시작
      print('📝 수면 세션 생성 중 (SDK)...');
      final sessionId = await _nativeBridge.beginTracking();
      _currentSessionId = sessionId;
      print('✅ SDK 세션 ID: $sessionId');

      // 4. 알람 설정
      targetAlarmTime = alarmTime;
      this.smartAlarmWindowMinutes = smartWindowMinutes;
      _isTracking = true;

      // 5. 기존 실시간 세그먼트 초기화
      SleepDataStore().realtimeSegments.clear();

      // 6. 실시간 모니터링 시작 (REST)
      _startRealtimeMonitoring();

      print('✅ 수면 추적 시작! (SDK 녹음 사용 중)');
      return true;
    } catch (e) {
      print('❌ 수면 추적 시작 실패: $e');
      _isTracking = false;
      return false;
    }
  }

  /// REST API로 실시간 수면 단계 폴링
  void _startRealtimeMonitoring() {
    if (_currentSessionId == null) return;

    _monitoringTimer?.cancel();

    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
          (timer) async {
        if (!_isTracking || _currentSessionId == null) {
          timer.cancel();
          return;
        }

        try {
          // 실시간 데이터에서 현재 수면 단계 가져오기
          final currentStage =
          await asleepService.getCurrentSleepStage(_currentSessionId!);

          if (currentStage != null) {
            final now = DateTime.now();

            // SleepDataStore에 세그먼트 추가
            SleepDataStore().realtimeSegments.add(
              SleepSegment(
                startTime: now.subtract(const Duration(seconds: 30)),
                endTime: now,
                stage: currentStage,
              ),
            );

            onSleepStageChanged?.call(currentStage);

            if (currentStage == SleepStage.rem) {
              _checkSmartAlarm();
            }
          } else {
            print('⏳ [실제 API] 분석 중...');
          }
        } catch (e) {
          print('수면 단계 확인 중 오류: $e');
        }
      },
    );
  }

  /// 스마트 알람: REM 상태 + 윈도우 안이면 알람 트리거
  void _checkSmartAlarm() {
    if (targetAlarmTime == null) return;

    final now = DateTime.now();
    final targetTime = DateTime(
      now.year,
      now.month,
      now.day,
      targetAlarmTime!.hour,
      targetAlarmTime!.minute,
    );

    final windowStart =
    targetTime.subtract(Duration(minutes: smartAlarmWindowMinutes));

    if (now.isAfter(windowStart) && now.isBefore(targetTime)) {
      print('⏰ 스마트 알람 시간 범위 진입 (REM 상태)');
      onAlarmTriggered?.call('SMART_ALARM');
    }
  }

  /// SDK + REST 기반 수면 추적 종료
  Future<void> stopSleepTracking() async {
    if (!_isTracking) {
      print('⚠️  추적 중이 아닙니다.');
      return;
    }

    try {
      print('🛑 수면 추적 종료 중...');

      // 타이머 취소
      _monitoringTimer?.cancel();
      _monitoringTimer = null;

      // 1. SDK에 종료 요청
      await _nativeBridge.endTracking();

      // 2. 세션 종료 + 리포트 가져오기
      if (_currentSessionId != null) {
        try {
          await asleepService.endSleepSession(_currentSessionId!);
        } catch (e) {
          print('세션 종료 API 호출 중 오류(무시 가능): $e');
        }

        final report = await getSleepReport();
        if (report != null) {
          SleepDataStore().lastReport = report;
          print('✅ 수면 리포트 저장 완료');
        }
      }

      _isTracking = false;
      _currentSessionId = null;

      print('✅ 수면 추적 종료 완료');
    } catch (e) {
      print('❌ 수면 추적 종료 중 오류: $e');
      _isTracking = false;
    }
  }

  /// 최종 수면 리포트 가져오기 (없으면 실시간 데이터로 임시 생성)
  Future<SleepReport?> getSleepReport() async {
    if (_currentSessionId == null) {
      print('❌ 활성 세션이 없습니다.');
      return null;
    }

    print('📊 수면 리포트 가져오는 중...');

    final report = await asleepService.pollSleepReport(
      _currentSessionId!,
      maxAttempts: 60,
      intervalSeconds: 10,
    );

    if (report != null) {
      print('✅ 수면 리포트 가져오기 완료');
      return report;
    } else {
      print('⚠️  리포트를 가져올 수 없습니다. 실시간 데이터로 임시 생성합니다.');
      return _createReportFromSegments();
    }
  }

  /// 실시간 세그먼트로 임시 리포트 생성
  SleepReport _createReportFromSegments() {
    final now = DateTime.now();
    final segments = SleepDataStore().realtimeSegments;

    int remMinutes = 0;
    int lightMinutes = 0;
    int deepMinutes = 0;

    for (final segment in segments) {
      final minutes =
          segment.endTime.difference(segment.startTime).inMinutes;
      switch (segment.stage) {
        case SleepStage.rem:
          remMinutes += minutes;
          break;
        case SleepStage.light:
          lightMinutes += minutes;
          break;
        case SleepStage.deep:
          deepMinutes += minutes;
          break;
        default:
          break;
      }
    }

    final totalMinutes = remMinutes + lightMinutes + deepMinutes;
    final sleepStart = segments.isNotEmpty
        ? segments.first.startTime
        : now.subtract(const Duration(hours: 8));

    return SleepReport(
      startTime: sleepStart,
      endTime: now,
      totalSleepMinutes: totalMinutes > 0 ? totalMinutes : 1,
      remSleepMinutes: remMinutes,
      lightSleepMinutes: lightMinutes,
      deepSleepMinutes: deepMinutes,
      wakeMinutes: 0,
      sleepEfficiency: 0.0,
      sleepLatency: 0,
      wakeCount: 0,
      segments: segments,
    );
  }
}