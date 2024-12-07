// https://stackoverflow.com/questions/73770245/how-to-hover-text-in-flutter

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HoverController extends ValueNotifier {
  HoverController() : super(null);

  int? get hoveredBox => value;

  void setHoveredBox(int? boxId) {
    value = boxId; // Notify listeners when value changes
  }
}

HoverController holdHoverController = HoverController();

class HoverBuilder extends StatefulWidget {
  const HoverBuilder({
    required this.builder,
    required this.id,
    super.key,
  });

  final Widget Function(bool isHovered) builder;
  final int id;

  @override
  _HoverBuilderState createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool get _isHovered => holdHoverController.hoveredBox == widget.id;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (PointerHoverEvent event) {
        if (holdHoverController.hoveredBox == null) {
          holdHoverController.setHoveredBox(widget.id);
        }
      },
      onEnter: (PointerEnterEvent event) =>
          holdHoverController.setHoveredBox(widget.id),
      onExit: (PointerExitEvent event) {
        if (holdHoverController.hoveredBox == widget.id) {
          holdHoverController.setHoveredBox(null);
        }
      },
      child: ValueListenableBuilder(
        valueListenable: holdHoverController,
        builder: (context, _, __) {
          return widget.builder(_isHovered);
        },
      ),
    );
  }
}
