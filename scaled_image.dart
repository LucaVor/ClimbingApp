import 'dart:math';
import 'package:flutter/material.dart';

double calculateScaleFactor(BuildContext context, double imageWidth,
    double imageHeight, double heightFactor, double widthFactor) {
  Size screenSize = MediaQuery.of(context).size;

  double targetHeight = screenSize.height * heightFactor;
  double targetWidth = screenSize.width * widthFactor;

  double widthScalingFactor = imageWidth / targetWidth;
  double heightScalingFactor = imageHeight / targetHeight;
  double scaleFactor = max(widthScalingFactor, heightScalingFactor);

  return scaleFactor;
}

class ScaledWall extends StatefulWidget {
  ScaledWall({
    super.key,
    required this.imageHeight,
    required this.imageWidth,
    required this.child,
    this.heightFactor = 0.8,
    this.widthFactor = 0.6,
  });

  final double imageWidth;
  final double imageHeight;
  final Widget child;
  double heightFactor;
  double widthFactor;

  @override
  State<ScaledWall> createState() => _ScaledWallState();
}

class _ScaledWallState extends State<ScaledWall> {
  @override
  Widget build(BuildContext context) {
    double scaleFactor = calculateScaleFactor(context, widget.imageWidth,
        widget.imageHeight, widget.heightFactor, widget.widthFactor);

    double realImageWidth = widget.imageWidth / scaleFactor;
    double realImageHeight = widget.imageHeight / scaleFactor;

    return SizedBox(
      width: realImageWidth,
      height: realImageHeight,
      child: FractionallySizedBox(
        widthFactor: scaleFactor,
        heightFactor: scaleFactor,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: 1 / scaleFactor,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
