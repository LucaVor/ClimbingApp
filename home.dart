import 'dart:convert';
import 'dart:typed_data';

import 'package:climbingapp/build_routes.dart';
import 'package:climbingapp/edit_wall.dart';
import 'package:climbingapp/server.dart';
import 'package:climbingapp/view_wall.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  List<String> walls = [];

  void getWalls() async {
    http.Response response = await Server.post("getWalls", {}, {});

    if (response.statusCode == 200) {
      dynamic responseBody = Server.getResponseBody(response);

      walls = responseBody.cast<String>();

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getWalls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Home",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(32.0),
              child: ListView(
                children: [
                  const Text(
                    "Walls",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  ...walls.map(
                    (wallName) => buildWallElement(context, wallName),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddDialogue(context);
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }

  Container buildWallElement(BuildContext context, String wallName) {
    return Container(
      width: 100,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 16.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(wallName, style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (cxt) => ViewWallPage(
                        wallName: wallName,
                      ),
                    ),
                  );
                },
                child: Text("View Wall",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (cxt) => EditWallPage(
                        wallName: wallName,
                      ),
                    ),
                  );
                },
                child: Text("Edit Wall Holds",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (cxt) => EditRoutePage(
                        wallName: wallName,
                      ),
                    ),
                  );
                },
                child: Text("Edit Routes",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget labeled(String label, Widget child) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 10),
        child
      ],
    );
  }

  void showAddDialogue(BuildContext context) {
    TextEditingController wallName = TextEditingController();
    bool hasFileUploaded = false;
    Uint8List? fileBytes;
    String? fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (innerCxt) => StatefulBuilder(
        builder: (builderContext, builderSetState) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(16.0),
            children: isUploading
                ? [const Center(child: CircularProgressIndicator())]
                : [
                    const Center(
                      child: Text(
                        "Add a new Wall!",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20.0),
                      ),
                    ),
                    const SizedBox(height: 50),
                    TextField(
                      controller: wallName,
                      decoration:
                          const InputDecoration(hintText: "Name of Wall"),
                    ),
                    const SizedBox(height: 25),
                    TextButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          allowedExtensions: ["jpg"],
                          type: FileType.custom,
                        );

                        if (result != null) {
                          builderSetState(() {
                            fileBytes = result.files.first.bytes;
                            fileName = result.files.first.name;

                            hasFileUploaded = true;
                          });
                        }
                      },
                      child: const Text("Upload Image of Wall"),
                    ),
                    const SizedBox(height: 25),
                    hasFileUploaded
                        ? Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.cyan,
                            ),
                            child: TextButton(
                              onPressed: () async {
                                builderSetState(() {
                                  isUploading = true;
                                });

                                String base64image = base64Encode(fileBytes!);

                                http.Response response = await Server.post(
                                  "createWall",
                                  {
                                    "name": wallName.text,
                                    "imageBytes": base64image
                                  },
                                  {},
                                );

                                if (response.statusCode == 200) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (cxt) => EditWallPage(
                                        wallName: wallName.text,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                  "Create Wall [${fileName ?? "Unknown"}]"),
                            ),
                          )
                        : const SizedBox(),
                  ],
          );
        },
      ),
    );
  }
}
