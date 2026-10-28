// log that you actually completed a hangout
// another page that slides up
// logged hangouts become meomires which become lego bricks
// friend counter goes up
// streak goes up

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dates.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';

void openLogSheet(BuildContext context, List<Friend> friends) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: LogHangoutSheet(friends: friends),
      );
    },
  );
}

class LogHangoutSheet extends StatefulWidget {
  const LogHangoutSheet({super.key, required this.friends});

  final List<Friend> friends;

  @override
  State<LogHangoutSheet> createState() => _LogHangoutSheetState();
}

class _LogHangoutSheetState extends State<LogHangoutSheet> {
  // The three things we log: what it was, who was there, when it happened.
  String title = '';
  String note = '';
  List<Friend> attendees = <Friend>[];

  @override
  void initState() {
    super.initState();
    // Start with whoever the user tapped through from, pre-checked.
    attendees = List<Friend>.from(widget.friends);
  }

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);
    List<Friend> everyone = app.configuredFriends;

    return GlassCard(
      radius: 28,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Center(child: SheetGrabber()),
            const SizedBox(height: 14),
            const Text('Log a hangout', style: Texts.bigTitle),

            const SectionLabel('Who was there'),
            // Constrained height so a long friend list doesn't eat the sheet.
            SizedBox(
              height: 96,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (Friend f in everyone)
                      _AttendeeToggle(
                        friend: f,
                        selected: attendees.contains(f),
                        onTap: () {
                          setState(() {
                            if (attendees.contains(f)) {
                              attendees.remove(f);
                            } else {
                              attendees.add(f);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SectionLabel('What did you do'),
            TextField(
              style: Texts.body,
              onChanged: (String value) => title = value,
              decoration: _fieldDecoration('Ramen, bouldering, movie...'),
            ),
            const SizedBox(height: 10),
            const SectionLabel('Notes (optional)'),
            TextField(
              style: Texts.body,
              onChanged: (String value) => note = value,
              maxLines: 2,
              decoration: _fieldDecoration('The joke only you two get'),
            ),

            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: GlassChip(
                    icon: Icons.photo_camera_outlined,
                    label: 'Add photo (stub)',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            AppButton(
              label: 'Save hangout',
              icon: Icons.check_rounded,
              onPressed: attendees.isEmpty || title.trim().isEmpty
                  ? null
                  : () {
                      HangoutMemory memory = HangoutMemory(
                        id: 'm${DateTime.now().microsecondsSinceEpoch}',
                        title: title.trim(),
                        date: shortDate(DateTime.now()),
                        note: note.trim(),
                        relationshipAtLogTime: attendees.first.relationship,
                      );
                      // One brick per attendee's history would double-count
                      // the build, so the memory is saved to the first
                      // attendee and everyone else just gets the counters.
                      for (int i = 0; i < attendees.length; i++) {
                        app.logHangout(attendees[i], i == 0 ? memory : null);
                      }
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// Consistent frosted text-field look.
InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    filled: true,
    fillColor: Colors.white.withAlpha(10),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
  );
}

class _AttendeeToggle extends StatelessWidget {
  const _AttendeeToggle({
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
      child: Container(
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
        child: Text(
          friend.shortName,
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
