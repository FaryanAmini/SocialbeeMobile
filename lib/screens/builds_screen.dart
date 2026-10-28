// builds_screen.dart — your friendships as one 3D set.
//
// Each brick is one logged hangout (the spec's "brick per memory" idea).
// Tap a brick: it flashes, and the memory opens as a sheet with a
// "Hang out again" shortcut — from memory to new plan in two taps.
//
// The drawing itself lives in widgets/lego.dart.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/lego.dart';
import '../widgets/pieces.dart';
import 'schedule_screen.dart';

// The spec's goal: 40 bricks total — 12 building, 28 maintaining.
const int goalTotal = 40;
const int goalBuilding = 12;
const int goalMaintaining = 28;

class BuildsScreen extends StatelessWidget {
  const BuildsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppState app = AppScope.of(context);
    List<HangoutMemory> memories = app.allMemories;

    // Which relationship each brick came from, for the progress counts.
    int buildingCount = 0;
    int maintainingCount = 0;
    for (HangoutMemory m in memories) {
      if (m.relationshipAtLogTime == Relationship.building) {
        buildingCount++;
      } else {
        maintainingCount++;
      }
    }

    List<LegoPiece> pieces = <LegoPiece>[
      for (HangoutMemory m in memories)
        LegoPiece(color: m.relationshipAtLogTime.color),
    ];
    // Show enough ghosts that the goal is visible even when behind.
    int ghosts = 8;
    if (pieces.length < 24) {
      ghosts = 24 - pieces.length + 8;
    }

    return PageScaffold(
      title: 'Builds',
      subtitle: '$buildingCount building · $maintainingCount maintaining',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 6, 16, listBottomPadding),
        children: <Widget>[
          // The set itself: tall, full-width, tappable.
          GlassCard(
            padding: const EdgeInsets.all(10),
            onTap: null, // taps are handled inside LegoWall
            child: SizedBox(
              height: 320,
              child: LegoWall(
                pieces: pieces,
                ghostSlots: ghosts,
                // Brick #3 in the layout list = the third memory logged
                // (the wall paints back-to-front, but slot numbers stay
                // in memory order — see lego.dart).
                onPieceTap: (int index) {
                  if (index < memories.length) {
                    _showMemorySheet(context, memories[index]);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ProgressCard(
            label: 'Building',
            count: buildingCount,
            goal: goalBuilding,
            color: AppColors.building,
          ),
          const SizedBox(height: 10),
          _ProgressCard(
            label: 'Maintaining',
            count: maintainingCount,
            goal: goalMaintaining,
            color: AppColors.maintaining,
          ),
          const SizedBox(height: 14),
          const GlassCard(
            child: EmptyState(
              icon: Icons.info_outline_rounded,
              title: 'One brick per hangout',
              subtitle:
                  'Log something you did with someone and it lands on the '
                  'wall automatically. Tap any brick to remember it.',
            ),
          ),
        ],
      ),
    );
  }

  // What happens when you tap a brick.
  void _showMemorySheet(BuildContext context, HangoutMemory memory) {
    AppState app = AppScope.of(context);
    // Find who this memory belongs to (the history lives on the friend).
    Friend? owner;
    for (Friend f in app.friends) {
      if (f.history.contains(memory)) {
        owner = f;
        break;
      }
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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
                  Text(memory.title, style: Texts.bigTitle),
                  const SizedBox(height: 4),
                  Text(
                    '${memory.date} · ${owner?.name ?? 'someone'}',
                    style: Texts.meta,
                  ),
                  if (memory.note.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(memory.note, style: Texts.body),
                  ],
                  if (memory.hasPhoto) ...<Widget>[
                    const SizedBox(height: 12),
                    // A real app shows the photo here; the stub is a frame.
                    Container(
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withAlpha(10),
                        border: Border.all(color: glassBorder),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Hang out again',
                    icon: Icons.bolt_rounded,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      if (owner != null) {
                        openScheduleScreen(context, preselect: <Friend>[owner]);
                      }
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

// "Building 3/12" with a thin amber-tinted fill bar.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.count,
    required this.goal,
    required this.color,
  });

  final String label;
  final int count;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double fraction = (count / goal).clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              // Expanded, so long captions wrap instead of running off.
              Expanded(
                child: Text('$label · $count of $goal', style: Texts.itemTitle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
