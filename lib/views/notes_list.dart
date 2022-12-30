// ignore_for_file: unnecessary_const

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salesforcenotes/views/note_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/user_secure_storage.dart';

class NotesList extends StatefulWidget {
  final String objName;
  const NotesList({
    super.key,
    required this.objName,
  });

  @override
  State<NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  late final String _obj;
  // late final Future<Map<dynamic, dynamic>>_notesList;

  Future<String?> getDomain() async {
    final String? domain = await UserSecureStorage.getDomainName();
    return domain;
  }

  Future<String?> getToken() async {
    final String? token = await UserSecureStorage.getToken();
    return token;
  }

  Future<List<String>?> getSObjectsList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getStringList('key');
  }

  @override
  initState() {
    _obj = widget.objName;
    // _notesList = getNoteList();
    super.initState();
  }

  int responseLength = 0;
  // List<String> notesList = [];

  Future<Map> getNoteList() async {
    var params = {
      "q": "FIND {$_obj*} IN ALL FIELDS RETURNING $_obj"
          "__c(Name, Text__c, Id)",
    };

    final dataEndpoint = Uri(
      scheme: 'https',
      host: await getDomain(),
      path: '/services/data/v56.0/search/',
      queryParameters: params,
    );

    String? accessToken = await getToken();

    final response = await http.get(
      dataEndpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    Map responseDecoded = jsonDecode(response.body);
    responseLength = responseDecoded['searchRecords'].length;
    return responseDecoded;
  }

  Future<void> refreshList() async {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => NotesList(objName: _obj),
        // pageBuilder: (_, __, ___) => const NotesList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note List'),
        actions: [
          IconButton(
            onPressed: () => {},
            // icon: Flexible(child: Lottie.asset('')),
            icon: const Icon(Icons.list),
          )
        ],
      ),
      body: FutureBuilder(
        future: getNoteList(),
        builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: SizedBox(
                height: 80.0,
                width: 80.0,
                child: CircularProgressIndicator(
                  strokeWidth: 20.00,
                  backgroundColor: Color.fromARGB(199, 74, 200, 211),
                ),
              ),
            );
          } else if (snapshot.data!["searchRecords"].length == 0){
            return Column(
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 58.0),
                  child: Center(child: Text('No records found')),
                ),
              ],
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: responseLength,
              itemBuilder: (BuildContext context, int index) {
                if(snapshot.data != null){
                  return InkWell(
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(
                            noteId: snapshot.data?["searchRecords"][index]['Id'],
                            noteText: snapshot.data?['searchRecords'][index]['Text__c'],
                          ),
                        )
                      )
                    },
                    child: Container(
                      height: 50,
                      // color: Colors.amber.shade100,
                      color: Colors.amber[(index + 1) * 100],
                      child: Center(
                        // child: Text(index.toString()),
                        child: Text(
                            snapshot.data!['searchRecords'][index]['Text__c']),
                      ),
                    ),
                  );
                }else{
                  return Column(
                    children: const [
                      Center(child: Text('No records found')),
                    ],
                  );
                }
              }
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshList,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
