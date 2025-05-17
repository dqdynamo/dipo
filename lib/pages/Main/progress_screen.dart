import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/step_tracker_service.dart';
import '../../services/sleep_tracker_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _tab = 0; // 0 = Activity, 1 = Sleep
  late DateTime _monday; // начало выбранной недели

  @override
  void initState() {
    super.initState();
    _monday = _getMonday(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StepTrackerService>().loadWeek(_monday);
      context.read<SleepTrackerService>().loadWeek(_monday);
    });
  }

  /// переводит любую дату к понедельнику той же недели
  DateTime _getMonday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  /* выбор недели через date-picker */
  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monday,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
      locale: const Locale('en'),
    );
    if (picked != null) {
      final mon = _getMonday(picked);
      setState(() => _monday = mon);
      context.read<StepTrackerService>().loadWeek(mon);
      context.read<SleepTrackerService>().loadWeek(mon);
    }
  }

  String get _rangeLabel {
    final fmt = DateFormat('MM/dd');
    final sun = _monday.add(const Duration(days: 6));
    return '${fmt.format(_monday)}-${fmt.format(sun)}';
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
          child: Consumer2<StepTrackerService, SleepTrackerService>(
            builder: (_, st, sl, __) {
              final weekSteps = st.weeklySteps(_monday); // 7 int
              final weekSleep = sl.weeklySleep(_monday); // 7 int (минуты)
              return Column(
                children: [
                  /* ----- header ----- */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickWeek,
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              _tab == 0 ? 'This week' : 'This week',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _rangeLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  /* ----- график ----- */
                  SizedBox(
                    height: 240,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _WeekChart(
                        data: isAct ? weekSteps : weekSleep,
                        isActivity: isAct,
                      ),
                    ),
                  ),

                  /* дни недели подпись */
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _Day('Mon'),
                        _Day('Tue'),
                        _Day('Wed'),
                        _Day('Thu'),
                        _Day('Fri'),
                        _Day('Sat'),
                        _Day('Sun'),
                      ],
                    ),
                  ),

                  /* ----- вкладки ----- */
                  Row(
                    children: [
                      _Tab('Activity', isAct, () {
                        setState(() => _tab = 0);
                      }),
                      _Tab('Sleep', !isAct, () {
                        setState(() => _tab = 1);
                      }),
                    ],
                  ),

                  /* ----- статистика ----- */
                  Expanded(
                    child: Container(
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
                              ? _ActivityWeekStats(data: weekSteps)
                              : _SleepWeekStats(data: weekSleep),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/* ═════════════ widgets ═════════════ */

class _Day extends StatelessWidget {
  final String t;

  const _Day(this.t);

  @override
  Widget build(BuildContext c) =>
      Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12));
}

class _Tab extends StatelessWidget {
  final String t;
  final bool sel;
  final VoidCallback tap;

  const _Tab(this.t, this.sel, this.tap);

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
          t,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _WeekChart extends StatelessWidget {
  final List<int> data;
  final bool isActivity;

  const _WeekChart({required this.data, required this.isActivity});

  @override
  Widget build(BuildContext ctx) {
    final max = data.fold<int>(0, (p, e) => e > p ? e : p);
    final maxY = ((max + 999) ~/ 1000) * 1000 + 1000;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY.toDouble(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 4,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (v) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 40,
              interval: maxY / 4,
              showTitles: true,
              getTitlesWidget:
                  (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), data[i].toDouble())
            ],
            isCurved: false,
            barWidth: 2,
            color: Colors.white,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeColor: Colors.white,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----- white stats area ----- */
class _ActivityWeekStats extends StatelessWidget {
  final List<int> data;

  const _ActivityWeekStats({required this.data});

  @override
  Widget build(BuildContext ctx) {
    final totalSteps = data.fold<int>(0, (s, e) => s + e);
    final totalDistance = totalSteps * 0.0008;
    final totalCal = (totalSteps * 0.04).toInt();

    final avgSteps = (totalSteps / 7).round();
    final avgDistance = totalDistance / 7;
    final avgCal = (totalCal / 7).round();

    return Column(
      children: [
        Row(
          children: [
            _Item(
              'Distance\nthis week',
              '${totalDistance.toStringAsFixed(2)}',
              'km',
            ),
            _Item('Steps\nthis week', '$totalSteps', 'steps'),
            _Item('Calories\nthis week', '$totalCal', 'kcal'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Item(
              'Avg distance / day',
              '${avgDistance.toStringAsFixed(2)}',
              'km',
            ),
            _Item('Avg steps / day', '$avgSteps', 'steps'),
            _Item('Avg calories / day', '$avgCal', 'kcal'),
          ],
        ),
      ],
    );
  }
}

class _SleepWeekStats extends StatelessWidget {
  final List<int> data;

  const _SleepWeekStats({required this.data});

  @override
  Widget build(BuildContext ctx) {
    final totalMin = data.fold<int>(0, (s, e) => s + e);
    final h = (totalMin / 60).floor();
    final m = totalMin % 60;

    final avg = (totalMin / 7).round();
    final ah = (avg / 60).floor();
    final am = avg % 60;

    return Column(
      children: [
        Row(
          children: [
            _Item('Total sleep\nthis week', '${h}h${m}m', ''),
            _Item('Avg sleep\nper day', '${ah}h${am}m', ''),
            const _Item('Avg wake-up\n', '00:00', ''),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _Item('Avg time\nin bed', '00:00', ''),
            _Item('Avg deep\nsleep', '0h0m', ''),
            _Item('Avg awake\nperiods', '0', ''),
          ],
        ),
      ],
    );
  }
}

/* карточка-текст */
class _Item extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Item(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
