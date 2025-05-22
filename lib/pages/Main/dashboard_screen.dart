// lib/pages/main/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/activity_tracker_service.dart';
import '../../services/goal_service.dart';
import '../../services/sleep_tracker_service.dart';
import 'goal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  bool _showChart = false;
  DateTime _day = DateTime.now();
  int _goalSteps = 10000;

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  void _showAddStepsDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Steps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of steps',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              final input = int.tryParse(controller.text);
              if (input != null && input > 0) {
                final tracker = context.read<ActivityTrackerService>();
                tracker.addSteps(input);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $input steps')),
                );
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final goalService = GoalService();
      final goal = await goalService.loadGoals();
      setState(() {
        _goalSteps = goal.steps;
      });

      context.read<ActivityTrackerService>().loadActivityForDate(_day);
      context.read<SleepTrackerService>().loadSleepForDate(_day);
      context.read<ActivityTrackerService>().loadWeek(_mondayOf(_day));
      context.read<SleepTrackerService>().loadWeek(_mondayOf(_day));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('en'),
    );
    if (picked != null) {
      setState(() => _day = picked);
      context.read<ActivityTrackerService>().loadActivityForDate(picked);
      context.read<SleepTrackerService>().loadSleepForDate(picked);
    }
  }

  String get _label {
    final today = DateFormat.yMMMMd('en').format(DateTime.now());
    final picked = DateFormat.yMMMMd('en').format(_day);
    return picked == today ? 'Today' : picked;
  }

  @override
  Widget build(BuildContext context) {
    final isAct = _tab == 0;
    final grad =
        isAct
            ? const [Color(0xFFFF9240), Color(0xFFDD4733)]
            : const [Color(0xFF35B4FF), Color(0xFF0D63C9)];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              final act = context.read<ActivityTrackerService>();
              final slp = context.read<SleepTrackerService>();

              await act.refreshFromHealth();
              await slp.refreshFromHealth();

              // Save both updated records to Firestore
              await act.saveActivity(_day);
              await slp.saveSleep(_day);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Updated: ${act.steps} steps, ${slp.totalMinutes} min sleep, ${act.avgHeartRate} bpm",
                  ),
                ),
              );
            },
            child: Consumer2<ActivityTrackerService, SleepTrackerService>(
              builder:
                  (_, st, sl, __) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  final activity =
                                      context.read<ActivityTrackerService>();
                                  final sleep =
                                      context.read<SleepTrackerService>();

                                  final sleepHours =
                                      (sleep.totalMinutes / 60).floor();
                                  final sleepMinutes = sleep.totalMinutes % 60;

                                  final shareText = '''
📊 My fitness progress today:

🚶 Steps: ${activity.steps}
🔥 Calories: ${activity.calories} kcal
🛌 Sleep: ${sleepHours}h ${sleepMinutes}m
❤️ Heart rate: ${activity.avgHeartRate} bpm

#MyFitnessStats
''';

                                  Share.share(shareText);
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: () => _showAddStepsDialog(context),
                              ),


                              const Spacer(),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Row(
                                  children: [
                                    Text(
                                      _label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GoalScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            if (isAct) setState(() => _showChart = !_showChart);
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child:
                                isAct
                                    ? _ActivityRingChart(
                                      key: ValueKey(_showChart),
                                      showChart: _showChart,
                                      st: st,
                                      goalSteps: _goalSteps,
                                    )
                                    : _SleepRing(
                                      key: const ValueKey('sleep'),
                                      sl: sl,
                                    ),
                          ),
                        ),
                        Row(
                          children: [
                            _Tab('Activity', isAct, () {
                              setState(() {
                                _tab = 0;
                                _showChart = false;
                              });
                            }),
                            _Tab('Sleep', !isAct, () {
                              setState(() {
                                _tab = 1;
                                _showChart = false;
                              });
                            }),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 22,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                          ),
                          child:
                              isAct
                                  ? Column(
                                    children: [
                                      Row(
                                        children: [
                                          _Card(
                                            Icons.local_fire_department,
                                            'Calories',
                                            st.calories.toString(),
                                            'kcal',
                                            Colors.deepOrange,
                                          ),
                                          _Card(
                                            Icons.place,
                                            'Distance',
                                            st.distance.toStringAsFixed(2),
                                            'km',
                                            Colors.blueAccent,
                                          ),
                                          _Card(
                                            Icons.timer,
                                            'Duration',
                                            st.activeMinutes.toString(),
                                            'min',
                                            Colors.amber,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        children: [
                                          _Card(
                                            Icons.favorite,
                                            'Heart Rate',
                                            st.avgHeartRate.toString(),
                                            'bpm',
                                            Colors.redAccent,
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : _SleepStats(sl: sl),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String text;
  final bool sel;
  final VoidCallback tap;

  const _Tab(this.text, this.sel, this.tap);

  @override
  Widget build(BuildContext c) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            sel
                ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 3),
                  ),
                )
                : null,
        child: Text(
          text,
          style: TextStyle(
            color: sel ? Colors.white : Colors.white60,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final IconData ic;
  final String label, val, unit;
  final Color col;

  const _Card(this.ic, this.label, this.val, this.unit, this.col);

  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(ic, color: col, size: 30),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          RichText(
            text: TextSpan(
              text: val,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SleepStats extends StatelessWidget {
  final SleepTrackerService sl;

  const _SleepStats({super.key, required this.sl});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Card(
        Icons.bedtime,
        'Deep',
        _f(sl.deepMinutes),
        '',
        const Color(0xFF536DFE),
      ),
      _Card(
        Icons.hotel,
        'Light',
        _f(sl.lightMinutes),
        '',
        const Color(0xFF18FFFF),
      ),
      _Card(
        Icons.wb_sunny,
        'Awake',
        _f(sl.wakeMinutes),
        '',
        const Color(0xFFFFB300),
      ),
    ],
  );

  String _f(int m) =>
      '${(m / 60).floor()}h${(m % 60).toString().padLeft(2, '0')}m';
}

class _SleepRing extends StatelessWidget {
  final SleepTrackerService sl;

  const _SleepRing({super.key, required this.sl});

  @override
  Widget build(BuildContext ctx) {
    final h = (sl.totalMinutes / 60).floor();
    final m = sl.totalMinutes % 60;
    return SizedBox(
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 235,
            height: 235,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white60, width: 2),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nightlight_round, color: Colors.white, size: 38),
              const SizedBox(height: 6),
              Text(
                '${h}h${m.toString().padLeft(2, '0')}m',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start: ${sl.sleepStart}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                'End:   ${sl.sleepEnd}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRingChart extends StatelessWidget {
  final bool showChart;
  final ActivityTrackerService st;
  final int goalSteps;

  const _ActivityRingChart({
    super.key,
    required this.showChart,
    required this.st,
    required this.goalSteps,
  });

  @override
  Widget build(BuildContext ctx) {
    if (showChart) return _HourlyStepsChart(stepsByHour: st.stepsByHour);
    final pct = (st.steps / goalSteps).clamp(0.0, 1.0);
    return SizedBox(
      height: 260,
      child: CircularPercentIndicator(
        radius: 120,
        lineWidth: 18,
        percent: pct,
        backgroundColor: Colors.white24,
        progressColor: Colors.white,
        circularStrokeCap: CircularStrokeCap.round,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              '${st.steps}',
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
              child: const Text('steps', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            Text(
              'Goal: $goalSteps',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              'Completed: ${(100 * (st.steps / goalSteps).clamp(0, 1)).round()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourlyStepsChart extends StatelessWidget {
  final List<int> stepsByHour;
  const _HourlyStepsChart({required this.stepsByHour});

  @override
  Widget build(BuildContext context) {
    final max = stepsByHour.reduce((a, b) => a > b ? a : b);
    final maxY = ((max + 199) ~/ 200) * 200 + 200;

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxY / 3,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 38,
                interval: maxY / 3,
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final v = value.toInt();
                  if (v % 4 != 0 && v != 23) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '$v',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                stepsByHour.length,
                    (i) => FlSpot(i.toDouble(), stepsByHour[i].toDouble()),
              ),
              isCurved: false,
              barWidth: 2,
              color: Colors.white,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeColor: Colors.white,
                      strokeWidth: 0,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


