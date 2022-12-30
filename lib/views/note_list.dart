import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/user_secure_storage.dart';

class NoteList extends StatefulWidget {
  const NoteList({super.key});

  @override
  State<NoteList> createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
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
    Future.delayed(Duration.zero,() async {
        notesList = await getNoteList();
    });
    super.initState();
  }

  List<String> notesList = [];

  Future<List<String>> getNoteList() async {
    const params = {
        "q": "FIND {Update*} IN ALL FIELDS RETURNING Update__c(Name, Text__c, Id)",
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
    for (int i = 0; i < responseDecoded['searchRecords'].length; i++) {
        String idList = responseDecoded["searchRecords"][i]['Text__c'];
        notesList.add(idList);
    }
    return notesList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note List'),
        actions: [
          IconButton(
            onPressed: () => {},
            icon: const Icon(Icons.list),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: notesList.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              height: 50,
              color: Colors.amber[(index+1)*100],
              child: Center(
                child: Text('Note ${index+1} : ${notesList[index]}'),
              ),
            );
          }
        ),
      ),
    );
  }
}