import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsHelper {
  static final AppSettingsHelper _instance = AppSettingsHelper._internal();
  factory AppSettingsHelper() => _instance;
  AppSettingsHelper._internal();

  static const String _vaultNameKey = 'vault_name';
  static const String defaultVaultName = 'Legacy Vault';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> getVaultName() async {
    final saved = await _secureStorage.read(key: _vaultNameKey);
    if (saved == null || saved.trim().isEmpty) {
      return defaultVaultName;
    }
    return saved.trim();
  }

  Future<void> saveVaultName(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized == defaultVaultName) {
      await _secureStorage.delete(key: _vaultNameKey);
      return;
    }
    await _secureStorage.write(key: _vaultNameKey, value: normalized);
  }
}
