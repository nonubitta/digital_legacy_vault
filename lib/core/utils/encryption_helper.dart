import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const String _keyName = 'vault_master_key';
  encrypt.Key? _encryptionKey;

  Future<void> initialize() async {
    String? keyString = await _secureStorage.read(key: _keyName);
    
    if (keyString == null) {
      // Generate new key
      _encryptionKey = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _keyName,
        value: base64.encode(_encryptionKey!.bytes),
      );
    } else {
      // Load existing key
      _encryptionKey = encrypt.Key(base64.decode(keyString));
    }
  }

  String encryptData(String plainText) {
    if (_encryptionKey == null) {
      throw Exception('Encryption key not initialized');
    }

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Combine IV and encrypted data
    final combined = base64.encode(iv.bytes) + ':' + encrypted.base64;
    return combined;
  }

  String decryptData(String encryptedText) {
    if (_encryptionKey == null) {
      throw Exception('Encryption key not initialized');
    }

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final iv = encrypt.IV(base64.decode(parts[0]));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  Future<void> resetEncryption() async {
    await _secureStorage.delete(key: _keyName);
    _encryptionKey = null;
  }
}
