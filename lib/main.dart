import 'dart:async';
import 'dart:convert';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:salesforcenotes/utils/user_secure_storage.dart';
import 'package:salesforcenotes/views/create_new_note.dart';
import 'package:salesforcenotes/views/user_settings.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final title = 'Salesforce Notes';
  late final TextEditingController _username;
  late final TextEditingController _password;

  @override
  void initState() {
    _username = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  // ignore: non_constant_identifier_names
  Future<String> Login(String username, String password) async {
    String? domainName = await UserSecureStorage.getDomainName();
    String? identifier = await UserSecureStorage.getConsumerKey();
    String? secret = await UserSecureStorage.getConsumerSecret();

    final authorizationEndpoint =
        Uri.parse('https://login.salesforce.com/services/oauth2/token');
    var client = await oauth2.resourceOwnerPasswordGrant(
      authorizationEndpoint,
      username,
      password,
      identifier: identifier,
      secret: secret,
      basicAuth: false,
    );

    Map<String, dynamic> credentials = jsonDecode(client.credentials.toJson());

    // final dataEndpoint = Uri(
    //     scheme: 'https',
    //     host: domainName,
    //     path: 'services/data/v56.0/sobjects/MyNote__c');
    // String accessToken = credentials['accessToken'];
    // final response = await http.post(
    //   dataEndpoint,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $accessToken',
    //   },
    //   body: '{"text__c": "from Flutter 2--33--45"}',
    //   // body: jsonEncode(<String, String>{
    //   //   'text__c': 'from Flutter 2--33--45',
    //   // }
    //   // ),
    // );
    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');
    return credentials['accessToken'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Go to the settings page',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: ((context) => const UserSettings())));
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              controller: _username,
              decoration: const InputDecoration(hintText: 'Username'),
            ),
            TextField(
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              controller: _password,
              decoration: const InputDecoration(hintText: 'Password'),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.all(16.0),
                  textStyle: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  //get consumer key and
                  final username = _username.text;
                  final password = _password.text;
                  final token = await Login(username, password);
                  final oldToken = await UserSecureStorage.getToken();
                  final bool isNewToken = (token != oldToken);
                  if (isNewToken) {
                    UserSecureStorage.setToken(token);
                  } else {
                    print('same token');
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewNote(path: '',)),
                  );
                },
                child: const Text('Login'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           // horizontal).
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
