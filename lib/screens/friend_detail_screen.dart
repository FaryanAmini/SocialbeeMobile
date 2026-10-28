// friend_detail_screen.dart — everything about one friendship.
//
// A full page (pushed on top of the tab shell), because this is where you
// spend time: read the history, edit the person, change the cadence.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';
import 'log_hangout_screen.dart';
import 'schedule_screen.dart';

class FriendDetailScreen extends StatelessWidget {
  const FriendDetailScreen({super.key, required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GlassPageBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Back row (large thumb-reachable target on the left).
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: <Widget>[
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  children: <Widget>[
                    _HeaderCard(friend: friend),
                    const SectionLabel('Frequency & relationship'),
                    _SettingsCard(friend: friend, app: app),
                    const SectionLabel('History'),
                    if (friend.history.isEmpty)
                      const GlassCard(
                        child: EmptyState(
                          icon: Icons.photo_camera_outlined,
                          title: 'No hangouts logged yet',
                          subtitle: 'Your first brick goes here once you log something.',
                        ),
                      )
                    else
                      GlassList(
                        rows: <Widget>[
                          for (HangoutMemory m in friend.history)
                            RowTile(
                              leading: const Icon(
                                Icons.view_in_ar_rounded,
                                size: 20,
                                color: AppColors.muted,
                              ),
                              title: m.title,
                              subtitle: m.date,
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Log a hangout',
                      icon: Icons.add_a_photo_rounded,
                      onPressed: () => openLogSheet(context, <Friend>[friend]),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Schedule something',
                      style: ButtonStyle2.ghost,
                      icon: Icons.bolt_rounded,
                      onPressed: () => openScheduleScreen(
                        context,
                        preselect: <Friend>[friend],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Big name card at the top.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Avatar(friend, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(friend.name, style: Texts.bigTitle),
                    const SizedBox(height: 4),
                    RelationshipTag(friend.relationship),
                  ],
                ),
              ),
            ],
          ),
          if (friend.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(friend.description, style: Texts.body),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _Stat(value: '${friend.hangoutCount}', label: 'hangouts'),
              _Stat(
                value: friend.streak > 0 ? '${friend.streak}' : '0',
                label: 'streak',
              ),
              _Stat(
                value: friend.nextReminderInDays <= 0
                    ? 'now'
                    : '${friend.nextReminderInDays}d',
                label: 'next nudge',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// One number + caption, used three across the header card.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: Texts.itemTitle),
          const SizedBox(height: 2),
          Text(label, style: Texts.meta),
        ],
      ),
    );
  }
}

// The frequency slider + relationship toggle live here. Editing is instant;
// there is no save button because the data model updates directly.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.friend, required this.app});

  final Friend friend;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(friend.frequencyLabel, style: Texts.itemTitle),
              ),
              StreakTag(friend.streak, size: 15),
            ],
          ),
          const SizedBox(height: 2),
          const Text('How often should we nudge you?', style: Texts.meta),
          Slider(
            min: 1,
            max: 60,
            value: friend.frequencyDays.toDouble().clamp(1, 60),
            onChanged: (double value) {
              friend.frequencyDays = value.round();
              app.saveFriendChanges();
            },
          ),
          const Divider(height: 26),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Relationship', style: Texts.itemTitle),
                    const SizedBox(height: 2),
                    Text(
                      friend.relationship == Relationship.building
                          ? 'Aim for a 6-month streak to move up'
                          : 'Streaks hold this friendship',
                      style: Texts.meta,
                    ),
                  ],
                ),
              ),
              // No color set here: Switch picks up the amber primary from
              // the theme in theme.dart automatically.
              Switch(
                value: friend.relationship == Relationship.maintaining,
                onChanged: (bool isOn) => app.toggleRelationship(friend),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
