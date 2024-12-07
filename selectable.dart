import 'package:flutter/material.dart';

class SelectableViewer extends StatefulWidget {
  SelectableViewer(
      {super.key,
      required this.child,
      required this.panEnabled,
      required this.onSelection,
      this.selectionEnabled = true});

  final Widget child;
  final bool panEnabled;
  final void Function(Rect) onSelection;
  bool selectionEnabled;

  @override
  State<SelectableViewer> createState() => _SelectableViewerState();
}

class _SelectableViewerState extends State<SelectableViewer> {
  Offset? startPosition;
  Rect? selectionRectangle;
  bool cursorIsDown = false;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: widget.panEnabled,
      maxScale: 6,
      child: Stack(
        children: [
          Listener(
            onPointerDown: (event) {
              if (!widget.selectionEnabled) return;

              setState(() {
                startPosition = event.localPosition;
                cursorIsDown = true;
              });
            },
            onPointerUp: (event) {
              if (!widget.selectionEnabled) return;
              cursorIsDown = false;

              if (startPosition != null) {
                setState(() {
                  Offset mousePosition = event.localPosition;

                  widget.onSelection(
                      Rect.fromPoints(startPosition!, mousePosition));

                  selectionRectangle = null;
                  startPosition = null;
                });
              }
            },
            onPointerMove: (event) {
              if (!widget.selectionEnabled) return;
              if (startPosition != null) {
                setState(() {
                  Offset mousePosition = event.localPosition;

                  selectionRectangle =
                      Rect.fromPoints(startPosition!, mousePosition);
                });
              }
            },
            child: widget.child,
          ),
          selectionRectangle == null
              ? const SizedBox()
              : Positioned(
                  top: selectionRectangle!.topLeft.dy,
                  left: selectionRectangle!.topLeft.dx,
                  child: Container(
                    width: selectionRectangle!.width,
                    height: selectionRectangle!.height,
                    decoration: const BoxDecoration(
                        color: Color.fromARGB(93, 54, 197, 244)),
                  ),
                ),
        ],
      ),
    );
  }
}
