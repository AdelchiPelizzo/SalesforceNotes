import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:salesforcenotes/views/media.dart';
import 'package:salesforcenotes/views/notes_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/user_secure_storage.dart';
import '/utils/metadata_salesforce.dart';

class NewNote extends StatefulWidget {
  // final XFile? xf;
  final List<double> coord;
  final String path;
  const NewNote({
    super.key,
    required this.path,
    required this.coord,
    // required this.xf,
  });

  @override
  State<NewNote> createState() => _NewNoteState();
}

class _NewNoteState extends State<NewNote> {
  late final Future<SharedPreferences> _prefs;
  late final TextEditingController _textController;
  late final TextEditingController _fileNameController;
  late final XFile? _image;
  late final List<XFile>? _images;
  late final ImagePicker _picker;
  late final String _mediaPath;
  List<double> coordinates = [];
  String objectName = '';
  late Future<List<String>?> objectNames;
  late final MetadataSalesforce mds;

  Future<String?> getDomain() async {
    final String? domain = await UserSecureStorage.getDomainName();
    return domain;
  }

  Future<String?> getToken() async {
    final String? token = await UserSecureStorage.getToken();
    return token;
  }

  @override
  void initState() {
    _prefs = SharedPreferences.getInstance();
    _textController = TextEditingController();
    _fileNameController = TextEditingController();
    _picker = ImagePicker();
    _mediaPath = widget.path;
    coordinates = widget.coord;
    objectNames = getSObjectsList();
    mds = MetadataSalesforce();
    super.initState();
  }

  sendImage() async {
    _image = await _picker.pickImage(source: ImageSource.gallery);
  }

  sendImages() async {
    _images = await _picker.pickMultiImage();
  }

  Future<List<String>?> getSObjectsList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getStringList('key');
  }

  getMetadataFromSalesforce() {
    mds.getObjectNames();
  }

  bool res = true;

  Future<void> _showMyDialog<String>(missingData) async {
    var data = missingData;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Missing Data'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Missing $data'),
                const Text('Complete the form data before submit'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => {
                res = false,
                Navigator.pop(context, 'Cancel'),
              },
              // onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResponseDialog<String>() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Response'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Success'),
                Text('Data saved successfully'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  sendNote() async {
    final dataEndpoint = Uri(
      scheme: 'https',
      host: await getDomain(),
      path: 'services/data/v56.0/sobjects/${objectName}__c',
    );
    String? accessToken = await getToken();
    String? note = _textController.text;
    String? fileName = _fileNameController.text;
    if (note == '') {
      await _showMyDialog('Note body');
    }
    print(dataEndpoint.toString());
    final response = await http.post(
      dataEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body:
          '{"text__c": "$note", "Location__Latitude__s": "${coordinates[0].toDouble()}", "Location__Longitude__s": "${coordinates[1].toDouble()}"}',
    );

    if (_mediaPath == '') {
      await _showMyDialog('Media Not present');
      if (res == false) {
        return;
      }
    }

    if (fileName == '') {
      await _showMyDialog('Enter file name');
    }

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('path ... ${_mediaPath}');

    final bytes = File(_mediaPath).readAsBytesSync();
    String img64 = base64Encode(bytes);

    final contentEndpoint = Uri(
      scheme: 'https',
      host: await getDomain(),
      path: 'services/data/v56.0/sobjects/ContentVersion',
    );
    var respons = json.decode(response.body);
    var id18 = respons["id"].toString();
    final contentResponse = await http.post(
      contentEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body:
          '{"Title": "${fileName}.gif","PathOnClient": "$_mediaPath","ContentLocation": "S","FirstPublishLocationId": "' +
              '$id18' +
              '","VersionData": "$img64"}',
    );
    print('response success >>> ' + (respons['success'] == true).toString());
    if (respons['success'] == true) {
      print('alert >> ');
      _showResponseDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: <Widget>[
          FutureBuilder<List<String>?>(
            future: objectNames,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 50 ),
                  child: SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.blue,
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                        // enabledBorder: OutlineInputBorder(
                        //     borderSide: BorderSide(color: Colors.white)),
                        // border: OutlineInputBorder(
                        //     borderSide: BorderSide(color: Colors.purple)),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        backgroundColor: Colors.blue,
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_downward_outlined,
                        color: Colors.white,
                      ),
                      hint: const Text(
                        'Select an object',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // value: objectName,
                      items: snapshot.data
                          ?.map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        objectName = value.toString();
                        setState(() {
                          objectName = value.toString();
                        });
                      },
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return const CircularProgressIndicator();
            },
          ),
          // IconButton(
          //   onPressed: () => {},
          //   icon: const Icon(Icons.create),
          // )
        ],
      ),
      body: Center(
        child: Column(children: [
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.fromLTRB(0.0, 20, 0.0, 5.0),
            child: Text(
              'Message Body',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLines: null,
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Write your Note here.',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              keyboardType: TextInputType.text,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0.0, 20, 0.0, 5.0),
            child: Text(
              'File Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLines: null,
              controller: _fileNameController,
              decoration: const InputDecoration(
                hintText: 'Write your file name here.',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              keyboardType: TextInputType.text,
            ),
          ),
          // Text(
          //   coordinates.toString(),
          //   style: const TextStyle(fontSize: 30),
          // ),
          const SizedBox(height: 15),
          if (widget.path != '')
            Flexible(
              child: Image.file(File(widget.path)),
            ),
          const SizedBox(height: 15),
          // FutureBuilder<List<String>?>(
          //   future: objectNames,
          //   builder: (context, snapshot) {
          //     if (snapshot.hasData) {
          //       return SizedBox(
          //         width: 220,
          //         child: DropdownButtonFormField<String>(
          //           decoration: const InputDecoration(
          //               contentPadding:
          //                   EdgeInsets.symmetric(vertical: 0, horizontal: 9),
          //               enabledBorder: OutlineInputBorder(
          //                   borderSide: BorderSide(color: Colors.black12)),
          //               border: OutlineInputBorder(
          //                   borderSide: BorderSide(color: Colors.purple))),
          //           style: const TextStyle(fontSize: 18, color: Colors.black),
          //           icon: const Icon(
          //             Icons.arrow_downward_outlined,
          //           ),
          //           hint: const Text('Select an object'),
          //           // value: objectName,
          //           items: snapshot.data
          //               ?.map((value) => DropdownMenuItem(
          //                     value: value,
          //                     child: Text(value),
          //                   ))
          //               .toList(),
          //           onChanged: (value) {
          //             objectName = value.toString();
          //             setState(() {
          //               objectName = value.toString();
          //             });
          //           },
          //         ),
          //       );
          //     } else if (snapshot.hasError) {
          //       return Text("${snapshot.error}");
          //     }
          //     return const CircularProgressIndicator();
          //   },
          // ),
          const SizedBox(height: 15),
          // Text(xf.toString()),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        //Floating action button on Scaffold
        onPressed: sendNote,
        child: const Icon(Icons.send), //icon inside button
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        //bottom navigation bar on scaffold
        color: Colors.redAccent,
        shape: const CircularNotchedRectangle(), //shape of notch
        notchMargin:
            5, //notche margin between floating button and bottom appbar
        child: Row(
          //children inside bottom appbar
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: IconButton(
                icon: const Icon(
                  Icons.photo,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMedia(),
                      ));
                },
              ),
            ),
            // FutureBuilder<List<String>?>(
            //   future: objectNames,
            //   builder: (context, snapshot) {
            //     if (snapshot.hasData) {
            //       return SizedBox(
            //         width: 180,
            //         child: DropdownButtonFormField<String>(
            //           decoration: const InputDecoration(
            //               contentPadding:
            //                   EdgeInsets.symmetric(vertical: 0, horizontal: 9),
            //               enabledBorder: OutlineInputBorder(
            //                   borderSide: BorderSide(color: Colors.black12)),
            //               border: OutlineInputBorder(
            //                   borderSide: BorderSide(color: Colors.purple))),
            //           style: const TextStyle(fontSize: 18, color: Colors.black),
            //           icon: const Icon(
            //             Icons.arrow_downward_outlined,
            //           ),
            //           hint: const Text('Select an object'),
            //           // value: objectName,
            //           items: snapshot.data
            //               ?.map((value) => DropdownMenuItem(
            //                     value: value,
            //                     child: Text(value),
            //                   ))
            //               .toList(),
            //           onChanged: (value) {
            //             objectName = value.toString();
            //             setState(() {
            //               objectName = value.toString();
            //             });
            //           },
            //         ),
            //       );
            //     } else if (snapshot.hasError) {
            //       return Text("${snapshot.error}");
            //     }
            //     return const CircularProgressIndicator();
            //   },
            // ),
            Padding(
              padding: const EdgeInsets.only(right: 80),
              child: IconButton(
                icon: const Icon(
                  Icons.list,
                  color: Colors.white,
                ),
                onPressed: () {
                  print(objectName);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesList(objName: objectName),
                      ));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
