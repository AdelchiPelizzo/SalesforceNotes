import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSecureStorage {
  static const _storage = FlutterSecureStorage();

  // static const _keyUsername = 'username';
  // static const _keyPets = 'pets';
  // static const _keyBirthday = 'birthday';

  static const _domainName = 'domain-name';
  static const _consumerKey = 'consumer-key';
  static const _consumerSecret = 'consumer-secret';
  static const _token = 'token';

  static Future setDomainName(String domainName) async =>
      await _storage.write(key: _domainName, value: domainName);

  static Future<String?> getDomainName() async =>
      await _storage.read(key: _domainName);

  static Future setConsumerKey(String consumerKey) async =>
      await _storage.write(key: _consumerKey, value: consumerKey);

  static Future<String?> getConsumerKey() async =>
      await _storage.read(key: _consumerKey);

  static Future setConsumerSecret(String consumerSecret) async =>
      await _storage.write(key: _consumerSecret, value: consumerSecret);

  static Future<String?> getConsumerSecret() async =>
      await _storage.read(key: _consumerSecret);

  static Future setToken(String token) async =>
      await _storage.write(key: _token, value: token);

  static Future<String?> getToken() async =>
      await _storage.read(key: _token);

  static Future setAppData(String key, String secret, String domain) async {
    print(key);
    print(secret);
    print(domain);
    await setConsumerKey(key);
    await setConsumerSecret(secret);
    await setDomainName(domain);
  }




  // static Future setUsername(String username) async =>
  //     await _storage.write(key: _keyUsername, value: username);

  // static Future<String?> getUsername() async =>
  //     await _storage.read(key: _keyUsername);

  // static Future setPets(List<String> pets) async {
  //   final value = json.encode(pets);

  //   await _storage.write(key: _keyPets, value: value);
  // }

  // static Future<List<String>?> getPets() async {
  //   final value = await _storage.read(key: _keyPets);

  //   return value == null ? null : List<String>.from(json.decode(value));
  // }

  // static Future setBirthday(DateTime dateOfBirth) async {
  //   final birthday = dateOfBirth.toIso8601String();

  //   await _storage.write(key: _keyBirthday, value: birthday);
  // }

  // static Future<DateTime?> getBirthday() async {
  //   final birthday = await _storage.read(key: _keyBirthday);

  //   return birthday == null ? null : DateTime.tryParse(birthday);
  // }
}