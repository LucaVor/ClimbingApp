import 'dart:ui';

import 'package:climbingapp/hold.dart';
import 'package:flutter/material.dart';

class CutOutHolds extends StatefulWidget {
  const CutOutHolds({
    super.key,
    required this.child,
    required this.cutOffs,
    required this.shouldShow,
  });

  final Widget child;
  final List<Hold> cutOffs;
  final bool Function(Hold) shouldShow;

  @override
  State<CutOutHolds> createState() => _CutOutHoldsState();
}

class _CutOutHoldsState extends State<CutOutHolds> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxWidth),
              painter: HoldCutOutPainter(
                cutOffs: widget.cutOffs,
                shouldShow: widget.shouldShow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HoldCutOutPainter extends CustomPainter {
  const HoldCutOutPainter({
    required this.cutOffs,
    required this.shouldShow,
  });

  final List<Hold> cutOffs;
  final bool Function(Hold) shouldShow;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (Hold hold in cutOffs) {
      if (!shouldShow(hold)) {
        continue;
      }

      double width = (hold.xmax - hold.xmin).toDouble();
      double height = (hold.ymax - hold.ymin).toDouble();

      canvas.clipRect(
        Rect.fromLTWH(
          hold.xmin.toDouble(),
          hold.ymin.toDouble(),
          width,
          height,
        ),
        clipOp: ClipOp.difference,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color.fromARGB(255, 79, 79, 79)
        ..blendMode = BlendMode.modulate,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
