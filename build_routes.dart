import 'package:climbingapp/hover_builder.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:climbingapp/hold.dart';
import 'package:climbingapp/hold_cut_out.dart';
import 'package:climbingapp/scaled_image.dart';
import 'package:climbingapp/selectable.dart';
import 'package:climbingapp/server.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum RouteCreationCursorMode {
  finish(mode: 0),
  start(mode: 1),
  hold(mode: 2);

  const RouteCreationCursorMode({required this.mode});

  final int mode;
}

RouteCreationCursorMode routeCursorMode = RouteCreationCursorMode.start;

class Route {
  Route({
    required this.startHoldA,
    required this.startHoldB,
    required this.finishHold,
    required this.activatedHolds,
    required this.id,
    required this.rating,
    required this.name,
  });

  final int id;
  int startHoldA;
  int startHoldB;
  int rating;
  String name;

  int finishHold;

  List<int> activatedHolds;

  List<String> getErrors() {
    int numStartHoldsMissing = 0;

    if (startHoldA == -1) numStartHoldsMissing += 1;
    if (startHoldB == -1) numStartHoldsMissing += 1;

    List<String> errors = [];

    if (numStartHoldsMissing != 0) {
      String identifier = numStartHoldsMissing == 1 ? "one" : "both";

      errors.add("Missing $identifier starting hold(s)");
    }

    if (finishHold == -1) {
      errors.add("Missing finish hold");
    }

    return errors;
  }

  bool hasErrors() {
    return getErrors().isNotEmpty;
  }
}

/// This Dart class represents a StatefulWidget for an EditRoutePage.
class EditRoutePage extends StatefulWidget {
  const EditRoutePage({super.key, required this.wallName});

  final String wallName;

  @override
  State<EditRoutePage> createState() => _EditRoutePageState();
}

int currentlySelectedRoute = -1;

class _EditRoutePageState extends State<EditRoutePage> {
  bool isLoading = true;

  late Image image;
  List<Hold> holds = [];
  List<Route> routes = [];
  double? imageWidth;
  double? imageHeight;

  void addRoute(dynamic routeResponse) {
    currentlySelectedRoute = routeResponse["id"];

    routes.add(Route(
      startHoldA: routeResponse["start_hold_a"],
      startHoldB: routeResponse["start_hold_b"],
      finishHold: routeResponse["finish_hold"],
      activatedHolds: routeResponse["activated_holds"].cast<int>(),
      name: routeResponse["route_name"],
      id: routeResponse["id"],
      rating: routeResponse["rating"],
    ));
  }

  void loadWallInformation() async {
    http.Response response = await Server.post(
      "getRouteEditingInfo",
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

      for (dynamic route in responseBody["wall data"]["routes"]) {
        addRoute(route);
      }

      if (routes.isNotEmpty) {
        currentlySelectedRoute = routes[0].id;
      } else {
        currentlySelectedRoute = -1;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void onHoldPressed(int holdID) {
    Hold hold = holds.firstWhere((e) => e.id == holdID);

    if (currentlySelectedRoute < 0) return;

    Route currentRoute = routes
        .firstWhere((candidate) => candidate.id == currentlySelectedRoute);

    if (routeCursorMode == RouteCreationCursorMode.start) {
      // If both are already set
      // then delete both and set A to the selected hold
      if (currentRoute.startHoldA != -1 && currentRoute.startHoldB != -1) {
        currentRoute.startHoldA = hold.id;
        currentRoute.startHoldB = -1;
      }

      // If neither are set
      // set A
      else if (currentRoute.startHoldA == -1 && currentRoute.startHoldB == -1) {
        currentRoute.startHoldA = hold.id;
      }

      // If only B is set
      // set A
      else if (currentRoute.startHoldA == -1 && currentRoute.startHoldB != -1) {
        currentRoute.startHoldA = hold.id;
      }

      // If only A is set
      // set B
      else if (currentRoute.startHoldA != -1 && currentRoute.startHoldB == -1) {
        currentRoute.startHoldB = hold.id;
      }
    } else if (routeCursorMode == RouteCreationCursorMode.hold) {
      if (!currentRoute.activatedHolds.contains(hold.id)) {
        currentRoute.activatedHolds.add(hold.id);
      } else {
        currentRoute.activatedHolds.remove(hold.id);
      }
    } else if (routeCursorMode == RouteCreationCursorMode.finish) {
      if (currentRoute.finishHold != hold.id) {
        currentRoute.finishHold = hold.id;
      } else {
        currentRoute.finishHold = -1;
      }
    }

    updateRoute(currentRoute);

    setState(() {});
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

  void updateRoute(Route currentRoute) {
    Server.post(
      "editRoute",
      {
        "name": widget.wallName,
        "start_hold_a": currentRoute.startHoldA,
        "start_hold_b": currentRoute.startHoldB,
        "finish_hold": currentRoute.finishHold,
        "activated_holds": currentRoute.activatedHolds,
        "rating": currentRoute.rating,
        "route_name": currentRoute.name,
        "id": currentRoute.id,
      },
      {},
    );
  }

  @override
  void initState() {
    super.initState();
    loadWallInformation();
  }

  Widget buildHoldAnnotationWidget(
      String text, double x, double y, double width, double height) {
    return Positioned(
      top: y.toDouble(),
      left: x.toDouble(),
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Color.fromARGB(70, 255, 255, 254),
          ),
          width: width,
          height: height,
          child: FittedBox(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(158, 0, 0, 0),
              ),
            ),
          ),
        ),
      ),
    );
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

    Size screenSize = MediaQuery.of(context).size;
    double routeBuilderWidth = screenSize.width * 0.2;
    double routeBuilderHeight = screenSize.height * 0.8;

    double scaleFactor =
        calculateScaleFactor(context, imageWidth!, imageHeight!, 0.6, 0.6);

    List<Widget> holdAnnotations = [];
    List<String> amplifiedColors = [];

    if (currentlySelectedRoute != -1) {
      Route currentRoute = routes
          .firstWhere((candidate) => candidate.id == currentlySelectedRoute);

      List<Hold> startHolds = [];

      if (currentRoute.startHoldA != -1) {
        startHolds
            .add(holds.firstWhere((e) => e.id == currentRoute.startHoldA));
      }
      if (currentRoute.startHoldB != -1) {
        startHolds
            .add(holds.firstWhere((e) => e.id == currentRoute.startHoldB));
      }

      String startIndicator = "1S";
      if (startHolds.length == 2 && startHolds[0].id == startHolds[1].id) {
        startIndicator = "2S";
      }

      for (Hold startHold in startHolds) {
        amplifiedColors.add(startHold.holdColorName);

        holdAnnotations.add(
          buildHoldAnnotationWidget(
            startIndicator,
            (startHold.xmin).toDouble(),
            (startHold.ymin).toDouble(),
            (startHold.xmax - startHold.xmin).toDouble(),
            (startHold.ymax - startHold.ymin).toDouble(),
          ),
        );
      }

      if (currentRoute.finishHold != -1) {
        Hold finishHold =
            holds.firstWhere((e) => e.id == currentRoute.finishHold);

        holdAnnotations.add(
          buildHoldAnnotationWidget(
            "F",
            (finishHold.xmin).toDouble(),
            (finishHold.ymin).toDouble(),
            (finishHold.xmax - finishHold.xmin).toDouble(),
            (finishHold.ymax - finishHold.ymin).toDouble(),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Edit Routes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: routeBuilderWidth,
                height: routeBuilderHeight,
                decoration: BoxDecoration(
                  color: Color.fromARGB(44, 100, 104, 129),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    TextButton(
                        onPressed: () async {
                          String name = "";
                          int i = 0;

                          while (true) {
                            String candidate = "$i";

                            bool contains = routes
                                .where((route) => route.name == candidate)
                                .isNotEmpty;

                            if (contains) {
                              i += 1;
                              continue;
                            }

                            name = candidate;
                            break;
                          }

                          dynamic routeRequest = {
                            "start_hold_a": -1,
                            "start_hold_b": -1,
                            "finish_hold": -1,
                            "activated_holds": [],
                            "route_name": name,
                            "name": widget.wallName,
                            "rating": 0,
                          };

                          http.Response response =
                              await Server.post("addRoute", routeRequest, {});

                          if (response.statusCode == 200) {
                            dynamic responseBody =
                                Server.getResponseBody(response);

                            int id = responseBody["id"];

                            routeRequest["id"] = id;

                            setState(() {
                              addRoute(routeRequest);
                            });
                          }
                        },
                        child: Text("Add New Route")),
                    Divider(
                      indent: 10.0,
                      endIndent: 10.0,
                    ),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: routes
                            .map((route) => buildRouteWidget(route))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 25),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTapUp: (_) {
                      if (holdHoverController.hoveredBox != null) {
                        onHoldPressed(holdHoverController.hoveredBox!);
                      }
                    },
                    child: ScaledWall(
                      imageWidth: imageWidth!,
                      imageHeight: imageHeight!,
                      heightFactor: 0.6,
                      child: SelectableViewer(
                        panEnabled: false,
                        selectionEnabled: false,
                        onSelection: (selection) async {},
                        child: CutOutHolds(
                          cutOffs: holds,
                          shouldShow: (hold) {
                            if (currentlySelectedRoute < 0) return false;

                            Route currentRoute = routes.firstWhere(
                                (candidate) =>
                                    candidate.id == currentlySelectedRoute);

                            if (currentRoute.startHoldA == hold.id) return true;
                            if (currentRoute.startHoldB == hold.id) return true;
                            if (currentRoute.finishHold == hold.id) return true;
                            if (currentRoute.activatedHolds.contains(hold.id))
                              return true;

                            return false;
                          },
                          child: Stack(
                            children: [
                              image,
                              ...holds.map(
                                (hold) => HoldWidget(
                                  hold: hold,
                                  widthMul: amplifiedColors
                                          .contains(hold.holdColorName)
                                      ? 10
                                      : 1,
                                ),
                              ),
                              ...holdAnnotations,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenSize.height * 0.2,
                    child: buildHoldAddMenu(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHoldAddMenu(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        holdAddMenuOption(
          "Add Start Hold",
          () => setState(() => routeCursorMode = RouteCreationCursorMode.start),
          routeCursorMode == RouteCreationCursorMode.start
              ? Colors.amber
              : Colors.blue,
        ),
        holdAddMenuOption(
          "Add Finish Hold",
          () =>
              setState(() => routeCursorMode = RouteCreationCursorMode.finish),
          routeCursorMode == RouteCreationCursorMode.finish
              ? Colors.amber
              : Colors.blue,
        ),
        holdAddMenuOption(
          "Add/Remove Hold",
          () => setState(() => routeCursorMode = RouteCreationCursorMode.hold),
          routeCursorMode == RouteCreationCursorMode.hold
              ? Colors.amber
              : Colors.blue,
        ),
      ],
    );
  }

  Widget holdAddMenuOption(String text, VoidCallback onPressed, Color color) {
    return TextButton(
      child: Text(
        text,
        style: TextStyle(
          color: color,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget buildRouteWidget(Route route) {
    TextEditingController ratingController =
        TextEditingController(text: route.rating.toString());

    TextEditingController nameController =
        TextEditingController(text: route.name);

    return Container(
      decoration: BoxDecoration(
        color: currentlySelectedRoute == route.id
            ? Color(0xFF646881)
            : Color.fromARGB(94, 100, 104, 129),
        borderRadius: BorderRadius.circular(5.0),
      ),
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 20.0,
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    currentlySelectedRoute = route.id;
                  });
                },
                icon: Icon(
                  Icons.remove_red_eye,
                  color: currentlySelectedRoute == route.id
                      ? Colors.amber
                      : Colors.grey,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () async {
                  http.Response response = await Server.post(
                    "removeRoute",
                    {
                      "name": widget.wallName,
                      "id": route.id,
                    },
                    {},
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      routes.removeWhere(
                          (candidateRoute) => candidateRoute.id == route.id);

                      if (route.id == currentlySelectedRoute) {
                        if (routes.isEmpty) {
                          currentlySelectedRoute = -1;
                        } else {
                          currentlySelectedRoute = routes.last.id;
                        }
                      }
                    });
                  }
                },
                child: Text("Delete",
                    style: TextStyle(fontSize: 12.0, color: Color(0xFF5AD2F4))),
              ),
            ],
          ),
          Row(
            children: [
              annotateHoldColorWidget(route.startHoldA),
              Spacer(),
              SizedBox(
                width: 80,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: nameController,
                  onChanged: (value) {
                    route.name = value;
                    updateRoute(route);
                  },
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: "Name",
                  ),
                ),
              ),
              Spacer(),
              annotateHoldColorWidget(route.startHoldB),
            ],
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 99, 99, 99),
                  ),
                  child: const ImageIcon(
                    AssetImage("assets/v.png"),
                    color: Color(0xFF5AD2F4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(45, 255, 255, 255),
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: ratingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (value) {
                        route.rating = int.tryParse(value) ?? 0;
                        updateRoute(route);
                      },
                      decoration: const InputDecoration.collapsed(
                        hintText: "0",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...route
              .getErrors()
              .map(
                (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Warning",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 7),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(e),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Container annotateHoldColorWidget(int holdID) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: holdID != -1
            ? nameToColor(holds.firstWhere((e) => e.id == holdID).holdColorName)
            : Colors.black,
      ),
      width: 28,
      height: 28,
    );
  }
}
