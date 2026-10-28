//
//
// REPLACE ALL THE LEGO SHIT AND DO IT YOURSELF. I DO NOT UNDERSTAND THIS CODE
// THUS IT SHOULD NOT BE PUSHED TO PRODUCTION
//
//
// lego.dart — the 3D-ish LEGO set.
//
// HOW THIS WORKS (the only "advanced" file, read once):
//   We draw bricks on a plain canvas using Flutter's CustomPainter. There is
//   no real 3D engine. Each brick is 3 flat shapes in isometric style:
//
//            top face (a diamond)
//                 /\
//               /    \   <- 2 little ovals = the studs
//              /______\
//              |      |  <- left face, darker
//              |______|  <- right face, darkest
//
//   Bricks sit on a slanted grid: brick (column c, row r) is placed at
//     x = (c - r) * halfBrickWidth   (going right shifts +x, going down shifts -x)
//     y = (c + r) * halfBrickHeight  (both directions shift down)
//   Drawing "back" bricks first (smallest c + r) makes near bricks overlap
//   them, which sells the 3D depth.
//
//   Tapping: we work out which brick's centre is nearest the tap point and
//   take that as the hit. A hit brick flashes white for half a second.

import 'dart:math'; // for min()

import 'package:flutter/material.dart';

// One logged hangout = one piece.
class LegoPiece {
  const LegoPiece({required this.color});

  final Color color;
}

// A computed brick: where it sits, how it looks. Internal to this file.
class Brick {
  Brick({
    required this.slot,
    required this.center,
    required this.color,
    required this.filled,
    required this.depthOrder,
  });

  final int slot; // index across all slots
  final Offset center;
  final Color color;
  final bool filled; // false = empty ghost slot

  // Back bricks (low column+row sum) must be painted first, so near bricks
  // overlap them. layout() computes this from the real column/row.
  final int depthOrder;
}

class LegoWall extends StatefulWidget {
  const LegoWall({
    super.key,
    required this.pieces,
    this.ghostSlots = 8,
    this.cols = 6,
    this.interactive = true,
    this.onPieceTap,
  });

  final List<LegoPiece> pieces;
  final int ghostSlots; // empty slots shown after the filled ones
  final int cols; // bricks per row of the grid
  final bool interactive;
  final void Function(int pieceIndex)? onPieceTap;

  // The brick half-width for a box of `size`. One place computes it, so
  // layout() and the painter can never disagree about brick size.
  static double brickHalfWidth(
    Size size,
    int filledCount,
    int ghosts,
    int cols,
  ) {
    int slots = filledCount + ghosts;
    int rows = (slots / cols).ceil();
    return min(
      size.width / (cols + rows) / 1.25,
      size.height / ((cols + rows) / 2 * 1.1 + 2.2),
    );
  }

  // Where every brick would sit inside a box of `size`, back-to-front.
  // static so other code (and tests) can hit-test without the widget.
  static List<Brick> layout(
    Size size,
    List<LegoPiece> pieces,
    int ghosts,
    int cols,
  ) {
    int filledCount = pieces.length;
    int slots = filledCount + ghosts;
    int rows = (slots / cols).ceil();

    // Pick the biggest brick that still fits this box.
    double halfW = brickHalfWidth(size, filledCount, ghosts, cols);
    double halfH = halfW * 0.5;
    double brickDepth = halfW * 0.6; // how tall the side faces are

    // Centre of the whole grid, so the set sits in the middle of the box.
    double midX = (cols - 1) * halfW / 2 - (rows - 1) * halfW / 2;
    double midY = (cols - 1) * halfH / 2 + (rows - 1) * halfH / 2 + brickDepth;
    double originX = size.width / 2 - midX;
    double originY = size.height / 2 - midY;

    List<Brick> result = <Brick>[];
    for (int i = 0; i < slots; i++) {
      int c = i % cols;
      int r = i ~/ cols;
      bool filled = i < filledCount;
      result.add(
        Brick(
          slot: i,
          center: Offset(originX + (c - r) * halfW, originY + (c + r) * halfH),
          color: filled ? pieces[i].color : const Color(0xFF15151C),
          filled: filled,
          depthOrder: c + r,
        ),
      );
    }
    result.sort((Brick a, Brick b) => a.depthOrder.compareTo(b.depthOrder));
    return result;
  }

  @override
  State<LegoWall> createState() => _LegoWallState();
}

class _LegoWallState extends State<LegoWall> {
  // Which brick is flashing right now (usually none).
  final List<int> flashing = <int>[];

  void _handleTapAt(Offset local, Size size) {
    if (!widget.interactive || widget.onPieceTap == null) {
      return;
    }

    // Find the brick whose centre is closest to the tap.
    List<Brick> bricks = LegoWall.layout(
      size,
      widget.pieces,
      widget.ghostSlots,
      widget.cols,
    );
    Brick? nearest;
    double nearestDistance = double.infinity;
    for (Brick b in bricks) {
      double d = (b.center - local).distance;
      if (d < nearestDistance) {
        nearestDistance = d;
        nearest = b;
      }
    }

    // Too far from any brick, or an empty ghost slot: ignore the tap.
    if (nearest == null || nearestDistance > 90 || !nearest.filled) {
      return;
    }

    int index = nearest.slot;
    setState(() => flashing.add(index));
    widget.onPieceTap!(index);

    // Stop the flash after 620ms.
    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (mounted) {
        setState(() => flashing.remove(index));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        List<Brick> bricks = LegoWall.layout(
          size,
          widget.pieces,
          widget.ghostSlots,
          widget.cols,
        );

        return GestureDetector(
          onTapUp: (TapUpDetails d) => _handleTapAt(d.localPosition, size),
          child: CustomPaint(
            painter: _LegoPainter(
              bricks: bricks,
              pieces: widget.pieces,
              flashing: flashing,
              size: size,
              ghostCount: widget.ghostSlots,
            ),
          ),
        );
      },
    );
  }
}

class _LegoPainter extends CustomPainter {
  _LegoPainter({
    required this.bricks,
    required this.pieces,
    required this.flashing,
    required this.size,
    required this.ghostCount,
  });

  final List<Brick> bricks;
  final List<LegoPiece> pieces;
  final List<int> flashing;
  final Size size;
  final int ghostCount;

  // Mix a color toward black (negative amount) or white (positive).
  // Handy for fake lighting: top face lighter, right side darkest.
  Color _shade(Color c, double amount) {
    if (amount < 0) {
      return Color.lerp(c, Colors.black, -amount)!;
    }
    return Color.lerp(c, Colors.white, amount)!;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (bricks.isEmpty) {
      return;
    }

    // Same numbers layout() used to place the bricks, recomputed from the
    // widget's size — no guessing.
    double halfW = LegoWall.brickHalfWidth(size, pieces.length, ghostCount, 6);
    double halfH = halfW * 0.5;
    double depth = halfW * 0.6;

    for (Brick brick in bricks) {
      Color base = brick.color;

      bool isFlashing = flashing.contains(brick.slot);
      Color top = isFlashing ? Colors.white : _shade(base, 0.18);
      Color left = isFlashing ? Colors.white : _shade(base, -0.12);
      Color right = isFlashing ? Colors.white : _shade(base, -0.30);
      if (!brick.filled) {
        top = const Color(0xFF15151C);
        left = const Color(0xFF101016);
        right = const Color(0xFF0C0C12);
      }

      double x = brick.center.dx;
      double y = brick.center.dy;

      // The three faces of one brick, as paths:
      Path topFace = Path()
        ..moveTo(x, y - halfH) // north
        ..lineTo(x + halfW, y) // east
        ..lineTo(x, y + halfH) // south
        ..lineTo(x - halfW, y) // west
        ..close();

      Path leftFace = Path()
        ..moveTo(x - halfW, y)
        ..lineTo(x, y + halfH)
        ..lineTo(x, y + halfH + depth)
        ..lineTo(x - halfW, y + depth)
        ..close();

      Path rightFace = Path()
        ..moveTo(x + halfW, y)
        ..lineTo(x, y + halfH)
        ..lineTo(x, y + halfH + depth)
        ..lineTo(x + halfW, y + depth)
        ..close();

      // White bricks get a soft glow behind them while flashing.
      if (isFlashing) {
        canvas.drawPath(
          topFace,
          Paint()
            ..color = Colors.white.withAlpha(220)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
      }

      canvas.drawPath(leftFace, Paint()..color = left);
      canvas.drawPath(rightFace, Paint()..color = right);
      canvas.drawPath(topFace, Paint()..color = top);

      // Thin outline so bricks read as separate objects.
      Paint edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = isFlashing
            ? Colors.white
            : Colors.white.withAlpha(brick.filled ? 46 : 16);
      canvas.drawPath(topFace, edge);
      canvas.drawPath(leftFace, edge);
      canvas.drawPath(rightFace, edge);

      // Two studs on the top face: little ovals left and right of centre.
      Paint stud = Paint()
        ..color = isFlashing
            ? Colors.white
            : (brick.filled
                  ? Colors.white.withAlpha(110)
                  : Colors.white.withAlpha(14));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - halfW * 0.45, y),
          width: halfW * 0.5,
          height: halfH * 0.6,
        ),
        stud,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + halfW * 0.45, y),
          width: halfW * 0.5,
          height: halfH * 0.6,
        ),
        stud,
      );
    }
  }

  @override
  bool shouldRepaint(_LegoPainter oldDelegate) {
    return oldDelegate.bricks != bricks ||
        oldDelegate.flashing.length != flashing.length ||
        oldDelegate.pieces != pieces;
  }
}
