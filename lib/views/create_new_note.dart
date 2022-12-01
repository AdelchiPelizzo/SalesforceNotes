import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:salesforcenotes/views/media.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/user_secure_storage.dart';
import '/utils/metadata_salesforce.dart';

class NewNote extends StatefulWidget {
  final String path;
  const NewNote({
    super.key,
    required this.path,
  });

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
  String objectName = '';
  late Future<List<String>?> objectNames;
  late final MetadataSalesforce mds ;

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

  getMetadataFromSalesforce(){
    mds.getObjectNames();
    // mds.getTableEnumOrId();
  }

  sendNote() async {
    final dataEndpoint = Uri(
      scheme: 'https',
      host: await getDomain(),
      path: 'services/data/v56.0/sobjects/' + objectName + '__c',
    );
    String? accessToken = await getToken();
    String? note = _textController.text;
    print(dataEndpoint.toString());
    final response = await http.post(
      dataEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{"text__c": "$note"}',
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
    final contentResponse = await http.post(
      contentEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body:
          '{"Title": "myFile5.gif","PathOnClient": "$_mediaPath","ContentLocation": "S","FirstPublishLocationId": "' +
              '$id18' +
              '","VersionData": "$img64"}',
    );
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
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 20)),
            // onPressed: getMetadataFromSalesforce,s
            onPressed: sendNote,
            child: const Text('Send Note'),
          ),
          const SizedBox(height: 30),
          const Text('Object Selected'),
          Text(
            objectName,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 30),
          // OutlinedButton(
          //     style: OutlinedButton.styleFrom(
          //     shape: const StadiumBorder(),
          //     side: const BorderSide(
          //       width: 2,
          //       color: Colors.blue,
          //     ),
          //   ),
          //   onPressed: sendNote,
          //   child: const Text('Send Note'),
          // ),
          FutureBuilder<List<String>?>(
            future: objectNames,
            builder: (context, snapshot) {
              print('object data  ' + objectName);
              if (snapshot.hasData) {
                print('snapshot data  ' + snapshot.data.toString());
                return DropdownButton<String>(
                  icon: const Icon(
                    Icons.arrow_drop_down,
                  ),
                  hint: const Text('Select an object'),
                  // value: objectName,
                  items: snapshot.data
                      ?.map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    objectName = value.toString();
                    setState(() {
                      objectName = value.toString();
                    });
                    print('object selected  ' + objectName);
                  },
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return const CircularProgressIndicator();
            },
          ),
          if (widget.path != '')
            Flexible(
              child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Expanded(
                child: Image.file(File(widget.path)),
              ),
            )),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: ((context) => const AddMedia())));
        },
        heroTag: 'image0',
        tooltip: 'Pick Image from gallery',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
