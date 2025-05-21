// lib/pages/main/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/activity_tracker_service.dart';
import '../../services/sleep_tracker_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0; // 0 = Activity, 1 = Sleep
  bool _showChart = false;
  DateTime _day = DateTime.now();

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final act = context.read<ActivityTrackerService>();
      final slp = context.read<SleepTrackerService>();

      await act.refreshFromHealth(context);
      await act.loadActivityForDate(_day);
      await slp.loadSleepForDate(_day);

      await act.loadWeek(_mondayOf(_day));
      await slp.loadWeek(_mondayOf(_day));
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

              await act.refreshFromHealth(context);
              await slp.loadSleepForDate(_day);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Обновлено: шагов ${act.steps}, сон ${slp.totalMinutes} мин")),
              );
            },
            child: Consumer2<ActivityTrackerService, SleepTrackerService>(
              builder: (_, st, sl, __) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // оставь всё как есть внутри Column
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.share, color: Colors.white),
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
                                const Icon(Icons.arrow_drop_down, color: Colors.white),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.settings, color: Colors.white),
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
                        child: isAct
                            ? _ActivityRingChart(
                          key: ValueKey(_showChart),
                          showChart: _showChart,
                          st: st,
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: isAct
                          ? _ActivityStats(st: st, selectedDate: _day)
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

/* small widgets */

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

class _ActivityRingChart extends StatelessWidget {
  final bool showChart;
  final ActivityTrackerService st;

  const _ActivityRingChart({
    Key? key,
    required this.showChart,
    required this.st,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    if (showChart) return _Bar(steps: st.stepsByHour);

    final pct = (st.steps / 10000).clamp(0.0, 1.0);
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -120),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.orangeAccent, width: 3),
              ),
            ),
          ),
          CircularPercentIndicator(
            radius: 120,
            lineWidth: 18,
            percent: pct,
            backgroundColor: Colors.white24,
            progressColor: Colors.white,
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  '${st.steps}',
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'steps',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final List<int> steps;

  const _Bar({required this.steps});

  @override
  Widget build(BuildContext ctx) {
    final max = steps.fold<int>(0, (p, e) => e > p ? e : p);
    final maxY = ((max + 199) ~/ 200) * 200 + 200;
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: BarChart(
            BarChartData(
              maxY: maxY.toDouble(),
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(
                horizontalInterval: maxY / 3,
                drawVerticalLine: false,
                getDrawingHorizontalLine:
                    (v) => FlLine(color: Colors.white30, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 40,
                    interval: maxY / 3,
                    showTitles: true,
                    getTitlesWidget:
                        (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    interval: 4,
                    showTitles: true,
                    getTitlesWidget:
                        (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < 24; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: steps[i].toDouble(),
                        width: 4,
                        color: Colors.white.withOpacity(
                          steps[i] > 0 ? 0.9 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${steps.fold<int>(0, (s, e) => s + e)} steps',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SleepRing extends StatelessWidget {
  final SleepTrackerService sl;

  const _SleepRing({Key? key, required this.sl}) : super(key: key);

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

/* ----- white area stats ----- */
class _ActivityStats extends StatelessWidget {
  final ActivityTrackerService st;
  final DateTime selectedDate;

  const _ActivityStats({required this.st, required this.selectedDate});

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final added = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add steps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 500'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (added != null && added > 0) {
      st.setSteps(st.steps + added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cal = (st.steps * 0.04).toInt();
    final dist = st.steps * 0.0008;
    final mins = (st.steps / 100).round();

    return Column(
      children: [
        Row(
          children: [
            _Card(Icons.local_fire_department, 'Calories', '$cal', 'kcal', Colors.deepOrange),
            _Card(Icons.place, 'Distance', dist.toStringAsFixed(2), 'km', Colors.blueAccent),
            _Card(Icons.timer, 'Duration', '$mins', 'min', Colors.amber),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await st.saveActivity(selectedDate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Day saved')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save day'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add steps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _SleepStats extends StatelessWidget {
  final SleepTrackerService sl;

  const _SleepStats({required this.sl});

  @override
  Widget build(BuildContext ctx) => Row(
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
