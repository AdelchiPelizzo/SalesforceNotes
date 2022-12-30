import 'dart:convert';
import 'dart:ffi';
// import 'dart:html';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/user_secure_storage.dart';

class NoteDetail extends StatefulWidget {
  final String noteId;
  final String noteText;
  const NoteDetail({
    super.key,
    required this.noteId,
    required this.noteText,
  });

  @override
  State<NoteDetail> createState() => _NoteDetailState();
}

class _NoteDetailState extends State<NoteDetail> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final String _id;
  late final String _text;
  @override
  void initState() {
    super.initState();
    _id = widget.noteId;
    _text = widget.noteText;
  }

  bool isFilePresent = true;

  Future<String> getContentVersionId(String noteId) async {
    print('noteId '+noteId);
    var params = {
      "q": "select ContentDocument.LatestPublishedVersionId from ContentDocumentLink where LinkedEntityId = '$noteId'",
    };
    final dataEndpoint = Uri(
      scheme: 'https',
      host: await UserSecureStorage.getDomainName(),
      path: "/services/data/v56.0/query/",
      queryParameters: params,
      // path: "/services/data/v56.0/query?q=select+ContentDocument.LatestPublishedVersionId+from+ContentDocumentLink+where+LinkedEntityId='$noteId'",
    );
    String? accessToken = await UserSecureStorage.getToken();
    print(dataEndpoint.toString());
    final response = await http.get(
      dataEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    print("response "+response.body.toString());
    List<String> ids = [];
    Map responseDecoded = jsonDecode(response.body);
    if(responseDecoded['records'].length < 1){
      isFilePresent = false;

    }
    for (int i = 0; i < responseDecoded['records'].length; i++) {
      String idList = responseDecoded["records"][i]['ContentDocument']['LatestPublishedVersionId'];
      ids.add(idList);
    }
    // String base64string = base64.encode(imagebytes);
    // XFile img = XFile.fromData(imagebytes);
    return ids[0];

  }

  Future<Uint8List> getFile(String noteId) async {
    String contentVersionId = await getContentVersionId(noteId);
    final dataEndpoint = Uri(
      scheme: 'https',
      host: await UserSecureStorage.getDomainName(),
      path: 'services/data/v56.0/sobjects/ContentVersion/$contentVersionId/VersionData',
      // path: "/services/data/v56.0/query?q=select+ContentDocument.LatestPublishedVersionId+from+ContentDocumentLink+where+LinkedEntityId='$noteId'",
    );
    String? accessToken = await UserSecureStorage.getToken();
    print(dataEndpoint.toString());
    final response = await http.get(
      dataEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    print("response.body.runtimeType "+Base64Decoder().runtimeType.toString());
    Uint8List imagebytes = response.bodyBytes;
    // String base64string = base64.encode(imagebytes);
    // XFile img = XFile.fromData(imagebytes);
    return imagebytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Note Title: $_text',
        ),
        centerTitle: true,
      ),
        // appBar: AppBar(
        //   leading: const BackButton(
        //     color: Colors.black,
        //   ),
        //   actions: const [],
        //   title: Center(
        //     child: Text(
        //       'Note Title: $_text',
        //     ),
        //   ),
        // ),
        body: Center(
          // ignore: prefer_const_literals_to_create_immutables
          child: Column(children: [
            const SizedBox(height: 15),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(0.0, 20, 0.0, 5.0),
            //   child: Text(
            //     'note id $_id',
            //     style: const TextStyle(
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            FutureBuilder<Uint8List>(
              future: getFile(_id),
              builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                if(snapshot.hasData){
                  final Uint8List bytes = snapshot.data!;
                  return Container(
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.all(5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.lightBlue, //                   <--- border color
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Image.memory(bytes)
                  );
                  // return Image.memory(base64.decode(snapshot.data!));
                  // return Text(snapshot.data.runtimeType.toString());
                  // return snapshot.data;
                }else if(isFilePresent){
                  return Column(
                    children: const [
                      Text('Please wait.'),
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                        minHeight: 25,
                      ),
                    ],
                  );
                }else {
                  return const Text('No Image found');
                }
               },
            )
          ]),
        ));
  }
}
