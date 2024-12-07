import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:climbingapp/hold.dart';
import 'package:climbingapp/hover_builder.dart';
import 'package:climbingapp/scaled_image.dart';
import 'package:climbingapp/selectable.dart';
import 'package:climbingapp/server.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// This Dart class represents a StatefulWidget for an EditWallPage.
class EditWallPage extends StatefulWidget {
  const EditWallPage({super.key, required this.wallName});

  final String wallName;

  @override
  State<EditWallPage> createState() => _EditWallPageState();
}

enum HoldCreationCursorMode {
  trash(mode: "Trash"),
  colorChanger(mode: "Color Changer"),
  newHold(mode: "New Hold");

  const HoldCreationCursorMode({required this.mode});

  final String mode;
}

class _EditWallPageState extends State<EditWallPage> {
  bool isLoading = true;

  late Image image;
  List<Hold> holds = [];
  HoldCreationCursorMode cursorMode = HoldCreationCursorMode.newHold;
  String currentSelectedColor = "Red";
  double? imageWidth;
  double? imageHeight;

  void loadWallInformation() async {
    http.Response response = await Server.post(
      "getWallEditingInfo",
      {"name": widget.wallName},
      {},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = Server.getResponseBody(response);

      String base64image = responseBody["image"];
      Uint8List imageBytes = base64Decode(base64image);
      image = Image.memory(imageBytes);

      imageWidth = responseBody["img_width"];
      imageHeight = responseBody["img_height"];

      for (dynamic hold in responseBody["wall data"]["holds"]) {
        addHold(hold);
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void onHoldPressed(int holdID) async {
    Hold hold = holds.firstWhere((e) => e.id == holdID);

    print(hold);

    if (cursorMode == HoldCreationCursorMode.newHold) {
    } else if (cursorMode == HoldCreationCursorMode.trash) {
      http.Response response = await Server.post(
        "removeHold",
        {"id": hold.id, "name": widget.wallName},
        {},
      );

      if (response.statusCode == 200) {
        setState(() {
          holds.removeWhere((potentialHold) => potentialHold.id == hold.id);
        });
      }
    } else if (cursorMode == HoldCreationCursorMode.colorChanger) {
      http.Response response = await Server.post(
        "changeHoldColor",
        {
          "id": hold.id,
          "newColor": currentSelectedColor,
          "name": widget.wallName
        },
        {},
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var potentialHold in holds) {
            if (potentialHold.id == hold.id) {
              potentialHold.holdColorName = currentSelectedColor;
            }
          }
        });
      }
    }
  }

  void addHold(dynamic hold) {
    holds.add(
      Hold(
        xmin: hold["xmin"],
        xmax: hold["xmax"],
        ymin: hold["ymin"],
        ymax: hold["ymax"],
        id: hold["id"],
        holdColorName: hold["hold_color_name"],
        onPressed: onHoldPressed,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadWallInformation();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          "Edit Wall",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      cursorMode = HoldCreationCursorMode.trash;
                    });
                  },
                  icon: Icon(
                    Icons.restore_from_trash,
                    color: cursorMode == HoldCreationCursorMode.trash
                        ? Colors.orange
                        : Colors.grey,
                    size: 60,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          cursorMode = HoldCreationCursorMode.colorChanger;

                          showColorPickerDialogue(context);
                        });
                      },
                      icon: Icon(
                        Icons.color_lens,
                        color: cursorMode == HoldCreationCursorMode.colorChanger
                            ? Colors.orange
                            : Colors.grey,
                        size: 60,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: nameToColor(currentSelectedColor),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      cursorMode = HoldCreationCursorMode.newHold;
                    });
                  },
                  icon: Icon(
                    Icons.brush,
                    color: cursorMode == HoldCreationCursorMode.newHold
                        ? Colors.orange
                        : Colors.grey,
                    size: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 25),
            GestureDetector(
              onTapUp: (_) {
                if (holdHoverController.hoveredBox != null) {
                  onHoldPressed(holdHoverController.hoveredBox!);
                }
              },
              child: ScaledWall(
                imageWidth: imageWidth!,
                imageHeight: imageHeight!,
                child: SelectableViewer(
                  panEnabled: false,
                  onSelection: (selection) async {
                    if (cursorMode != HoldCreationCursorMode.newHold) {
                      return;
                    }

                    if (selection.width == 0 || selection.height == 0) {
                      return;
                    }

                    dynamic holdInfo = {
                      "xmin": selection.topLeft.dx.toInt(),
                      "ymin": selection.topLeft.dy.toInt(),
                      "xmax": selection.bottomRight.dx.toInt(),
                      "ymax": selection.bottomRight.dy.toInt(),
                      "name": widget.wallName,
                    };
                    http.Response response = await Server.post(
                      "addHold",
                      holdInfo,
                      {},
                    );

                    if (response.statusCode == 200) {
                      dynamic responseBody = Server.getResponseBody(response);
                      int id = responseBody["id"];
                      String holdColorName = responseBody["hold_color_name"];

                      holdInfo["id"] = id;
                      holdInfo["hold_color_name"] = holdColorName;

                      setState(() {
                        addHold(holdInfo);
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      image,
                      ...holds.map((hold) => HoldWidget(
                            hold: hold,
                            widthMul: 1,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showColorPickerDialogue(BuildContext) {
    const List<String> colors = [
      "White",
      "Black",
      "Red",
      "Pink",
      "Yellow",
      "Purple",
      "Green",
      "Blue"
    ];

    showDialog(
      context: context,
      builder: (dialogCxt) => SimpleDialog(
        contentPadding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.0),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.grey, blurRadius: 16.0)
              ],
            ),
            child: Row(
              children: colors
                  .map(
                    (color) => Column(
                      children: [
                        TextButton(
                          child: Text(color),
                          onPressed: () {
                            Navigator.of(context).pop();

                            setState(() {
                              currentSelectedColor = color;
                            });
                          },
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: nameToColor(color),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
