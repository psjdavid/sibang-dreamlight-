import 'package:flutter/material.dart';
import 'dart:math';

enum AlarmMode {
  time,  // 시간 기반 (예: 7시 30분)
  cycle, // 주기 기반 (예: 3주기 후)
}

class AlarmModel {
  final String id;
  String name;
  bool isEnabled;

  // 알람 모드
  AlarmMode mode;

  // 시간 모드 설정
  TimeOfDay? targetTime;

  // 주기 모드 설정
  int cycleCount; // 몇 주기 후에 깰 것인가
  int cycleDurationMinutes; // 한 주기의 길이 (기본 90분)

  // 수면 보장 시간
  bool guaranteedSleepEnabled;
  int guaranteedSleepMinutes; // 최소 수면 시간 (분)

  // 스마트 알람
  int smartWindowMinutes; // REM 수면 감지 윈도우 (분)

  final bool smartAlarmEnabled;  // 추가 필요 (기본값: true)

  // 알람 설정
  String alarmSound;
  double volume;
  bool vibration;
  bool repeatDaily;
  List<int> repeatDays; // 0=일, 1=월, ..., 6=토

  AlarmModel({
    required this.id,
    this.name = '알람',
    this.isEnabled = true,
    this.mode = AlarmMode.time,
    this.targetTime,
    this.cycleCount = 5, // 기본 5주기 (7.5시간)
    this.cycleDurationMinutes = 90,
    this.guaranteedSleepEnabled = false,
    this.guaranteedSleepMinutes = 420, // 기본 7시간
    this.smartWindowMinutes = 30,
    this.alarmSound = '기본 알람',
    this.volume = 0.7,
    this.vibration = true,
    this.repeatDaily = false,
    this.repeatDays = const [],
    this.smartAlarmEnabled = true,  // 기본값 true
  }) {
    targetTime ??= const TimeOfDay(hour: 7, minute: 30);
  }

  // 총 수면 예정 시간 계산 (주기 모드일 때)
  int get totalSleepMinutes => cycleCount * cycleDurationMinutes;

  // 수면 보장 시간 체크 및 추천 주기 계산
  AlarmRecommendation getRecommendation() {
    if (mode != AlarmMode.cycle) {
      return AlarmRecommendation(
        isValid: true,
        recommendedCycleCount: cycleCount,
        message: '시간 모드 사용 중',
      );
    }

    if (!guaranteedSleepEnabled) {
      return AlarmRecommendation(
        isValid: true,
        recommendedCycleCount: cycleCount,
        message: '설정된 ${cycleCount}주기 (${_formatDuration(totalSleepMinutes)})에 알람이 울립니다.',
      );
    }

    // 수면 보장 시간 체크
    if (totalSleepMinutes < guaranteedSleepMinutes) {
      // 보장 시간 이상의 가장 가까운 주기 찾기
      int recommendedCycles = (guaranteedSleepMinutes / cycleDurationMinutes).ceil();
      int recommendedMinutes = recommendedCycles * cycleDurationMinutes;

      return AlarmRecommendation(
        isValid: false,
        recommendedCycleCount: recommendedCycles,
        message: '⚠️ 수면 보장 시간(${_formatDuration(guaranteedSleepMinutes)}) 미만입니다.\n'
            '추천: ${recommendedCycles}주기 (${_formatDuration(recommendedMinutes)})',
      );
    }

    // 보장 시간은 충족하지만, 더 가까운 주기가 있는지 확인
    int lowerCycle = (guaranteedSleepMinutes / cycleDurationMinutes).ceil();
    int upperCycle = cycleCount;

    if (lowerCycle == upperCycle) {
      return AlarmRecommendation(
        isValid: true,
        recommendedCycleCount: cycleCount,
        message: '✅ 최적 시간입니다! ${cycleCount}주기 (${_formatDuration(totalSleepMinutes)})',
      );
    } else {
      return AlarmRecommendation(
        isValid: true,
        recommendedCycleCount: lowerCycle,
        message: '현재: ${cycleCount}주기 (${_formatDuration(totalSleepMinutes)})\n'
            '더 빠른 기상: ${lowerCycle}주기 (${_formatDuration(lowerCycle * cycleDurationMinutes)}) 가능',
      );
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}시간';
    } else if (hours == 0) {
      return '${mins}분';
    } else {
      return '${hours}시간 ${mins}분';
    }
  }

  // 다음 알람 시간 계산 (표시용)
  String getNextAlarmTimeDisplay() {
    if (mode == AlarmMode.time && targetTime != null) {
      return '${targetTime!.hour.toString().padLeft(2, '0')}:${targetTime!.minute.toString().padLeft(2, '0')}';
    } else {
      return '${cycleCount}주기 후 (${_formatDuration(totalSleepMinutes)})';
    }
  }

  // 알람 복사
  AlarmModel copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    AlarmMode? mode,
    TimeOfDay? targetTime,
    int? cycleCount,
    int? cycleDurationMinutes,
    bool? guaranteedSleepEnabled,
    int? guaranteedSleepMinutes,
    int? smartWindowMinutes,
    String? alarmSound,
    double? volume,
    bool? vibration,
    bool? repeatDaily,
    List<int>? repeatDays,
    bool? smartAlarmEnabled,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      targetTime: targetTime ?? this.targetTime,
      cycleCount: cycleCount ?? this.cycleCount,
      cycleDurationMinutes: cycleDurationMinutes ?? this.cycleDurationMinutes,
      guaranteedSleepEnabled: guaranteedSleepEnabled ?? this.guaranteedSleepEnabled,
      guaranteedSleepMinutes: guaranteedSleepMinutes ?? this.guaranteedSleepMinutes,
      smartWindowMinutes: smartWindowMinutes ?? this.smartWindowMinutes,
      alarmSound: alarmSound ?? this.alarmSound,
      volume: volume ?? this.volume,
      vibration: vibration ?? this.vibration,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      repeatDays: repeatDays ?? this.repeatDays,
      smartAlarmEnabled: smartAlarmEnabled ?? this.smartAlarmEnabled,
    );
  }

  // JSON 변환 (저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'mode': mode.index,
      'targetTimeHour': targetTime?.hour,
      'targetTimeMinute': targetTime?.minute,
      'cycleCount': cycleCount,
      'cycleDurationMinutes': cycleDurationMinutes,
      'guaranteedSleepEnabled': guaranteedSleepEnabled,
      'guaranteedSleepMinutes': guaranteedSleepMinutes,
      'smartWindowMinutes': smartWindowMinutes,
      'alarmSound': alarmSound,
      'volume': volume,
      'vibration': vibration,
      'repeatDaily': repeatDaily,
      'repeatDays': repeatDays,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      name: json['name'] ?? '알람',
      isEnabled: json['isEnabled'] ?? true,
      mode: AlarmMode.values[json['mode'] ?? 0],
      targetTime: json['targetTimeHour'] != null
          ? TimeOfDay(
        hour: json['targetTimeHour'],
        minute: json['targetTimeMinute'],
      )
          : null,
      cycleCount: json['cycleCount'] ?? 5,
      cycleDurationMinutes: json['cycleDurationMinutes'] ?? 90,
      guaranteedSleepEnabled: json['guaranteedSleepEnabled'] ?? false,
      guaranteedSleepMinutes: json['guaranteedSleepMinutes'] ?? 420,
      smartWindowMinutes: json['smartWindowMinutes'] ?? 30,
      alarmSound: json['alarmSound'] ?? '기본 알람',
      volume: json['volume'] ?? 0.7,
      vibration: json['vibration'] ?? true,
      repeatDaily: json['repeatDaily'] ?? false,
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
    );
  }
}

class AlarmRecommendation {
  final bool isValid; // 현재 설정이 수면 보장 시간을 충족하는가
  final int recommendedCycleCount; // 추천 주기 수
  final String message; // 사용자에게 보여줄 메시지

  AlarmRecommendation({
    required this.isValid,
    required this.recommendedCycleCount,
    required this.message,
  });
}

// 알람 관리 서비스
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final List<AlarmModel> _alarms = [];

  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  // 알람 추가
  void addAlarm(AlarmModel alarm) {
    _alarms.add(alarm);
  }

  // 알람 생성
  AlarmModel createAlarm() {
    final alarm = AlarmModel(
      id: _generateId(),
      name: '알람 ${_alarms.length + 1}',
    );
    _alarms.add(alarm);
    return alarm;
  }

  // 알람 수정
  void updateAlarm(AlarmModel updatedAlarm) {
    final index = _alarms.indexWhere((a) => a.id == updatedAlarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
    }
  }

  // 알람 삭제
  void deleteAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
  }

  // 알람 토글
  void toggleAlarm(String id) {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(
        isEnabled: !_alarms[index].isEnabled,
      );
    }
  }

  // ID로 알람 찾기
  AlarmModel? getAlarm(String id) {
    try {
      return _alarms.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}