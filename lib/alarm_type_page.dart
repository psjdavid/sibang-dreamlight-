import 'package:flutter/material.dart';
import 'alarm_model.dart';

class AlarmTypePage extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmTypePage({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmTypePage> createState() => _AlarmTypePageState();
}

class _AlarmTypePageState extends State<AlarmTypePage> {
  late AlarmModel _alarm;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _alarm = widget.alarm;
    _nameController.text = _alarm.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateAlarm(AlarmModel updatedAlarm) {
    setState(() {
      _alarm = updatedAlarm;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarm.targetTime ?? const TimeOfDay(hour: 7, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateAlarm(_alarm.copyWith(targetTime: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendation = _alarm.getRecommendation();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알람 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _alarm = _alarm.copyWith(name: _nameController.text);
              Navigator.pop(context, _alarm);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 알람 이름
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '알람 이름',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              prefixIcon: const Icon(Icons.label),
            ),
          ),

          const SizedBox(height: 25),

          // 모드 선택 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '시간 모드 또는 주기 모드를 선택하여 최적의 기상 시간을 설정하세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 알람 모드 선택
          _buildSectionTitle('알람 모드', theme),
          const SizedBox(height: 10),

          _buildModeCard(
            AlarmMode.time,
            '시간 모드',
            '특정 시간에 정확히 기상합니다.',
            Icons.access_time,
            theme,
          ),

          const SizedBox(height: 15),

          _buildModeCard(
            AlarmMode.cycle,
            '주기 모드',
            '수면 주기를 고려하여 N주기 후에 기상합니다.',
            Icons.nightlight_round,
            theme,
          ),

          const SizedBox(height: 30),

          // 시간 또는 주기 설정
          if (_alarm.mode == AlarmMode.time)
            _buildTimeSettings(theme)
          else
            _buildCycleSettings(theme),

          const SizedBox(height: 30),

          // 스마트 알람 설정
          _buildSectionTitle('스마트 알람 옵션', theme),
          const SizedBox(height: 10),
          _buildSmartAlarmSettings(theme),

          const SizedBox(height: 30),

          // 수면 보장 시간
          _buildSectionTitle('수면 보장 시간', theme),
          const SizedBox(height: 10),
          _buildGuaranteedSleepSettings(theme),

          // 추천 메시지 (주기 모드일 때)
          if (_alarm.mode == AlarmMode.cycle) ...[
            const SizedBox(height: 16),
            _buildRecommendationCard(recommendation, theme),
          ],

          const SizedBox(height: 30),

          // 알람 옵션
          _buildSectionTitle('알람 옵션', theme),
          const SizedBox(height: 10),
          _buildAlarmOptions(theme),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModeCard(
      AlarmMode mode,
      String title,
      String description,
      IconData icon,
      ThemeData theme,
      ) {
    final isSelected = _alarm.mode == mode;

    return GestureDetector(
      onTap: () {
        _updateAlarm(_alarm.copyWith(mode: mode));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('기상 시간', theme),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '기상 시간',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _alarm.targetTime != null
                      ? '${_alarm.targetTime!.hour.toString().padLeft(2, '0')}:${_alarm.targetTime!.minute.toString().padLeft(2, '0')}'
                      : '07:30',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleSettings(ThemeData theme) {
    const int averageCycleDuration = 90; // 하드코딩된 평균 수면 사이클 시간

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('수면 주기 설정', theme),
        const SizedBox(height: 12),

        // 주기 수
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '주기 수',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1주기',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '${_alarm.cycleCount}주기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '10주기',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _alarm.cycleCount.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${_alarm.cycleCount}주기',
                  onChanged: (value) {
                    _updateAlarm(_alarm.copyWith(cycleCount: value.round()));
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 5),
                Text(
                  '총 수면 시간: ${_formatDuration(_alarm.cycleCount * averageCycleDuration)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        // 1주기 길이 (읽기 전용)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '평균 1주기 길이',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$averageCycleDuration분',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '측정된 평균 수면 사이클 시간입니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuaranteedSleepSettings(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '최소 수면 시간 보장',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '설정한 시간 미만으로 알람이 울리지 않습니다',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _alarm.guaranteedSleepEnabled,
                  onChanged: (value) {
                    if (value) {
                      // 최소 수면 보장 시간 활성화 시 스마트 알람 비활성화
                      _updateAlarm(_alarm.copyWith(
                        guaranteedSleepEnabled: true,
                        smartAlarmEnabled: false,
                      ));
                    } else {
                      _updateAlarm(_alarm.copyWith(
                        guaranteedSleepEnabled: false,
                      ));
                    }
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
            if (_alarm.guaranteedSleepEnabled) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '4시간',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    _formatDuration(_alarm.guaranteedSleepMinutes),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '10시간',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _alarm.guaranteedSleepMinutes.toDouble(),
                min: 240, // 4시간
                max: 600, // 10시간
                divisions: 36,
                label: _formatDuration(_alarm.guaranteedSleepMinutes),
                onChanged: (value) {
                  _updateAlarm(
                      _alarm.copyWith(guaranteedSleepMinutes: value.round()));
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      AlarmRecommendation recommendation, ThemeData theme) {
    final isWarning = !recommendation.isValid;
    final color = isWarning ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.check_circle,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation.message,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAlarmSettings(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '스마트 알람',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '렘수면 구간에서 최적의 시간에 알람을 울립니다',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _alarm.smartAlarmEnabled,
                  onChanged: (value) {
                    if (value) {
                      // 스마트 알람 활성화 시 최소 수면 보장 비활성화
                      _updateAlarm(_alarm.copyWith(
                        smartAlarmEnabled: true,
                        guaranteedSleepEnabled: false,
                      ));
                    } else {
                      _updateAlarm(_alarm.copyWith(
                        smartAlarmEnabled: false,
                      ));
                    }
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
            if (_alarm.smartAlarmEnabled) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '알람 시간 조정 범위',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '설정한 알람 시간 기준 최대 ${_alarm.smartWindowMinutes}분 전에 렘수면 구간에서 알람을 울립니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0분',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    '${_alarm.smartWindowMinutes}분',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '60분',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _alarm.smartWindowMinutes.toDouble(),
                min: 0,
                max: 60,
                divisions: 12,
                label: '${_alarm.smartWindowMinutes}분',
                onChanged: (value) {
                  _updateAlarm(
                      _alarm.copyWith(smartWindowMinutes: value.round()));
                },
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '범위가 넓을수록 최적의 렘수면 구간을 찾을 확률이 높아집니다.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmOptions(ThemeData theme) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          child: SwitchListTile(
            title: const Text(
              '진동',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              _alarm.vibration ? '알람과 함께 진동' : '진동 사용 안 함',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            secondary: Icon(
              Icons.vibration,
              color: theme.colorScheme.primary,
            ),
            value: _alarm.vibration,
            onChanged: (value) {
              _updateAlarm(_alarm.copyWith(vibration: value));
            },
          ),
        ),
        const SizedBox(height: 15),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          child: ListTile(
            leading: Icon(
              Icons.music_note,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              '알람 소리',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              _alarm.alarmSound,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAlarmSoundDialog(theme);
            },
          ),
        ),
        const SizedBox(height: 15),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '볼륨',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '${(_alarm.volume * 100).round()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _alarm.volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: '${(_alarm.volume * 100).round()}%',
                  onChanged: (value) {
                    _updateAlarm(_alarm.copyWith(volume: value));
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAlarmSoundDialog(ThemeData theme) {
    final sounds = [
      '기본 알람',
      '새소리',
      '파도 소리',
      '클래식',
      '잔잔한 벨소리',
      '기상나팔',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('알람 소리 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds
              .map((sound) => RadioListTile<String>(
            title: Text(sound),
            value: sound,
            groupValue: _alarm.alarmSound,
            onChanged: (value) {
              if (value != null) {
                _updateAlarm(_alarm.copyWith(alarmSound: value));
                Navigator.pop(context);
              }
            },
          ))
              .toList(),
        ),
      ),
    );
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
}