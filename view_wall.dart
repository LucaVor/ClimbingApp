import 'package:climbingapp/hold.dart';
import 'package:climbingapp/build_routes.dart' as route_builder;

import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:climbingapp/hold_cut_out.dart';
import 'package:climbingapp/scaled_image.dart';
import 'package:climbingapp/selectable.dart';
import 'package:climbingapp/server.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewWallPage extends StatefulWidget {
  const ViewWallPage({
    super.key,
    required this.wallName,
  });

  final String wallName;

  @override
  State<ViewWallPage> createState() => _ViewWallPageState();
}

class _ViewWallPageState extends State<ViewWallPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;

  late Image image;

  List<Hold> holds = [];
  List<route_builder.Route> routes = [];

  double? imageWidth;
  double? imageHeight;

  int currentRouteIdx = -1;

  void addRoute(dynamic routeResponse) {
    route_builder.Route route = route_builder.Route(
      startHoldA: routeResponse["start_hold_a"],
      startHoldB: routeResponse["start_hold_b"],
      finishHold: routeResponse["finish_hold"],
      activatedHolds: routeResponse["activated_holds"].cast<int>(),
      name: routeResponse["route_name"],
      id: routeResponse["id"],
      rating: routeResponse["rating"],
    );

    if (route.hasErrors()) {
      return;
    }

    routes.add(route);
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
        onPressed: (_) {},
      ),
    );
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

      routes.sort(
        (a, b) => a.rating.compareTo(b.rating),
      );

      if (routes.isNotEmpty) {
        currentRouteIdx = routes[0].id;
      }

      setState(() {
        isLoading = false;
      });
    }
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

    if (routes.length == 0) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "View Wall",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
              "This wall has NO valid routes. Cannot view without at least one."),
        ),
      );
    }

    route_builder.Route route =
        routes.firstWhere((e) => e.id == currentRouteIdx);

    Size screenSize = MediaQuery.of(context).size;

    double scaleFactor =
        calculateScaleFactor(context, imageWidth!, imageHeight!, 0.7, 0.9);

    List<Widget> holdAnnotations = [];

    List<Hold> startHolds = [];

    if (route.startHoldA != -1) {
      startHolds.add(holds.firstWhere((e) => e.id == route.startHoldA));
    }
    if (route.startHoldB != -1) {
      startHolds.add(holds.firstWhere((e) => e.id == route.startHoldB));
    }

    String startIndicator = "1S";
    if (startHolds.length == 2 && startHolds[0].id == startHolds[1].id) {
      startIndicator = "2S";
    }

    for (Hold startHold in startHolds) {
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

    Hold finishHold = holds.firstWhere((e) => e.id == route.finishHold);

    holdAnnotations.add(
      buildHoldAnnotationWidget(
        "F",
        (finishHold.xmin).toDouble(),
        (finishHold.ymin).toDouble(),
        (finishHold.xmax - finishHold.xmin).toDouble(),
        (finishHold.ymax - finishHold.ymin).toDouble(),
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: BottomAppBar(
        child: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Show Routes"),
              const SizedBox(width: 1),
              IconButton(
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
                icon: const Icon(
                  Icons.route,
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "View Wall",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawerScrimColor: Colors.transparent,
      drawer: new Drawer(
        child: new ListView(
          children: buildRouteList(),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ScaledWall(
                imageWidth: imageWidth!,
                imageHeight: imageHeight!,
                heightFactor: 0.7,
                widthFactor: 0.9,
                child: SelectableViewer(
                  panEnabled: true,
                  selectionEnabled: false,
                  onSelection: (selection) async {},
                  child: CutOutHolds(
                    cutOffs: holds,
                    shouldShow: (hold) {
                      return holdShouldBeDisplayed(hold, route);
                    },
                    child: Stack(
                      children: [
                        image,
                        ...holds.map(
                          (hold) => HoldWidget(
                            hold: hold,
                            widthMul: 0,
                          ),
                        ),
                        ...holdAnnotations,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool holdShouldBeDisplayed(Hold hold, route_builder.Route route) {
    if (route.startHoldA == hold.id) return true;
    if (route.startHoldB == hold.id) return true;
    if (route.finishHold == hold.id) return true;
    if (route.activatedHolds.contains(hold.id)) return true;

    return false;
  }

  List<Widget> buildRouteList() {
    List<Widget> routeWidgets = [];
    int lastRating = -1;

    for (route_builder.Route route in routes) {
      if (route.rating != lastRating) {
        lastRating = route.rating;

        routeWidgets.add(SizedBox(height: 20));
        routeWidgets.add(Center(
            child: Text("V${lastRating}",
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0))));
        routeWidgets.add(Divider());
        routeWidgets.add(SizedBox(height: 10));
      }

      routeWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              currentRouteIdx = route.id;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: currentRouteIdx == route.id
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
                  children: [
                    Text(route.name),
                    Spacer(),
                    Text("V${route.rating}"),
                  ],
                ),
                Row(
                  children: [
                    annotateHoldColorWidget(route.startHoldA),
                    Spacer(),
                    annotateHoldColorWidget(route.startHoldB),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return routeWidgets;
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
