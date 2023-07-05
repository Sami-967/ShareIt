import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userName = Random().nextInt(10000).toString();

  final Strategy strategy = Strategy.P2P_STAR;

  Map<String, ConnectionInfo> endpointMap = {};

  String? tempFileUri;
  //reference to the file currently being transferred
  Map<int, String> map = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: const Text(
          "Share File",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            left: 185,
            child: SizedBox(
              height: 150.0,
              width: 180.0,
              child: RawMaterialButton(
                shape: const CircleBorder(),
                fillColor: Colors.green,
                onPressed: () async {
                  Nearby().askExternalStoragePermission();

                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowMultiple: true,
                    allowedExtensions: ['jpg', 'pdf', 'doc', 'mp4'],
                  );

                  try {
                    if (await Nearby().enableLocationServices()) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Location Service Enabled :)")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Enabling Location Service Failed :(")));
                    }
                    bool a = await Nearby().startAdvertising(
                      userName,
                      strategy,
                      onConnectionInitiated: onConnectionInit,
                      onConnectionResult: (id, status) {
                        showSnackbar(status);
                      },
                      onDisconnected: (id) {
                        showSnackbar(
                            "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
                        setState(() {
                          endpointMap.remove(id);
                        });
                      },
                    );

                    showSnackbar("ADVERTISING: $a");
                  } catch (exception) {
                    showSnackbar(exception);
                  }
                  if (result == null) return;
                  List<File> files =
                      result.paths.map((path) => File(path!)).toList();
                  for (MapEntry<String, ConnectionInfo> m
                      in endpointMap.entries) {
                    for (var file in files) {
                      int payloadId =
                          await Nearby().sendFilePayload(m.key, file.path);
                      showSnackbar("Sending file to ${m.key}");
                      Nearby().sendBytesPayload(
                          m.key,
                          Uint8List.fromList(
                              "$payloadId:${file.path.split('/').last}"
                                  .codeUnits));
                    }
                  }
                },
                child: const Text("Send",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20)),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 10,
            child: SizedBox(
              height: 200.0,
              width: 200.0,
              child: RawMaterialButton(
                shape: const CircleBorder(),
                onPressed: () async {
                  await Nearby().askLocationPermission();
                  if (await Nearby().enableLocationServices()) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Location Service Enabled :)")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Enabling Location Service Failed :(")));
                  }
                  try {
                    bool a = await Nearby().startDiscovery(
                      userName,
                      strategy,
                      onEndpointFound: (id, name, serviceId) {
                        // show sheet automatically to request connection
                        showModalBottomSheet(
                          context: context,
                          builder: (builder) {
                            return Center(
                              child: Column(
                                children: <Widget>[
                                  Text("id: $id"),
                                  Text("Name: $name"),
                                  Text("ServiceId: $serviceId"),
                                  ElevatedButton(
                                    child: const Text("Request Connection"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Nearby().requestConnection(
                                        userName,
                                        id,
                                        onConnectionInitiated: (id, info) {
                                          onConnectionInit(id, info);
                                        },
                                        onConnectionResult: (id, status) {
                                          showSnackbar(status);
                                        },
                                        onDisconnected: (id) {
                                          setState(() {
                                            endpointMap.remove(id);
                                          });
                                          showSnackbar(
                                              "Disconnected from: ${endpointMap[id]!.endpointName}, id $id");
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      onEndpointLost: (id) {
                        showSnackbar(
                            "Lost discovered Endpoint: ${endpointMap[id]!.endpointName}, id $id");
                      },
                    );
                    showSnackbar("DISCOVERING: $a");
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
                fillColor: Colors.blueAccent,
                child: const Text("Receive",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20)),
              ),
            ),
          ),
          const Positioned(
            top: 280,
            left: 185,
            child: SizedBox(
              height: 150.0,
              width: 180.0,
              child: RawMaterialButton(
                shape: CircleBorder(),
                onPressed: null,
                fillColor: Colors.amberAccent,
                child: Text("Files",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20)),
              ),
            ),
          ),
          Positioned(
            top: 380,
            left: 10,
            child: SizedBox(
              height: 200.0,
              width: 180.0,
              child: RawMaterialButton(
                shape: const CircleBorder(),
                onPressed: () async {
                  await Nearby().stopAllEndpoints();
                  setState(() {
                    endpointMap.clear();
                  });
                },
                fillColor: Colors.red,
                child: const Text("Disconnect",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20)),
              ),
            ),
          )
        ],
      ),
    );
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = (await getExternalStorageDirectory())!.absolute.path;
    final b =
        await Nearby().copyFileAndDeleteOriginal(uri, '$parentDir/$fileName');

    showSnackbar("Moved file:$b");
    return b;
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                child: const Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);
                        showSnackbar("$endid: $str");

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);

                          if (map.containsKey(payloadId)) {
                            if (tempFileUri != null) {
                              moveFile(tempFileUri!, fileName);
                            } else {
                              showSnackbar("File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("$endid: File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                        showSnackbar("$endid: FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        showSnackbar(
                            "$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id]!;
                          moveFile(tempFileUri!, name);
                        } else {
                          //bytes not received till yet
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
                    },
                  );
                },
              ),
              ElevatedButton(
                child: const Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
