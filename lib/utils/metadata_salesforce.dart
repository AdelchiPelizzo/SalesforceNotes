import 'dart:convert';
import './user_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MetadataSalesforce {

  Future<String?> getDomain() async {
    final String? domain = await UserSecureStorage.getDomainName();
    return domain;
  }

  Future<String?> getToken() async {
    final String? token = await UserSecureStorage.getToken();
    return token;
  }

  Future<List<String>> getTableEnumOrId() async {
    final String? baseUrl = await getDomain();
    final uri = Uri.parse(
        "https://$baseUrl/services/data/v56.0/tooling/query/?q=Select+TableEnumOrId+from+customfield+Where+developername+=+'Text'");

    String? accessToken = await getToken();
    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    List<String> objectsId = [];
    Map responseDecoded = jsonDecode(response.body);
    for (int i = 0; i < responseDecoded['records'].length; i++) {
      String idList = responseDecoded["records"][i]['TableEnumOrId'];
      objectsId.add(idList);
    }

    return objectsId;
  }

  Future<List<String>> getObjectNames() async {
    final String? baseUrl = await getDomain();
    String? accessToken = await getToken();
    List<String> listOfId;
    int count = 0;
    Uri uri = Uri.parse('');
    http.Response response;
    Map responseDecoded;
    List<String> objectNamesList = [];
    String uriString = "https://$baseUrl/services/data/v56.0/tooling/query/?q=SELECT+DeveloperName+FROM+CustomObject+WHERE+Id+IN+(";
    getTableEnumOrId().then(
      (value) => {
      count += value.length,
      listOfId = value,
      for (String id in listOfId)
        {
          if (count > 1)
            {
              uriString += "'$id',",
              count--,
            }
          else if (count == 1)
            {
              uriString += "'$id')",
              count--,
            }
        },
      uri = Uri.parse(uriString),
      http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).then((value) => {
          response = value,
          responseDecoded = jsonDecode(response.body),
          for(int i = 0; i<responseDecoded['records'].length; i++){
            objectNamesList.add(responseDecoded["records"][i]['DeveloperName']),
          },
          print('<<<<'+objectNamesList.toString()),
        }),
      }
    );
    return objectNamesList;
  }
}
