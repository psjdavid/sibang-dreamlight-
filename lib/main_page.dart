import 'package:flutter/material.dart';
import 'alarm_model.dart';
import 'alarm_type_page.dart';
import 'asleep_service.dart';
import 'main.dart';
import 'package:flutter/foundation.dart'; // kDebugMode 쓰려면 필요

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final AlarmService _alarmService = AlarmService();
  bool _isTrackingSleep = false;

  @override
  void initState() {
    super.initState();
    // 초기 알람 하나 생성
    if (_alarmService.alarms.isEmpty) {
      _alarmService.createAlarm();
    }
  }

  void _navigateToAlarmDetail(AlarmModel alarm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmTypePage(alarm: alarm),
      ),
    );

    if (result != null) {
      setState(() {
        _alarmService.updateAlarm(result);
      });
    }
  }

  void _createNewAlarm() {
    final newAlarm = _alarmService.createAlarm();
    setState(() {});
    _navigateToAlarmDetail(newAlarm);
  }

  Future<void> _startSleepTracking() async {
    final enabledAlarms = _alarmService.alarms.where((a) => a.isEnabled).toList();

    if (enabledAlarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('활성화된 알람이 없습니다. 먼저 알람을 켜주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final alarm = enabledAlarms.first;
    final alarmTime = alarm.targetTime ?? const TimeOfDay(hour: 7, minute: 30);

    setState(() {
      _isTrackingSleep = true;
    });

    final success = await sleepTrackingService.startSleepTracking(
      alarmTime: alarmTime,
      smartWindowMinutes: alarm.smartWindowMinutes,
    );

    if (!success) {
      setState(() {
        _isTrackingSleep = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('수면 추적을 시작할 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('수면 추적이 시작되었습니다. 편안한 밤 되세요!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _stopSleepTracking() async {
    await sleepTrackingService.stopSleepTracking();
    setState(() {
      _isTrackingSleep = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수면 추적이 종료되었습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '드림라이트',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (kDebugMode)   // 🔹 릴리즈 빌드에서는 안 보이게
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Asleep API 테스트',
              onPressed: () async {
                // 여기서 디버그 함수 호출
                // asleep_service.dart에 만든 debugTestApiKeyAndUser() 호출
                try {
                  await sleepTrackingService.asleepService
                      .debugTestApiKeyAndUser(); // 이름 맞게 수정해서 사용
                } catch (e) {
                  debugPrint('debugTestApiKeyAndUser error: $e');
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 수면 추적 버튼
          _buildSleepTrackingButton(theme),
          const SizedBox(height: 16),
          // 알람 리스트
          Expanded(
            child: _alarmService.alarms.isEmpty
                ? _buildEmptyState(theme)
                : _buildAlarmList(theme, isDark),
          ),
        ],
      ),
      floatingActionButton: _isTrackingSleep
          ? null
          : FloatingActionButton.extended(
              onPressed: _createNewAlarm,
              icon: const Icon(Icons.add),
              label: const Text('알람 추가'),
              elevation: 4,
            ),
    );
  }

  Widget _buildSleepTrackingButton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isTrackingSleep
              ? [Colors.orange, Colors.deepOrange]
              : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (_isTrackingSleep ? Colors.orange : theme.colorScheme.primary).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _isTrackingSleep ? _stopSleepTracking : _startSleepTracking,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isTrackingSleep ? Icons.stop_circle : Icons.bedtime,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isTrackingSleep ? '수면 추적 중' : '수면 시작',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isTrackingSleep)
                      const Text(
                        '탭하여 중지',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_add,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            '설정된 알람이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '하단의 버튼을 눌러 알람을 추가하세요',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alarmService.alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarmService.alarms[index];
        return _buildAlarmCard(alarm, theme, isDark);
      },
    );
  }

  Widget _buildAlarmCard(AlarmModel alarm, ThemeData theme, bool isDark) {
    final recommendation = alarm.getRecommendation();
    final hasWarning = alarm.guaranteedSleepEnabled && !recommendation.isValid;

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('알람 삭제'),
            content: Text('${alarm.name}을(를) 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        setState(() {
          _alarmService.deleteAlarm(alarm.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alarm.name}이(가) 삭제되었습니다'),
            action: SnackBarAction(
              label: '실행 취소',
              onPressed: () {
                setState(() {
                  _alarmService.addAlarm(alarm);
                });
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: alarm.isEnabled ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: hasWarning
              ? BorderSide(color: Colors.orange, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _navigateToAlarmDetail(alarm),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: alarm.isEnabled
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                alarm.mode == AlarmMode.time
                                    ? Icons.access_time
                                    : Icons.nightlight_round,
                                size: 16,
                                color: alarm.isEnabled
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                alarm.mode == AlarmMode.time
                                    ? '시간 모드'
                                    : '주기 모드',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: alarm.isEnabled
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _alarmService.toggleAlarm(alarm.id);
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  alarm.getNextAlarmTimeDisplay(),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    color: alarm.isEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                if (alarm.mode == AlarmMode.cycle) ...[
                  const SizedBox(height: 8),
                  Text(
                    '주기: ${alarm.cycleDurationMinutes}분',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                if (hasWarning) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (alarm.repeatDaily)
                      _buildInfoChip(
                        icon: Icons.repeat,
                        label: '매일',
                        theme: theme,
                        enabled: alarm.isEnabled,
                      ),
                    if (alarm.vibration)
                      _buildInfoChip(
                        icon: Icons.vibration,
                        label: '진동',
                        theme: theme,
                        enabled: alarm.isEnabled,
                      ),
                    if (alarm.guaranteedSleepEnabled)
                      _buildInfoChip(
                        icon: Icons.shield,
                        label: '수면 보장',
                        theme: theme,
                        enabled: alarm.isEnabled,
                      ),
                    if (alarm.smartWindowMinutes > 0)
                      _buildInfoChip(
                        icon: Icons.schedule,
                        label: '스마트 ${alarm.smartWindowMinutes}분',
                        theme: theme,
                        enabled: alarm.isEnabled,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: enabled
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}