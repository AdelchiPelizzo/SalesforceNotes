import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ConsumerKeys {

    void readFileAsync(String path) {
    File file = File(path); // (1)
    Future<String> futureContent = file.readAsString();
    futureContent.then((c) => print(c)); // (3)
  }

  Future<void> Login(String username, String password) async {

  const storage = FlutterSecureStorage();
  await storage.write(key: 'token', value: 'token-value');
  await storage.write(key: 'username', value: 'username');
//eg: to get the value
  String token = (await storage.read(key: 'token')) ?? '';
  //or, using nullable var
  String? user = await storage.read(key: 'username');

  print('token');
  print('user');

    final authorizationEndpoint = Uri.parse('https://anylabeltest1-dev-ed.my.salesforce.com/services/oauth2/token');
    const identifier = '3MVG9sh10GGnD4Dsmq12_RAdeolG5JwpClBINZv1G.c_JMW0Cn6y4IUkl5E7DIYaoATcOQnmktQUwu5o.WWqK';
    const secret = '09B45C49B265235021AAD5941CC5EE8BE5DB04DAAFB1F3DB9A87DDD9CFC55EFC';

    var client = await oauth2.resourceOwnerPasswordGrant(
      authorizationEndpoint,
      username,
      password,
      identifier: identifier,
      secret: secret,
      basicAuth: false,
    );

    // await File('~/.forcenotes/credentials.json').writeAsString(client.credentials.toJson());
    // var credentials = client.credentials.toJson();
    Map<String, dynamic> credentials = jsonDecode(client.credentials.toJson());

    const dataEndPoint = 'https://anylabeltest1-dev-ed.my.salesforce.com/services/data/v56.0/sobjects/MyNote__c';

    await http.post(
      Uri.parse(dataEndPoint),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${credentials['accessToken']}',
      },
      body: jsonEncode(<String, String>{
        'text__c': 'from Flutter 2--',
      }),
    );
    print('token ... ${credentials['accessToken']}');
  }
}


// ignore: non_constant_identifier_names
