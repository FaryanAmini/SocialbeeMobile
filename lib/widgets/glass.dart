// glass.dart — the "liquid glass" building blocks.
//
// The look is two ingredients:
//   1. GlassCard: a translucent white gradient + one bright thin border.
//      Only the frosted variant (nav bar) also blurs what is behind it.
//   2. GlassChip: the same idea at pill size.
//
// No shadows anywhere. The blur and the border do all the work.

// note kinda just took this one from ai. i am too new to ts to figure this out sorry

import 'dart:ui'; // for ImageFilter.blur

import 'package:flutter/material.dart';

import '../theme.dart';

// A rounded panel. Put anything inside it.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.borderAccent, // pass a color to tint the border (e.g. amber nudges)
    this.onTap,
    this.frosted = false, // true = liquid-glass blur; only the nav bar uses it
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderAccent;
  final VoidCallback? onTap;
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    BorderRadius shape = BorderRadius.circular(radius);

    // Layer cake, bottom to top:
    //   (optional blurred backdrop) -> white sheen gradient -> border -> content
    Widget surface = Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0x15FFFFFF), // brighter frost top-left
            Color(0x08FFFFFF), // fading toward bottom-right
          ],
        ),
        border: Border.all(
          color: borderAccent != null
              ? borderAccent!.withAlpha(120)
              : glassBorder,
          width: 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    Widget card = ClipRRect(
      borderRadius: shape,
      child: frosted
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: surface,
            )
          : surface,
    );

    // Make the whole card tappable if the caller gave us an onTap.
    if (onTap == null) {
      return card;
    }
    return InkWell(onTap: onTap, borderRadius: shape, child: card);
  }
}

// A small pill button (flat, no blur): "Schedule", "Sync account"...
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.emphasis = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  // emphasis = amber-tinted, used for the single most important chip.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    Color foreground = emphasis ? AppColors.accent : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: emphasis
              ? AppColors.accent.withAlpha(28) // ~11% amber
              : Colors.white.withAlpha(15), // ~6% white
          border: Border.all(
            color: emphasis
                ? AppColors.accent.withAlpha(115)
                : Colors.white.withAlpha(35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The plain black every page background sits on. Wrap a page body in this
// so the frosted nav bar has content scrolling underneath it to blur.
class GlassPageBackground extends StatelessWidget {
  const GlassPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.background),
        child,
      ],
    );
  }
}
