// glass.dart — the "liquid glass" building blocks.
//
// The look is three ingredients:
//   1. AmbientBackground: soft colored glows painted on the page behind
//      everything, so the blur has something to smear around.
//   2. GlassCard: blur what is behind the card, then lay a translucent white
//      gradient + one bright thin border on top. That is the frost.
//   3. GlassChip: the same idea at pill size.
//
// No shadows anywhere. The blur and the border do all the work.

// note kinda just took this one from ai. i am too new to ts to figure this out sorry

import 'dart:ui'; // for ImageFilter.blur

import 'package:flutter/material.dart';

import '../theme.dart';

// Big soft radial glows, pinned near the corners of the screen.
// They are static on purpose (no animation) — it keeps this file short.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        return Stack(
          children: <Widget>[
            _glow(
              width * 0.12,
              height * 0.02,
              width * 1.2,
              const Color(0x33F5A524),
            ),
            _glow(
              width * 0.92,
              height * 0.28,
              width * 0.9,
              const Color(0x268B7CFF),
            ),
            _glow(
              width * 0.18,
              height * 0.86,
              width * 1.0,
              const Color(0x1F2FBF8F),
            ),
          ],
        );
      },
    );
  }

  Widget _glow(double centerX, double centerY, double radius, Color color) {
    return Positioned(
      left: centerX - radius / 2,
      top: centerY - radius / 2,
      width: radius,
      height: radius,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: <Color>[color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}

// A frosted rounded panel. Put anything inside it.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.borderAccent, // pass a color to tint the border (e.g. amber nudges)
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderAccent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    BorderRadius shape = BorderRadius.circular(radius);

    // Layer cake, bottom to top:
    //   blurred backdrop -> white sheen gradient -> border -> content
    Widget card = ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
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
        ),
      ),
    );

    // Make the whole card tappable if the caller gave us an onTap.
    if (onTap == null) {
      return card;
    }
    return InkWell(onTap: onTap, borderRadius: shape, child: card);
  }
}

// A small frosted pill button: "Schedule", "Sync account"...
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
        ),
      ),
    );
  }
}

// The soft dark gradient every page background sits on. Wrap a page body
// in this to get the "glass over ambience" effect.
class GlassPageBackground extends StatelessWidget {
  const GlassPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.background),
        const IgnorePointer(child: AmbientBackground()),
        child,
      ],
    );
  }
}
