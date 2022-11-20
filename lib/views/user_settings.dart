import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:salesforcenotes/utils/user_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {

  final title = 'Salesforce Notes Settings';
  
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late final TextEditingController _key;
  late final TextEditingController _secret;
  late final TextEditingController _domain;

  // final _storage = const FlutterSecureStorage();

  // final String _userKey = 'userKey';
  // final String _userSecret = 'userSecret';
  // final String _domainName = 'domainName';

  // Future setUserKey(String data) async {
  //   await _storage.write(key: _userKey, value: data);
  // }

  // Future setUserSecret(String data) async {
  //   await _storage.write(key: _userSecret, value: data);
  // }

  // Future setUserKeySecret(String key, String secret) async {
  //   await setUserKey(key);
  //   await setUserSecret(secret);
  // }

  // Future<String?> getUserKey() async {
  //   return await _storage.read(key: _userKey);
  // }

  // Future<String?> getUserSecret() async {
  //   return await _storage.read(key: _userSecret);
  // }

  @override
  void initState() {
    _key = TextEditingController();
    _secret = TextEditingController();
    _domain = TextEditingController();
    super.initState();
    init();
  }

  Future init() async {
    final consumerKey = await UserSecureStorage.getConsumerKey() ?? '';
    final consumerSecret = await UserSecureStorage.getConsumerSecret() ?? '';
    final domainName = await UserSecureStorage.getDomainName() ?? '';

    setState(() {
      this._key.text = consumerKey;
      this._secret.text = consumerSecret;
      this._domain.text = domainName;
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _secret.dispose();
    _domain.dispose();
    super.dispose();
  }

  Future<List<String>> setSObjectsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print('prefs ...');
    final metadataEndpoint = Uri(
        scheme: 'https',
        host: await UserSecureStorage.getDomainName() ?? '',
        path: "/services/data/v56.0/tooling/query/",
        query: 'q=SELECT+DeveloperName+FROM+CustomObject',
      );
    String? accessToken = await UserSecureStorage.getToken();
    final response = await http.get(
      metadataEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    // print(metadataEndpoint);
    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');
    // print(response.body.runtimeType);

    Map<String, dynamic> sobjects = jsonDecode(response.body);
    List<dynamic> records = sobjects['records'];
    List<String> objectsNames = [];
    for(dynamic object in records){
      print(object['DeveloperName']);
      objectsNames.add(object['DeveloperName']);
    }
    print('names list >  ${objectsNames}');
    await prefs.setStringList('key', objectsNames);

    
    print(prefs.getStringList('key'));

    return objectsNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.text,
              autocorrect: false,
              controller: _key,
              decoration: const InputDecoration(hintText: 'Connected App Key'),
            ),
            TextField(
              autocorrect: false,
              controller: _secret,
              decoration: const InputDecoration(hintText: 'Connected App Secret'),
            ),
            TextField(
              autocorrect: false,
              controller: _domain,
              decoration: const InputDecoration(hintText: 'Connected Org Domain Name'),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.all(10.0),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  //get consumer key and secret.
                  final key = _key.text;
                  final secret = _secret.text;
                  final domain = _domain.text;
                  UserSecureStorage.setAppData(key, secret, domain);
                },
                child: const Text('Set Consumer key and secret'),
              ),
            ),
             Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.all(10.0),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  setSObjectsList();
                },
                child: const Text('Refresh SObjects List'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}