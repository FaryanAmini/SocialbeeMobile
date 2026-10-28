// no clue how imma do this just yet.
// ai for now sorry

// pieces.dart — the small reusable widgets every screen imports.
//
// Nothing here does anything clever: they are simple Boxes, Circles and Rows
// styled with the tokens from theme.dart. Each one has one job.

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'glass.dart';

// The little tracked uppercase header between sections: "SOON", "LATER"...
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
      child: Text(text.toUpperCase(), style: Texts.sectionLabel),
    );
  }
}

// A circle showing a friend's initials, with a small colored dot that means
// building (violet) or maintaining (green).
//
// solid: true is used inside the overlapping avatar stacks — translucent
// discs would let the neighbor show through and become unreadable.
class Avatar extends StatelessWidget {
  const Avatar(
    this.friend, {
    super.key,
    this.size = 44,
    this.dim = false,
    this.showRelationship = true,
    this.solid = false,
  });

  final Friend friend;
  final double size;
  final bool dim; // gray for "new contact, not set up yet"
  final bool showRelationship;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    Color letters = dim ? AppColors.dimContact : AppColors.inkMid;

    Widget disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: solid ? const Color(0xFF222228) : Colors.white.withAlpha(20),
        border: Border.all(
          color: solid ? AppColors.background : Colors.white.withAlpha(45),
          width: solid ? 2 : 1,
        ),
      ),
      child: Text(
        friend.initials,
        style: TextStyle(
          color: letters,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.34,
        ),
      ),
    );

    if (!showRelationship || dim) {
      return disc;
    }

    // The relationship dot, hung off the bottom-right edge of the disc.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          disc,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: friend.relationship.color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Overlapping avatars, as seen on hangout rows.
class AvatarStack extends StatelessWidget {
  const AvatarStack(this.friends, {super.key, this.size = 36});

  final List<Friend> friends;
  final double size;

  @override
  Widget build(BuildContext context) {
    List<Friend> shown = friends.length > 3 ? friends.sublist(0, 3) : friends;
    double step = size * 0.62; // how far each avatar shifts right

    return SizedBox(
      width: size + step * (shown.length - 1),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Built right-to-left so the FIRST friend paints last, on top.
          for (int i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: i * step,
              child: Avatar(
                shown[i],
                size: size,
                showRelationship: false,
                solid: true,
              ),
            ),
        ],
      ),
    );
  }
}

// "Building" / "Maintaining" shown as dot + word.
class RelationshipTag extends StatelessWidget {
  const RelationshipTag(this.relationship, {super.key});

  final Relationship relationship;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: relationship.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          relationship.label,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

// Fire + number. Returns an invisible placeholder when the streak is zero,
// so layouts never need to ask "do I show this?".
class StreakTag extends StatelessWidget {
  const StreakTag(this.streak, {super.key, this.size = 13});

  final int streak;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.local_fire_department_rounded,
          size: size,
          color: AppColors.accent,
        ),
        const SizedBox(width: 3),
        Text(
          '$streak',
          style: TextStyle(
            fontSize: size - 1,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

// Tiny "dot + word" status, e.g. "Due now" or "Pending".
class StatusTag extends StatelessWidget {
  const StatusTag(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// The standard list row: leading widget, title, one subtitle, optional
// trailing widget. 90% of the app is made of these.
class RowTile extends StatelessWidget {
  const RowTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: Texts.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Texts.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// Several RowTiles stacked in one GlassCard with hairlines between.
class GlassList extends StatelessWidget {
  const GlassList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    List<Widget> withDividers = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      withDividers.add(rows[i]);
      if (i != rows.length - 1) {
        withDividers.add(
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
        );
      }
    }
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: withDividers),
    );
  }
}

// The big primary button (solid amber) or its outlined sibling (ghost).
enum ButtonStyle2 {
  solid,
  ghost,
} // "2" to avoid clashing with Flutter's ButtonStyle

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.style = ButtonStyle2.solid,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonStyle2 style;

  @override
  Widget build(BuildContext context) {
    bool enabled = onPressed != null;
    bool solid = style == ButtonStyle2.solid;
    Color foreground = solid ? AppColors.accentInk : AppColors.ink;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: solid
                ? AppColors.accent
                : Colors.white.withAlpha(13),
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: solid ? Colors.transparent : Colors.white.withAlpha(36),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Round frosted icon button (the + in the dock, week arrows).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.emphasis = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool emphasis; // amber fill instead of frosted glass

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: emphasis ? AppColors.accent : Colors.white.withAlpha(18),
            border: Border.all(
              color: emphasis ? AppColors.accent : Colors.white.withAlpha(35),
            ),
          ),
          child: Icon(
            icon,
            size: size * 0.48,
            color: emphasis ? AppColors.accentInk : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// The little line at the top of bottom sheets.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// Friendly nothing-here block.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.muted, size: 26),
          const SizedBox(height: 12),
          Text(title, style: Texts.itemTitle, textAlign: TextAlign.center),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(subtitle!, style: Texts.meta, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
