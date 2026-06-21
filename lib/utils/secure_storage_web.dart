import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageWeb {
  static const _secureStorage = FlutterSecureStorage();
  
  // Sal estática combinada con el valor para cifrado
  static const String _salt = "PedidosAppWebSalt2026_@UniversityEvent";

  static String _encrypt(String input) {
    final List<int> bytes = utf8.encode(input);
    final List<int> result = [];
    for (int i = 0; i < bytes.length; i++) {
      int saltChar = _salt.codeUnitAt(i % _salt.length);
      result.add(bytes[i] ^ saltChar);
    }
    return base64.encode(result);
  }

  static String _decrypt(String input) {
    try {
      final List<int> bytes = base64.decode(input);
      final List<int> result = [];
      for (int i = 0; i < bytes.length; i++) {
        int saltChar = _salt.codeUnitAt(i % _salt.length);
        result.add(bytes[i] ^ saltChar);
      }
      return utf8.decode(result);
    } catch (e) {
      return '';
    }
  }

  Future<String?> read({required String key}) async {
    try {
      final rawValue = await _secureStorage.read(key: key);
      if (rawValue == null) return null;
      if (kIsWeb) {
        return _decrypt(rawValue);
      }
      return rawValue;
    } catch (e) {
      debugPrint("[SecureStorageWeb] read error for key $key: $e");
      return null;
    }
  }

  Future<void> write({required String key, required String value}) async {
    try {
      if (kIsWeb) {
        final encryptedValue = _encrypt(value);
        await _secureStorage.write(key: key, value: encryptedValue);
      } else {
        await _secureStorage.write(key: key, value: value);
      }
    } catch (e) {
      debugPrint("[SecureStorageWeb] write error for key $key: $e");
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint("[SecureStorageWeb] delete error for key $key: $e");
    }
  }

  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint("[SecureStorageWeb] deleteAll error: $e");
    }
  }
}
