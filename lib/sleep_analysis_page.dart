import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'sleep_tracking_service.dart';
import 'asleep_service.dart';

class SleepAnalysisPage extends StatefulWidget {
  const SleepAnalysisPage({super.key});

  @override
  State<SleepAnalysisPage> createState() => _SleepAnalysisPageState();
}

class _SleepAnalysisPageState extends State<SleepAnalysisPage> {
  String _selectedPeriod = '오늘';
  SleepReport? _report;
  List<SleepData> _sleepData = [];

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  void _loadSleepData() {
    // 저장된 리포트 가져오기
    _report = SleepDataStore().lastReport;

    if (_report != null && _report!.segments.isNotEmpty) {
      // 실제 데이터 변환
      _sleepData = _convertSegmentsToData(_report!.segments);
    } else {
      // 목업 데이터
      _sleepData = _generateMockSleepData(480);
    }

    setState(() {});
  }

  List<SleepData> _convertSegmentsToData(List<SleepSegment> segments) {
    final data = <SleepData>[];

    if (segments.isEmpty) return data;

    final startTime = segments.first.startTime;

    for (var segment in segments) {
      final minutesSinceStart = segment.endTime.difference(startTime).inMinutes;
      final depth = _stageToDepth(segment.stage);
      data.add(SleepData(minutesSinceStart, depth));
    }

    return data;
  }

  double _stageToDepth(SleepStage stage) {
    switch (stage) {
      case SleepStage.rem:
        return 1.5;
      case SleepStage.light:
        return 3.0;
      case SleepStage.deep:
        return 4.5;
      case SleepStage.awake:
        return 1.0;
      default:
        return 2.5;
    }
  }

  static List<SleepData> _generateMockSleepData(int durationMinutes) {
    final data = <SleepData>[];
    final random = math.Random(42);

    for (int i = 0; i < durationMinutes; i += 5) {
      final cyclePosition = (i % 90) / 90.0;
      double depth;

      if (cyclePosition < 0.15) {
        depth = 1.0 + random.nextDouble() * 0.5;
      } else if (cyclePosition < 0.4) {
        depth = 2.0 + (cyclePosition - 0.15) * 8;
      } else if (cyclePosition < 0.7) {
        depth = 4.5 + random.nextDouble() * 0.5;
      } else {
        depth = 4.5 - (cyclePosition - 0.7) * 10;
      }

      data.add(SleepData(i, depth.clamp(1.0, 5.0)));
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRealData = _report != null && _report!.segments.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '수면 분석',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSleepData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 데이터 출처 표시
          if (hasRealData)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '실시간 수면 추적 데이터',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '샘플 데이터 (수면 추적 후 실제 데이터 표시)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 기간 선택
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['오늘', '이번 주', '이번 달', '전체'].map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 25),

          // 수면 요약 통계
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '총 수면',
                  _formatMinutes(_report?.totalSleepMinutes ?? 450),
                  Icons.bedtime,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '수면 점수',
                  '${_report?.calculateSleepScore() ?? 85}점',
                  Icons.stars,
                  Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'REM 수면',
                  _formatMinutes(_report?.remSleepMinutes ?? 90),
                  Icons.air,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '깊은 잠',
                  _formatMinutes(_report?.deepSleepMinutes ?? 180),
                  Icons.nightlight,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 수면 패턴 그래프
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
                        Icons.show_chart,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '수면 패턴',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: SleepPatternChart(data: _sleepData),
                  ),
                  const SizedBox(height: 15),
                  _buildLegend(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 수면 분석 인사이트
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
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '수면 인사이트',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildInsightItem(
                    '✅ 수면 주기가 규칙적입니다',
                    '약 90분 주기로 렘수면이 반복되고 있어요.',
                  ),
                  const SizedBox(height: 10),
                  _buildInsightItem(
                    '💤 깊은 잠이 ${_report != null && _report!.deepSleepMinutes > 120 ? "충분합니다" : "부족합니다"}',
                    '깊은 수면: ${_formatMinutes(_report?.deepSleepMinutes ?? 150)}',
                  ),
                  const SizedBox(height: 10),
                  _buildInsightItem(
                    '🌅 수면 효율',
                    '${((_report?.sleepEfficiency ?? 0.85) * 100).toStringAsFixed(0)}% - ${(_report?.sleepEfficiency ?? 0.85) >= 0.8 ? "양호" : "개선 필요"}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}시간 ${mins}분';
    }
    return '${mins}분';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('REM (얕은잠)', Colors.lightBlue),
        _buildLegendItem('얕은잠', Colors.blue),
        _buildLegendItem('깊은잠', Colors.indigo),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class SleepData {
  final int minute;
  final double depth;

  SleepData(this.minute, this.depth);
}

class SleepPatternChart extends StatelessWidget {
  final List<SleepData> data;

  const SleepPatternChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SleepChartPainter(data),
      child: Container(),
    );
  }
}

class SleepChartPainter extends CustomPainter {
  final List<SleepData> data;

  SleepChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final path = Path();

    if (data.isEmpty) return;

    final xStep = size.width / (data.length - 1);
    final yScale = size.height / 5;

    path.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = data[i].depth * yScale;

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.indigo.withOpacity(0.8),
        Colors.blue.withOpacity(0.6),
        Colors.lightBlue.withOpacity(0.3),
      ],
    );

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = data[i].depth * yScale;

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    canvas.drawPath(linePath, linePaint);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 1; i <= 5; i++) {
      final y = i * yScale;
      final stageName = i == 1 ? 'REM' : i <= 2 ? '얕음' : '깊음';

      textPainter.text = TextSpan(
        text: stageName,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-35, y - 6));
    }

    for (int i = 0; i <= data.length ~/ 60; i += 2) {
      final x = (i * 60) * xStep;
      textPainter.text = TextSpan(
        text: '${i}h',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 10, size.height + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}