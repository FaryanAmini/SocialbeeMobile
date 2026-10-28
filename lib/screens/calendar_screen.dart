// REPLACE THIS I WANT TO UNDERSTAND THIS ONE WELL
// NEED TO MAKE THIS MY OWN
// MAYBE USE PLUG IN
// I DONT WANT TO MAINTAIN MY OWN CALENDAR

// calendar_screen.dart — the month view.
//
// The UI keeps its own small list of events, seeded from AppState.
// The big idea of this page: the grid IS the picker. Tapping an empty
// slot opens scheduling pre-filled to that day and hour. Two taps total
// to schedule from anywhere in the month.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dates.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';
import 'schedule_screen.dart';

// An event on this calendar. Simple on purpose: this demo has no real
// calendar data, so entries are just a day, an hour and a title.
class CalendarEvent {
  CalendarEvent({required this.day, required this.hour, required this.title});

  DateTime day;
  int hour; // 8..22, the hours the app offers
  String title;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<CalendarEvent> events = <CalendarEvent>[];
  int weekOffset = 0; // 0 = this week, 1 = next week, ...

  // Flutter rule: you may not read an InheritedWidget (AppScope.of) inside
  // initState(). didChangeDependencies() runs right after initState, when it
  // IS allowed. The _seeded flag keeps this "once at startup" behaviour.
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      _seeded = true;
      _seedFromAppState();
    }
  }

  // One-time copy of the planned hangouts so this page can also let the
  // user move events around without touching the Home data model.
  void _seedFromAppState() {
    AppState app = AppScope.of(context);
    for (PlannedHangout h in app.hangouts) {
      if (h.when != null) {
        events.add(
          CalendarEvent(
            day: DateTime(h.when!.year, h.when!.month, h.when!.day),
            hour: h.when!.hour,
            title: h.title,
          ),
        );
      }
    }
  }

  // The seven days of the currently-shown week, Monday first.
  List<DateTime> visibleWeek() {
    DateTime now = DateTime.now();
    DateTime monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    DateTime start = monday.add(Duration(days: weekOffset * 7));
    return <DateTime>[for (int i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> days = visibleWeek();

    // A rough count for the subtitle. (Real app: days in this week with
    // something on them.)
    int busyDays = 0;
    for (DateTime d in days) {
      if (events.any((CalendarEvent e) => _sameDay(e.day, d))) {
        busyDays++;
      }
    }

    return PageScaffold(
      title: 'Calendar',
      subtitle: '$busyDays busy this week · tap a slot to schedule',
      actions: <Widget>[
        CircleIconButton(
          icon: Icons.chevron_left_rounded,
          size: 36,
          onPressed: weekOffset == 0
              ? null // can't go before this week
              : () => setState(() => weekOffset--),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.chevron_right_rounded,
          size: 36,
          onPressed: () => setState(() => weekOffset++),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // --- the week strip: 7 clickable days ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                children: <Widget>[
                  for (DateTime d in days)
                    Expanded(
                      child: _DayColumn(day: d, events: events),
                    ),
                ],
              ),
            ),
          ),

          const SectionLabel('Day slots'),

          // --- hour rows; tap an empty intersection = schedule ------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, listBottomPadding),
              children: <Widget>[
                for (int hour = 8; hour <= 22; hour += 2)
                  _HourRow(
                    hour: hour,
                    days: days,
                    events: events,
                    onTapEmptySlot: (DateTime day, int tappedHour) {
                      // THE shortcut: one tap opens scheduling, pre-filled.
                      openScheduleScreen(
                        context,
                        initialWhen: DateTime(
                          day.year,
                          day.month,
                          day.day,
                          tappedHour,
                        ),
                      );
                    },
                    onTapEvent: (CalendarEvent e) {
                      setState(() => e.hour = _nextHourSlot(e.hour));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Nudge an event forward one slot (8 -> 10 -> ... -> 22 -> 8).
  int _nextHourSlot(int hour) => hour >= 22 ? 8 : hour + 2;
}

// One of the seven columns in the week strip.
class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day, required this.events});

  final DateTime day;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    int count = events
        .where(
          (CalendarEvent e) =>
              e.day.year == day.year &&
              e.day.month == day.month &&
              e.day.day == day.day,
        )
        .length;

    return Column(
      children: <Widget>[
        Text(
          weekdayNames[day.weekday - 1],
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? AppColors.accent : Colors.white.withAlpha(12),
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isToday ? AppColors.accentInk : AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Little event dots so you see the load at a glance.
        SizedBox(
          height: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < count && i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// One hour row: hour label on the left, seven tappable cells.
class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.hour,
    required this.days,
    required this.events,
    required this.onTapEmptySlot,
    required this.onTapEvent,
  });

  final int hour;
  final List<DateTime> days;
  final List<CalendarEvent> events;
  final void Function(DateTime day, int hour) onTapEmptySlot;
  final void Function(CalendarEvent event) onTapEvent;

  String get hourLabel {
    int h = hour % 12;
    if (h == 0) h = 12;
    return hour < 12 ? '$h AM' : '$h PM';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        // The cells are 44px tall, so the row is 44px tall too. (stretch
        // would break inside a ListView — heights must come from children.)
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 52,
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(hourLabel, style: Texts.meta),
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                for (DateTime day in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _SlotCell(
                        day: day,
                        hour: hour,
                        event: _eventAt(day, hour),
                        onTapEmptySlot: onTapEmptySlot,
                        onTapEvent: onTapEvent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CalendarEvent? _eventAt(DateTime day, int hour) {
    for (CalendarEvent e in events) {
      bool sameDay =
          e.day.year == day.year &&
          e.day.month == day.month &&
          e.day.day == day.day;
      if (sameDay && e.hour == hour) {
        return e;
      }
    }
    return null;
  }
}

// A single day/hour intersection. Empty = a dashed-feel glass cell that
// schedules on tap; filled = an amber cell that moves the event forward.
class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.day,
    required this.hour,
    required this.event,
    required this.onTapEmptySlot,
    required this.onTapEvent,
  });

  final DateTime day;
  final int hour;
  final CalendarEvent? event;
  final void Function(DateTime day, int hour) onTapEmptySlot;
  final void Function(CalendarEvent event) onTapEvent;

  @override
  Widget build(BuildContext context) {
    if (event != null) {
      return GestureDetector(
        onTap: () => onTapEvent(event!),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.accent.withAlpha(46),
            border: Border.all(color: AppColors.accent),
          ),
          padding: const EdgeInsets.all(4),
          child: Text(
            event!.title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTapEmptySlot(day, hour),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withAlpha(5),
          border: Border.all(color: Colors.white.withAlpha(14)),
        ),
      ),
    );
  }
}
