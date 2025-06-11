import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/activity_tracker_service.dart';
import '../../services/goal_service.dart';
import 'goal_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _day = DateTime.now();
  int _goalSteps = 0;
  final ScreenshotController _screenshotController = ScreenshotController();

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final goalService = GoalService();
      final goal = await goalService.loadGoals();
      setState(() {
        _goalSteps = goal.steps;
      });

      final activity = context.read<ActivityTrackerService>();
      activity.loadActivityForDate(_day);
      activity.loadWeek(_mondayOf(_day));
      activity.refreshFromHealth();
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
    }
  }

  String get _label {
    final today = DateFormat.yMMMMd('en').format(DateTime.now());
    final picked = DateFormat.yMMMMd('en').format(_day);
    return picked == today ? tr('dashboard_today') : picked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final grad = isDark
        ? [const Color(0xFF22212C), const Color(0xFF2E294E)]
        : [const Color(0xFFFF9240), const Color(0xFFDD4733)];

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Consumer<ActivityTrackerService>(
              builder: (_, st, __) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.flag, color: isDark ? Colors.white : Colors.white),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GoalScreen(),
                              ),
                            );
                            final goalService = GoalService();
                            final goal = await goalService.loadGoals();
                            setState(() {
                              _goalSteps = goal.steps;
                            });
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Row(
                            children: [
                              Text(
                                _label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.white),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.share, color: isDark ? Colors.white : Colors.white),
                          onPressed: () async {
                            try {
                              final image = await _screenshotController.capture();
                              if (image == null) return;

                              final directory = await getTemporaryDirectory();
                              final imagePath = await File('${directory.path}/activity_share.png').create();
                              await imagePath.writeAsBytes(image);

                              await Share.shareXFiles(
                                [XFile(imagePath.path)],
                                text: tr('dashboard_share_text'),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('dashboard_error_screenshot', namedArgs: {'error': e.toString()}))),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _ActivityChart(st: st, goalSteps: _goalSteps),
                  const SizedBox(height: 20),
                  _SyncButton(onSync: () async {
                    await context.read<ActivityTrackerService>().refreshFromHealth();
                    context.read<ActivityTrackerService>().loadActivityForDate(_day);
                    context.read<ActivityTrackerService>().loadWeek(_mondayOf(_day));
                  }),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF191825) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.09)
                              : theme.shadowColor.withOpacity(0.09),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: _ActivityStats(st: st),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final ActivityTrackerService st;
  final int goalSteps;

  const _ActivityChart({required this.st, required this.goalSteps});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    final pct = goalSteps > 0 ? (st.steps / goalSteps).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: 320,
      child: CircularPercentIndicator(
        radius: 150,
        lineWidth: 20,
        percent: pct,
        backgroundColor: isDark ? Colors.white24 : Colors.white24,
        progressColor: isDark ? Colors.white : theme.colorScheme.primary,
        circularStrokeCap: CircularStrokeCap.round,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk, color: isDark ? Colors.white : theme.colorScheme.primary, size: 42),
            const SizedBox(height: 8),
            Text(
              '${st.steps}',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : theme.colorScheme.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                tr('dashboard_steps'),
                style: TextStyle(
                  color: isDark ? Colors.white70 : theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              tr('dashboard_goal', namedArgs: {'goal': goalSteps.toString()}),
              style: TextStyle(color: isDark ? Colors.white70 : theme.colorScheme.primary, fontSize: 14),
            ),
            Text(
              tr('dashboard_completed', namedArgs: {'percent': (100 * pct).round().toString()}),
              style: TextStyle(color: isDark ? Colors.white70 : theme.colorScheme.primary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}


class _ActivityStats extends StatelessWidget {
  final ActivityTrackerService st;

  const _ActivityStats({required this.st});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cal = (st.steps * 0.04).toInt();
    final dist = st.steps * 0.0008;
    final mins = (st.steps / 100).round();

    return Row(
      children: [
        _Card(
          Icons.local_fire_department,
          tr('dashboard_calories'),
          '$cal',
          tr('dashboard_kcal'),
          isDark ? Colors.white : theme.colorScheme.primary,
          isDark: isDark,
        ),
        _Card(
          Icons.place,
          tr('dashboard_distance'),
          dist.toStringAsFixed(2),
          tr('dashboard_km'),
          isDark ? Colors.white : theme.colorScheme.secondary,
          isDark: isDark,
        ),
        _Card(
          Icons.timer,
          tr('dashboard_duration'),
          '$mins',
          tr('dashboard_min'),
          isDark ? Colors.white : Colors.pinkAccent,
          isDark: isDark,
        ),
      ],
    );
  }
}


class _Card extends StatelessWidget {
  final IconData ic;
  final String label, val, unit;
  final Color col;
  final bool isDark;

  const _Card(this.ic, this.label, this.val, this.unit, this.col, {this.isDark = false});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191825) : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: col.withOpacity(isDark ? 0.07 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: col.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(ic, color: col, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              '$val $unit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : col,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncButton extends StatefulWidget {
  final Future<void> Function() onSync;

  const _SyncButton({required this.onSync});

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  bool _loading = false;

  Future<void> _sync() async {
    setState(() => _loading = true);
    try {
      await widget.onSync();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : theme.colorScheme.onPrimary,
        backgroundColor: isDark ? Colors.white10 : Colors.white24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: _loading ? null : _sync,
      icon: _loading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
          : Icon(Icons.sync, color: isDark ? Colors.white : theme.colorScheme.primary),
      label: Text(
        _loading ? tr('dashboard_syncing') : tr('dashboard_sync_steps'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : theme.colorScheme.primary,
        ),
      ),
    );
  }
}

