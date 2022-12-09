import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _domainName = 'domain-name';
  static const _consumerKey = 'consumer-key';
  static const _consumerSecret = 'consumer-secret';
  static const _token = 'token';

  static Future setDomainName(String domainName) async => {
      await _storage.delete(key: domainName),
      await _storage.write(key: _domainName, value: domainName),
  };

  static Future<String?> getDomainName() async =>
      await _storage.read(key: _domainName);

  static Future setConsumerKey(String consumerKey) async => {
      await _storage.delete(key: _consumerKey),
      await _storage.write(key: _consumerKey, value: consumerKey),
  };

  static Future<String?> getConsumerKey() async =>
      await _storage.read(key: _consumerKey);

  static Future setConsumerSecret(String consumerSecret) async => {
      await _storage.delete(key: _consumerSecret),
      await _storage.write(key: _consumerSecret, value: consumerSecret),
  };

  static Future<String?> getConsumerSecret() async =>
      await _storage.read(key: _consumerSecret);

  static Future setToken(String token) async => {
      await _storage.delete(key: _token),
      await _storage.write(key: _token, value: token),
  };

  static Future<String?> getToken() async =>
      await _storage.read(key: _token);

  static Future setAppData(String key, String secret, String domain) async {
    await setConsumerKey(key);
    await setConsumerSecret(secret);
    await setDomainName(domain);
  }
}