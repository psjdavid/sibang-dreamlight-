import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  double _alarmVolume = 70;
  String _selectedRingtone = '기본 알람음';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 테마 설정 섹션
          _buildSectionTitle('테마 설정'),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: SwitchListTile(
              title: const Text(
                '다크 모드',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _isDarkMode ? '어두운 테마 사용 중' : '밝은 테마 사용 중',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              secondary: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              value: _isDarkMode,
              onChanged: (value) {
                // 1) 로컬 상태 변경 → 슬라이더 바로 움직임
                setState(() {
                  _isDarkMode = value;
                });

                // 2) 부모에게도 알림 → 실제 앱 테마 변경
                widget.onThemeToggle();
              },
              activeColor: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 30),

          // 알람 설정 섹션
          _buildSectionTitle('알람 설정'),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    '진동',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _vibrationEnabled ? '알람 시 진동합니다' : '진동하지 않습니다',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  secondary: Icon(
                    Icons.vibration,
                    color: theme.colorScheme.primary,
                  ),
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    '사운드',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _soundEnabled ? '알람음이 재생됩니다' : '무음 모드',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  secondary: Icon(
                    _soundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: theme.colorScheme.primary,
                  ),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 알람 볼륨
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
                        '알람 볼륨',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_alarmVolume.round()}%',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _alarmVolume,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_alarmVolume.round()}%',
                    onChanged: _soundEnabled
                        ? (value) {
                      setState(() {
                        _alarmVolume = value;
                      });
                    }
                        : null,
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 벨소리 선택
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: Icon(
                Icons.music_note,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                '알람음',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _selectedRingtone,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showRingtoneDialog();
              },
            ),
          ),

          const SizedBox(height: 30),

          // 수면 분석 설정 섹션
          _buildSectionTitle('수면 분석 설정'),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: Icon(
                Icons.auto_graph,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                '수면 데이터 수집',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text(
                '수면 패턴 분석을 위해 데이터를 수집합니다',
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 앱 정보 섹션
          _buildSectionTitle('앱 정보'),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    '버전 정보',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text('드림라이트 v1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    '도움말',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showHelpDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showRingtoneDialog() {
    final ringtones = [
      '기본 알람음',
      '부드러운 멜로디',
      '새소리',
      '파도 소리',
      '클래식 벨',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('알람음 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ringtones.map((ringtone) {
            return RadioListTile<String>(
              title: Text(ringtone),
              value: ringtone,
              groupValue: _selectedRingtone,
              onChanged: (value) {
                setState(() {
                  _selectedRingtone = value!;
                });
                Navigator.pop(context);
              },
              activeColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text('드림라이트'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0'),
            SizedBox(height: 10),
            Text('개발: 시루와 방실이'),
            SizedBox(height: 10),
            Text(
              '수면 패턴 분석을 통한 맞춤형 기상 알람 서비스',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('도움말'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '드림라이트 사용 방법',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('1. 메인 페이지에서 알람 시간을 설정하세요.'),
              SizedBox(height: 5),
              Text('2. 수면 보장 시간을 설정하세요.'),
              SizedBox(height: 5),
              Text('3. 알람 유형(맞춤/일반)을 선택하세요.'),
              SizedBox(height: 5),
              Text('4. "수면 시작" 버튼을 눌러 수면 추적을 시작하세요.'),
              SizedBox(height: 10),
              Text(
                '💡 팁: 수면 패턴 맞춤 알람을 사용하면 얕은 잠 단계에서 기상할 수 있어 더욱 상쾌한 아침을 맞이할 수 있습니다!',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}