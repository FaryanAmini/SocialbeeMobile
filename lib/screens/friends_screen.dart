// friends_screen.dart — everyone you want to stay close to.
//
// The grid is the whole page. Tapping a tile opens that friend's detail
// page; long-pressing a tile opens a quick menu (schedule / log / set up)
// so common actions never need the detail page first.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';
import 'contact_setup_screen.dart';
import 'friend_detail_screen.dart';
import 'log_hangout_screen.dart';
import 'schedule_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);

    // "new contacts" (not set up) lead; the rest follow alphabetically.
    List<Friend> newContacts = app.unconfiguredFriends;
    List<Friend> everyone = List<Friend>.from(app.configuredFriends);
    everyone.sort((Friend a, Friend b) => a.name.compareTo(b.name));

    return PageScaffold(
      title: 'Friends',
      subtitle: '${everyone.length} in your circle',
      actions: <Widget>[
        const CircleIconButton(icon: Icons.sync_rounded, size: 40),
      ],
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 6, 16, listBottomPadding),
        children: <Widget>[
          if (newContacts.isNotEmpty) ...<Widget>[
            const SectionLabel('New contacts'),
            GlassList(
              rows: <Widget>[
                for (Friend f in newContacts)
                  RowTile(
                    leading: Avatar(f, size: 40, dim: true),
                    title: f.name,
                    subtitle: 'From your contacts — tap to set up',
                    trailing: const GlassChip(label: 'Set up'),
                    onTap: () => openContactSetup(context, f),
                  ),
              ],
            ),
          ],
          const SectionLabel('Your circle'),
          _FriendsGrid(friends: everyone),
        ],
      ),
    );
  }
}

// Two columns of tiles, one glass card each.
class _FriendsGrid extends StatelessWidget {
  const _FriendsGrid({required this.friends});

  final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = <Widget>[];
    for (Friend f in friends) {
      tiles.add(_FriendTile(friend: f));
    }
    // If the count is odd, the last row has a hole; Spacer keeps the grid
    // columns aligned.
    if (tiles.length.isOdd) {
      tiles.add(const SizedBox(height: 116));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      padding: const EdgeInsets.only(bottom: 4),
      children: tiles,
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FriendDetailScreen(friend: friend),
          ),
        );
      },
      // Long-press = quick actions without visiting the detail page.
      child: GestureDetector(
        onLongPress: () => _showQuickMenu(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Avatar(friend, size: 40),
                const Spacer(),
                StreakTag(friend.streak),
              ],
            ),
            const Spacer(),
            Text(
              friend.name,
              style: Texts.itemTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    friend.countdownLabel,
                    style: Texts.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  friend.relationship.label.toLowerCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: friend.relationship.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        void closeAnd(void Function() action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GlassCard(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Center(child: SheetGrabber()),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Avatar(friend, size: 40),
                      const SizedBox(width: 10),
                      Text(friend.name, style: Texts.itemTitle),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MenuRow(
                    icon: Icons.bolt_rounded,
                    label: 'Schedule a hangout',
                    onTap: () => closeAnd(
                      () => openScheduleScreen(
                        context,
                        preselect: <Friend>[friend],
                      ),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.add_a_photo_rounded,
                    label: 'Log a hangout',
                    onTap: () =>
                        closeAnd(() => openLogSheet(context, <Friend>[friend])),
                  ),
                  _MenuRow(
                    icon: Icons.settings_suggest_outlined,
                    label: 'Details & frequency',
                    onTap: () {
                      closeAnd(() {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext c) =>
                                FriendDetailScreen(friend: friend),
                          ),
                        );
                      });
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
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.inkSoft),
            const SizedBox(width: 12),
            Text(label, style: Texts.body),
          ],
        ),
      ),
    );
  }
}
