// home_screen.dart — the first page.
//
// Layout is one ordered scroll, no tabs:
//   1. Nudges you can act on right now (swipe them)
//   2. SOON / LATER / PENDING hangouts
//   3. A preview of the 3D build
//
// Empty sections disappear entirely. That is the "calm" part of the design:
// the page only shows what actually needs attention.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dates.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';
import '../widgets/lego.dart';
import 'friend_detail_screen.dart';
import 'log_hangout_screen.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenBuilds});

  final VoidCallback onOpenBuilds;

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);

    List<Reminder> nudges = app.outstandingReminders;
    List<Reminder> upcoming = app.upcomingReminders;
    List<PlannedHangout> soon = app.hangoutsInBucket(HangoutBucket.soon);
    List<PlannedHangout> later = app.hangoutsInBucket(HangoutBucket.later);
    List<PlannedHangout> pending = app.hangoutsInBucket(HangoutBucket.pending);

    String subtitleText;
    if (nudges.isNotEmpty) {
      subtitleText = '${nudges.length} nudges to act on';
    } else {
      subtitleText = 'Nothing needs you right now';
    }

    List<Widget> items = <Widget>[];

    // --- 1. nudges -------------------------------------------------------
    if (nudges.isNotEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            'Swipe a nudge: right to schedule, left to defer',
            style: Texts.meta,
          ),
        ),
      );
      for (Reminder reminder in nudges) {
        items.add(NudgeCard(reminder: reminder));
      }
    } else if (upcoming.isNotEmpty) {
      // All clear: show just the next person due, as one quiet card.
      Reminder next = upcoming.first;
      items.add(
        GlassCard(
          child: Row(
            children: <Widget>[
              Avatar(next.friend, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('ALL CLEAR', style: Texts.sectionLabel),
                    const SizedBox(height: 2),
                    Text(
                      'Next up: ${next.friend.name} · in ${next.dueInDays} days',
                      style: Texts.meta,
                    ),
                  ],
                ),
              ),
              StreakTag(next.friend.streak),
            ],
          ),
        ),
      );
    }

    // --- 2. planned hangouts ----------------------------------------------
    void addBucket(String label, List<PlannedHangout> list) {
      if (list.isEmpty) {
        return; // empty section = no section at all
      }
      items.add(SectionLabel(label));
      items.add(
        GlassList(
          rows: <Widget>[
            for (PlannedHangout h in list) HangoutRowTile(hangout: h),
          ],
        ),
      );
    }

    addBucket('Soon', soon);
    addBucket('Later', later);
    addBucket('Pending', pending);

    if (soon.isEmpty && later.isEmpty && pending.isEmpty && nudges.isEmpty) {
      items.add(
        const GlassCard(
          child: EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nothing planned',
            subtitle: 'Tap the + button to schedule something.',
          ),
        ),
      );
    }

    // --- 3. build preview ---------------------------------------------------
    items.add(const SectionLabel('Build'));
    items.add(BuildPreviewCard(onTap: onOpenBuilds, memories: app.allMemories));

    return PageScaffold(
      title: 'SociaBee',
      subtitle: subtitleText,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 6, 16, listBottomPadding),
        children: items,
      ),
    );
  }
}

// A nudge you must act on. Wraps the card in Flutter's Dismissible:
// drag right fires onSchedule, drag left fires onDefer. No buttons needed.
class NudgeCard extends StatelessWidget {
  const NudgeCard({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);
    Friend friend = reminder.friend;

    // Dismissible gives us the drag, the rubber-band, and the icons-under-
    // content behavior for free. confirmDismiss decides what the swipe DOES;
    // returning false snaps the card back instead of removing it, because
    // the *data* (outstanding list) decides when this card disappears.
    return Dismissible(
      key: ValueKey<String>(reminder.id),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          // swipe right: open scheduling with this friend preselected
          openScheduleScreen(context, preselect: <Friend>[friend]);
        } else {
          // swipe left: defer to the next reminder time
          app.deferReminder(reminder);
        }
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          borderAccent: AppColors.accent,
          onTap: () => showReminderSheet(context, reminder),
          child: Row(
            children: <Widget>[
              Avatar(friend, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(friend.name, style: Texts.itemTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Due now · you usually hang out '
                      '${friend.frequencyLabel.toLowerCase()}',
                      style: Texts.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StreakTag(friend.streak),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// One row for a planned hangout: faces + activity + when. Tapping opens a
// sheet with the details and the two actions people actually want here.
class HangoutRowTile extends StatelessWidget {
  const HangoutRowTile({super.key, required this.hangout});

  final PlannedHangout hangout;

  @override
  Widget build(BuildContext context) {
    bool isPending = hangout.bucket == HangoutBucket.pending;

    String subtitle;
    if (hangout.when == null) {
      subtitle = 'Waiting on ${hangout.awaitingReplyFrom}';
    } else {
      subtitle = '${dayLabel(hangout.when!)} · ${timeLabel(hangout.when!)}';
    }

    return RowTile(
      leading: AvatarStack(hangout.friends),
      title: hangout.title,
      subtitle: subtitle,
      trailing: isPending
          ? const StatusTag('Pending', color: AppColors.accent)
          : null,
      onTap: () => showHangoutSheet(context, hangout),
    );
  }
}

// The detail sheet for a planned hangout.
void showHangoutSheet(BuildContext context, PlannedHangout hangout) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(child: SheetGrabber()),
                const SizedBox(height: 14),
                Text(hangout.title, style: Texts.bigTitle),
                const SizedBox(height: 6),
                Text(
                  hangout.when == null
                      ? 'Waiting for ${hangout.awaitingReplyFrom} to confirm'
                      : '${dateLabel(hangout.when!)} · ${timeLabel(hangout.when!)}',
                  style: Texts.meta,
                ),
                if (hangout.note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(hangout.note, style: Texts.body),
                ],
                const SizedBox(height: 16),
                // Attendee chips jump straight to that friend's page.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (Friend f in hangout.friends)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FriendDetailScreen(friend: f),
                            ),
                          );
                        },
                        child: GlassChip(label: f.shortName),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Log this hangout',
                  icon: Icons.add_a_photo_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    openLogSheet(context, hangout.friends);
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Move it',
                  style: ButtonStyle2.ghost,
                  icon: Icons.swap_horiz_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    openScheduleScreen(
                      context,
                      preselect: hangout.friends,
                      initialWhen: hangout.when,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Tapping a nudge (instead of swiping) gets this two-button sheet.
void showReminderSheet(BuildContext context, Reminder reminder) {
  AppState app = AppScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.black,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Center(child: SheetGrabber()),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Avatar(reminder.friend, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(reminder.friend.name, style: Texts.itemTitle),
                          const SizedBox(height: 2),
                          Text(
                            'You usually hang out '
                            '${reminder.friend.frequencyLabel.toLowerCase()}',
                            style: Texts.meta,
                          ),
                        ],
                      ),
                    ),
                    StreakTag(reminder.friend.streak),
                  ],
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Schedule',
                  icon: Icons.bolt_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    openScheduleScreen(
                      context,
                      preselect: <Friend>[reminder.friend],
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Remind me later',
                  style: ButtonStyle2.ghost,
                  onPressed: () {
                    app.deferReminder(reminder);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// The dark glass box on Home showing the current build. Tap = Builds page.
class BuildPreviewCard extends StatelessWidget {
  const BuildPreviewCard({
    super.key,
    required this.onTap,
    required this.memories,
  });

  final VoidCallback onTap;
  final List<HangoutMemory> memories;

  @override
  Widget build(BuildContext context) {
    List<LegoPiece> pieces = <LegoPiece>[
      for (HangoutMemory m in memories)
        LegoPiece(color: m.relationshipAtLogTime.color),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: 170,
            width: double.infinity,
            child: LegoWall(pieces: pieces, ghostSlots: 8, interactive: false),
          ),
          // Darken the bottom so the caption text stays readable.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[Color(0xE009090C), Color(0x0009090C)],
                    stops: <double>[0, 0.65],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 14,
            bottom: 12,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${memories.length} memories built',
                    style: Texts.itemTitle,
                  ),
                ),
                const Icon(
                  Icons.view_in_ar_rounded,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
              ],
            ),
          ),
          // Invisible tap layer over the whole preview.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, splashColor: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
