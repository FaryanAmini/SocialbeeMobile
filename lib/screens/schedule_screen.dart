// schedule_screen.dart — "who, what, when" in one sheet
//

// The whole point of the design scheduling takes exactly four taps after
// opening — tap a friend, tap an idea (which also writes the event name),
// tap a day, tap an hour, then Confirm.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dates.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';

// Call this from anywhere
void openScheduleScreen(
  BuildContext context, {
  List<Friend>? preselect,
  DateTime? initialWhen,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (BuildContext sheetContext) {
      return Padding(
        // The sheet should cover most of the screen but always fit it,
        // even on small windows.
        padding: const EdgeInsets.fromLTRB(12, 60, 12, 12),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.4,
          maxChildSize: 0.94,
          builder: (BuildContext _, ScrollController controller) {
            return ScheduleSheet(
              controller: controller,
              preselect: preselect,
              initialWhen: initialWhen,
            );
          },
        ),
      );
    },
  );
}

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({
    super.key,
    required this.controller,
    this.preselect,
    this.initialWhen,
  });

  final ScrollController controller;
  final List<Friend>? preselect;
  final DateTime? initialWhen;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  // Three separate simple "selection" variables. No fancy state machine.
  List<Friend> chosenFriends = <Friend>[];
  String title = '';
  DateTime? chosenDay;
  int? chosenHour;

  // Ideas the user can tap instead of typing. Tapping one also sets title.
  static const List<String> ideas = <String>[
    'Coffee',
    'Dinner',
    'Study',
    'Gym',
    'Movie',
    'Walk',
    'Brunch',
    'Games',
  ];

  // Hours shown in the time row, 8am through 10pm.
  static const List<int> hours = <int>[8, 10, 12, 14, 16, 18, 20, 22];

  @override
  void initState() {
    super.initState();
    if (widget.preselect != null) {
      chosenFriends = List<Friend>.from(widget.preselect!);
    }
    if (widget.initialWhen != null) {
      chosenDay = DateTime(
        widget.initialWhen!.year,
        widget.initialWhen!.month,
        widget.initialWhen!.day,
      );
      chosenHour = widget.initialWhen!.hour;
    }
  }

  bool get canConfirm =>
      chosenFriends.isNotEmpty &&
      title.isNotEmpty &&
      chosenDay != null &&
      chosenHour != null;

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);

    // The next 7 days as selectable day chips, starting today.
    List<DateTime> days = <DateTime>[];
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      days.add(DateTime(now.year, now.month, now.day + i));
    }

    return GlassCard(
      radius: 28,
      padding: EdgeInsets.zero,
      child: ListView(
        controller: widget.controller,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        children: <Widget>[
          const Center(child: SheetGrabber()),
          const SizedBox(height: 14),
          const Text('Schedule a hangout', style: Texts.bigTitle),

          // --- WHO -------------------------------------------------------
          const SectionLabel('Who'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (Friend f in app.configuredFriends)
                _FriendToggle(
                  friend: f,
                  selected: chosenFriends.contains(f),
                  onTap: () {
                    setState(() {
                      if (chosenFriends.contains(f)) {
                        chosenFriends.remove(f);
                      } else {
                        chosenFriends.add(f);
                      }
                    });
                  },
                ),
            ],
          ),

          // --- WHAT ------------------------------------------------------
          const SectionLabel('What'),
          TextField(
            style: Texts.body,
            decoration: InputDecoration(
              hintText: 'Dinner, study, walk...',
              hintStyle: const TextStyle(color: AppColors.muted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onChanged: (String value) => title = value,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (String idea in ideas)
                TapPill(
                  label: idea,
                  onTap: () {
                    setState(() => title = idea);
                  },
                ),
            ],
          ),

          // --- WHEN ------------------------------------------------------
          const SectionLabel('When'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (DateTime day in days)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _DayChip(
                      day: day,
                      selected:
                          chosenDay != null &&
                          chosenDay!.year == day.year &&
                          chosenDay!.month == day.month &&
                          chosenDay!.day == day.day,
                      onTap: () => setState(() => chosenDay = day),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (int hour in hours)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TapPill(
                      label: _hourLabel(hour),
                      selected: chosenHour == hour,
                      onTap: () => setState(() => chosenHour = hour),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          AppButton(
            label: 'Confirm',
            onPressed: canConfirm
                ? () {
                    DateTime when = DateTime(
                      chosenDay!.year,
                      chosenDay!.month,
                      chosenDay!.day,
                      chosenHour!,
                      0,
                    );
                    app.scheduleHangout(
                      PlannedHangout(
                        id: 'p${DateTime.now().microsecondsSinceEpoch}',
                        friends: List<Friend>.from(chosenFriends),
                        bucket: _bucketFor(when),
                        when: when,
                        activity: title,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // Soon = within a week; Later = beyond that. (Spec: "within the next
  // 7 days counts as soon.")
  HangoutBucket _bucketFor(DateTime when) {
    int days = when.difference(DateTime.now()).inDays;
    if (days <= 7) {
      return HangoutBucket.soon;
    }
    return HangoutBucket.later;
  }

  static String _hourLabel(int hour24) {
    int h = hour24 % 12;
    if (h == 0) h = 12;
    return hour24 < 12 ? '$h AM' : '$h PM';
  }
}

// A friend bubble in the WHO section. Frosted when off, amber when on.
class _FriendToggle extends StatelessWidget {
  const _FriendToggle({
    required this.friend,
    required this.selected,
    required this.onTap,
  });

  final Friend friend;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppColors.accent.withAlpha(40)
              : Colors.white.withAlpha(12),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white.withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Avatar(friend, size: 24, showRelationship: false),
            const SizedBox(width: 6),
            Text(
              friend.shortName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A selectable day square: "Mon / 28".
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected
              ? AppColors.accent.withAlpha(40)
              : Colors.white.withAlpha(12),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white.withAlpha(30),
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(
              weekdayNames[day.weekday - 1],
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.accent : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A plain text pill button used for ideas and hours.
// (The name is silly-simple on purpose: it is just a label you can tap.)
class TapPill extends StatelessWidget {
  const TapPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? AppColors.accent.withAlpha(40)
              : Colors.white.withAlpha(12),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white.withAlpha(28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
