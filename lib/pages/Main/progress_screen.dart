// lib/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/activity_tracker_service.dart';
import '../../services/sleep_tracker_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _tab = 0; // 0 = Activity, 1 = Sleep
  int _period = 0; // 0 = Week, 1 = Month, 2 = Year
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final activityService = context.read<ActivityTrackerService>();
    final sleepService = context.read<SleepTrackerService>();
    switch (_period) {
      case 0:
        final monday = _getMonday(_selectedDate);
        activityService.loadWeek(monday);
        sleepService.loadWeek(monday);
        break;
      case 1:
        final monthStart = DateTime(_selectedDate.year, _selectedDate.month);
        activityService.loadMonth(monthStart);
        sleepService.loadMonth(monthStart);
        break;
      case 2:
        final year = _selectedDate.year;
        activityService.loadYear(year);
        sleepService.loadYear(year);
        break;
    }
  }

  DateTime _getMonday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  String get _rangeLabel {
    final fmt = DateFormat('MM/dd');
    switch (_period) {
      case 0:
        final monday = _getMonday(_selectedDate);
        final sunday = monday.add(const Duration(days: 6));
        return '${fmt.format(monday)}-${fmt.format(sunday)}';
      case 1:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 2:
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
      locale: const Locale('en'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }



  @override
  Widget build(BuildContext context) {
    final isAct = _tab == 0;
    final grad = isAct
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
          child: Consumer2<ActivityTrackerService, SleepTrackerService>(
            builder: (_, st, sl, __) {
              List<int> data;
              switch (_period) {
                case 0:
                  final monday = _getMonday(_selectedDate);
                  data =
                  isAct ? st.weeklySteps(monday) : sl.weeklySleep(monday);
                  break;
                case 1:
                  final monthStart = DateTime(
                      _selectedDate.year, _selectedDate.month);
                  data = isAct ? st.monthlySteps(monthStart) : sl.monthlySleep(
                      monthStart);
                  break;
                case 2:
                  final year = _selectedDate.year;
                  data = isAct ? st.yearlySteps(year) : sl.yearlySleep(DateTime(year));
                  break;
                default:
                  data = [];
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickDate,
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              _period == 0
                                  ? 'This week'
                                  : _period == 1
                                  ? 'This month'
                                  : 'This year',
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
                  SizedBox(
                    height: 240,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _Chart(
                        data: data,
                        isActivity: isAct,
                        period: _period,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _buildLabels(),
                    ),
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PeriodButton('Week', _period == 0, () {
                        setState(() => _period = 0);
                        _loadData();
                      }),
                      _PeriodButton('Month', _period == 1, () {
                        setState(() => _period = 1);
                        _loadData();
                      }),
                      _PeriodButton('Year', _period == 2, () {
                        setState(() => _period = 2);
                        _loadData();
                      }),
                    ],
                  ),
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
                      child: isAct
                          ? _ActivityStats(data: data, period: _period)
                          : _SleepStats(data: data, period: _period),
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

  List<Widget> _buildLabels() {
    switch (_period) {
      case 0:
        return const [
          _Day('Mon'),
          _Day('Tue'),
          _Day('Wed'),
          _Day('Thu'),
          _Day('Fri'),
          _Day('Sat'),
          _Day('Sun'),
        ];
      case 1:
        final daysInMonth = DateTime(
            _selectedDate.year, _selectedDate.month + 1, 0).day;
        return List.generate(daysInMonth, (i) => _Day('${i + 1}'));
      case 2:
        return const [
          _Day('Jan'),
          _Day('Feb'),
          _Day('Mar'),
          _Day('Apr'),
          _Day('May'),
          _Day('Jun'),
          _Day('Jul'),
          _Day('Aug'),
          _Day('Sep'),
          _Day('Oct'),
          _Day('Nov'),
          _Day('Dec'),
        ];
      default:
        return [];
    }
  }
}

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
  Widget build(BuildContext c) =>
      Expanded(
        child: GestureDetector(
          onTap: tap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: sel
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

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<int> data;
  final bool isActivity;
  final int period;

  const _Chart({
    required this.data,
    required this.isActivity,
    required this.period,
  });

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
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 40,
              interval: maxY / 4,
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
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
            spots: List.generate(
              data.length,
                  (i) => FlSpot(i.toDouble(), data[i].toDouble()),
            ),
            isCurved: false,
            barWidth: 2,
            color: Colors.white,
            dotData: FlDotData(
              show: true,
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
    );
  }
}

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


class _ActivityStats extends StatelessWidget {
  final List<int> data;
  final int period;

  const _ActivityStats({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final totalSteps = data.fold<int>(0, (s, e) => s + e);
    final totalDistance = totalSteps * 0.0008;
    final totalCal = (totalSteps * 0.04).toInt();

    final count = data.where((e) => e > 0).length;
    final avgSteps = count > 0 ? (totalSteps / count).round() : 0;
    final avgDistance = count > 0 ? totalDistance / count : 0;
    final avgCal = count > 0 ? (totalCal / count).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            _Item('Distance', totalDistance.toStringAsFixed(2), 'km'),
            _Item('Steps', '$totalSteps', 'steps'),
            _Item('Calories', '$totalCal', 'kcal'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Item('Avg dist/day', avgDistance.toStringAsFixed(2), 'km'),
            _Item('Avg steps/day', '$avgSteps', 'steps'),
            _Item('Avg cal/day', '$avgCal', 'kcal'),
          ],
        ),
      ],
    );
  }
}

class _SleepStats extends StatelessWidget {
  final List<int> data;
  final int period;

  const _SleepStats({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final totalMin = data.fold<int>(0, (s, e) => s + e);
    final h = (totalMin / 60).floor();
    final m = totalMin % 60;

    final count = data.where((e) => e > 0).length;
    final avg = count > 0 ? (totalMin / count).round() : 0;
    final ah = (avg / 60).floor();
    final am = avg % 60;

    return Column(
      children: [
        Row(
          children: [
            _Item('Total sleep', '${h}h${m}m', ''),
            _Item('Avg sleep/day', '${ah}h${am}m', ''),
            const _Item('Wake-up', '00:00', ''),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _Item('Time in bed', '00:00', ''),
            _Item('Deep sleep', '0h0m', ''),
            _Item('Awake periods', '0', ''),
          ],
        ),
      ],
    );
  }
}
