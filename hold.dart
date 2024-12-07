import 'dart:typed_data';
import 'dart:ui';

import 'package:climbingapp/hover_builder.dart';
import 'package:flutter/material.dart';

Color nameToColor(String name) {
  if (name == "White") return Colors.white;
  if (name == "Black") return Colors.black;
  if (name == "Red") return Colors.red;
  if (name == "Yellow") return Colors.yellow;
  if (name == "Green") return Colors.green;
  if (name == "Blue") return Colors.blue;
  if (name == "Purple") return Colors.purple;
  if (name == "Pink") return Colors.pink;
  return Colors.grey;
}

class Hold {
  Hold({
    required this.xmin,
    required this.ymin,
    required this.xmax,
    required this.ymax,
    required this.holdColorName,
    required this.id,
    required this.onPressed,
  });

  final num xmin;
  final num ymin;
  final num xmax;
  final num ymax;
  final int id;
  String holdColorName;
  final void Function(int) onPressed;
}

class HoldWidget extends StatefulWidget {
  const HoldWidget({
    super.key,
    required this.hold,
    required this.widthMul,
  });

  final Hold hold;
  final double widthMul;

  @override
  State<HoldWidget> createState() => _HoldWidgetState();
}

class _HoldWidgetState extends State<HoldWidget> {
  @override
  Widget build(BuildContext context) {
    double width = (widget.hold.xmax - widget.hold.xmin).toDouble();
    double height = (widget.hold.ymax - widget.hold.ymin).toDouble();
    return Positioned(
      left: widget.hold.xmin.toDouble(),
      top: widget.hold.ymin.toDouble(),
      child: HoverBuilder(
        id: widget.hold.id,
        builder: (isHovering) {
          double borderWidth = (isHovering ? 2 : 1) * widget.widthMul;

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: borderWidth == 0
                  ? null
                  : Border.all(
                      color: nameToColor(widget.hold.holdColorName),
                      width: borderWidth,
                    ),
            ),
          );
        },
      ),
    );
  }
}
