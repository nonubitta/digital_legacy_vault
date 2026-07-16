import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccessCodeHelper {
  static final AccessCodeHelper _instance = AccessCodeHelper._internal();
  factory AccessCodeHelper() => _instance;
  AccessCodeHelper._internal();

  static const String _accessCodeKey = 'vault_access_code';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> hasAccessCode() async {
    final code = await _secureStorage.read(key: _accessCodeKey);
    return code != null && code.isNotEmpty;
  }

  Future<void> saveAccessCode(String code) async {
    await _secureStorage.write(key: _accessCodeKey, value: code);
  }

  Future<bool> verifyAccessCode(String code) async {
    final savedCode = await _secureStorage.read(key: _accessCodeKey);
    if (savedCode == null || savedCode.isEmpty) return false;
    return savedCode == code;
  }
}