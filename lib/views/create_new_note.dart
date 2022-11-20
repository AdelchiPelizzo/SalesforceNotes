import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salesforcenotes/views/media.dart';
import 'package:salesforcenotes/views/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/user_secure_storage.dart';
import '../views/media.dart';

class NewNote extends StatefulWidget {
  final String path ;
  const NewNote({super.key, required this.path, });

  @override
  State<NewNote> createState() => _NewNoteState();
}

class _NewNoteState extends State<NewNote> {
  late final Future<SharedPreferences> _prefs;
  late final TextEditingController _textController;
  late final XFile? _image;
  late final List<XFile>? _images;
  late final ImagePicker _picker;
  late final String _mediaPath;

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
    _picker = ImagePicker();
    _mediaPath = widget.path;
    super.initState();
  }

  sendImage() async {
    _image = await _picker.pickImage(source: ImageSource.gallery);
  }

  sendImages() async {
    _images =  await _picker.pickMultiImage();
  }
    // Pick an image
    // Capture a photo
    // final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    // // Pick a video
    // final XFile? image = await _picker.pickVideo(source: ImageSource.gallery);
    // // Capture a video
    // final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    // // Pick multiple images
    // final List<XFile>? images = await _picker.pickMultiImage();

  // Future<String>



  Future<List<String>?> getSObjectsList() async {
     SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getStringList('key');
  }


  // getObjects() async {

  //   final metadataEndpoint = Uri(
  //       scheme: 'https',
  //       host: await getDomain(),
  //       path: "/services/data/v56.0/tooling/query/",
  //       query: 'q=SELECT+DeveloperName+FROM+CustomObject',
  //     );
  //   String? accessToken = await getToken();
  //   String? note = _textController.text;
  //   final response = await http.get(
  //     metadataEndpoint,
  //     headers: <String, String>{
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $accessToken',
  //     },
  //   );
  //   // print(metadataEndpoint);
  //   // print('Response status: ${response.statusCode}');
  //   // print('Response body: ${response.body}');
  //   // print(response.body.runtimeType);

  //   Map<String, dynamic> sobjects = jsonDecode(response.body);
  //   List<dynamic> records = sobjects['records'];
  //   List<String> objectsNames = [];
  //   for(dynamic object in records){
  //     print(object['DeveloperName']);
  //     objectsNames.add(object['DeveloperName']);
  //   }

  //   print('names list >  ${objectsNames}');

  //   return objectsNames;
  //   // print('We sent the verification link to ${user['email']}.');
  // }

  sendNote() async {
    final dataEndpoint = Uri(
        scheme: 'https',
        host: await getDomain(),
        path: 'services/data/v56.0/sobjects/MyNote__c');
    String? accessToken = await getToken();
    String? note = _textController.text;
    final response = await http.post(
      dataEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{"text__c": "$note"}',
      // body: jsonEncode(<String, String>{
      //   'text__c': 'from Flutter 2--33--45',
      // }
      // ),
    );

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
    var id15 = id18.substring(0,15);
    final contentResponse = await http.post(
      contentEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{"Title": "myFile5.gif","PathOnClient": "$_mediaPath","ContentLocation": "S","FirstPublishLocationId": "'+'$id18'+'","VersionData": "$img64"}',
      // body: jsonEncode(<String, String>{
      //   'text__c': 'from Flutter 2--33--45',
      // }
      // ),
    );

    print('content response ${contentResponse.body}');

    // return response.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Create New Note'),
          actions: [
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.create),
            )
          ],
        ),
        body: Center(
          child: Column(children: [
            TextField(
              controller: _textController,
              decoration:
                  const InputDecoration(hintText: 'Write your Note here.'),
              autofocus: false,
              maxLines: null,
              keyboardType: TextInputType.text,
            ),
            TextButton(
              onPressed: sendNote,
              child: const Text('Send Note'),
            ),
            FutureBuilder <List<String>?> (
              future: getSObjectsList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DropdownButton<String>(
                    icon: const Icon(
                      Icons.arrow_drop_down,
                    ),
                    hint: const Text('Select an object'),
                    items: snapshot.data
                        ?.map((value) => DropdownMenuItem(
                              child: Text(value),
                              value: value,
                            ))
                        .toList(),
                    onChanged: (value) {
                      print(value);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return const CircularProgressIndicator();
              },
            ),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: ((context) => const AddMedia())));
                // isVideo = false;
                // _onImageButtonPressed(ImageSource.gallery, context: context);
              },
              heroTag: 'image0',
              tooltip: 'Pick Image from gallery',
              child: const Icon(Icons.add_a_photo),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                widget.path,
                style:  const TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 20,
                )
              ),
            ),
            if(widget.path != '')
            Expanded(
              child: Image.file(File(widget.path)),
            ),
            // const AddMedia(),
            // DropdownButtonFormField<String>(
            //   items: getSObjectsList().map((String value) {
            //     return DropdownMenuItem<String>(
            //       value: value,
            //       child: Text(value),
            //     );
            //   }).toList(),
            //   onChanged: (_) {},
            // ),
            // TextButton(
            //   onPressed: getObjects,
            //   child: const Text('Get Objects'),
            // ),
          ]),
        ),
        // floatingActionButton: Column(
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   children: <Widget>[
        //   Semantics(
        //     label: 'image_picker_example_from_gallery',
        //     child: FloatingActionButton(
        //       onPressed: () {
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //               builder: ((context) => const AddMedia())));
        //         // isVideo = false;
        //         // _onImageButtonPressed(ImageSource.gallery, context: context);
        //       },
        //       heroTag: 'image0',
        //       tooltip: 'Pick Image from gallery',
        //       child: const Icon(Icons.photo),
        //     ),
        //   ),
        //   Padding(
        //     padding: const EdgeInsets.only(top: 16.0),
        //     child: FloatingActionButton(
        //       onPressed: () {
        //         // isVideo = false;
        //         // _onImageButtonPressed(
        //         //   ImageSource.gallery,
        //         //   context: context,
        //         //   isMultiImage: true,
        //         // );
        //       },
        //       heroTag: 'image1',
        //       tooltip: 'Pick Multiple Image from gallery',
        //       child: const Icon(Icons.photo_library),
        //     ),
        //   ),
        //   Padding(
        //     padding: const EdgeInsets.only(top: 16.0),
        //     child: FloatingActionButton(
        //       onPressed: () {
        //         // isVideo = false;
        //         // _onImageButtonPressed(ImageSource.camera, context: context);
        //       },
        //       heroTag: 'image2',
        //       tooltip: 'Take a Photo',
        //       child: const Icon(Icons.camera_alt),
        //     ),
        //   ),
        //   Padding(
        //     padding: const EdgeInsets.only(top: 16.0),
        //     child: FloatingActionButton(
        //       backgroundColor: Colors.red,
        //       onPressed: () {
        //         // isVideo = true;
        //         // _onImageButtonPressed(ImageSource.gallery);
        //       },
        //       heroTag: 'video0',
        //       tooltip: 'Pick Video from gallery',
        //       child: const Icon(Icons.video_library),
        //     ),
        //   ),
        //   Padding(
        //     padding: const EdgeInsets.only(top: 16.0),
        //     child: FloatingActionButton(
        //       backgroundColor: Colors.red,
        //       onPressed: () {
        //         // isVideo = true;
        //         // _onImageButtonPressed(ImageSource.camera);
        //       },
        //       heroTag: 'video1',
        //       tooltip: 'Take a Video',
        //       child: const Icon(Icons.videocam),
        //     ),
        //   ),
        // ],

        // ),
      );
  }
}
