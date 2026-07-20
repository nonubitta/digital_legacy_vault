import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsHelper {
  static final AppSettingsHelper _instance = AppSettingsHelper._internal();
  factory AppSettingsHelper() => _instance;
  AppSettingsHelper._internal();

  static const String _vaultNameKey = 'vault_name';
  static const String _showHomeAmountsKey = 'show_home_amounts';
  static const String _disclaimerAcceptedKey = 'disclaimer_accepted';
  static const String _disabledSystemCategoriesKey =
      'disabled_system_categories';
  static const String defaultVaultName = 'Legacy Vault';
  static const String _securityLevelKey = 'security_level';
  static const String defaultSecurityLevel = 'MEDIUM';

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

  Future<bool> getShowHomeAmounts() async {
    final saved = await _secureStorage.read(key: _showHomeAmountsKey);
    if (saved == null || saved.trim().isEmpty) {
      return true;
    }
    return saved == 'true';
  }

  Future<void> saveShowHomeAmounts(bool value) async {
    await _secureStorage.write(
      key: _showHomeAmountsKey,
      value: value.toString(),
    );
  }

  Future<bool> hasAcceptedDisclaimer() async {
    final saved = await _secureStorage.read(key: _disclaimerAcceptedKey);
    return saved == 'true';
  }

  Future<void> saveDisclaimerAccepted(bool accepted) async {
    await _secureStorage.write(
      key: _disclaimerAcceptedKey,
      value: accepted.toString(),
    );
  }

  Future<Set<String>> getDisabledSystemCategoryNames() async {
    final saved = await _secureStorage.read(key: _disabledSystemCategoriesKey);
    if (saved == null || saved.trim().isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(saved);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded.map((entry) => entry.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveSystemCategoryEnabled(String categoryName, bool enabled) async {
    final disabled = await getDisabledSystemCategoryNames();
    if (enabled) {
      disabled.remove(categoryName);
    } else {
      disabled.add(categoryName);
    }

    if (disabled.isEmpty) {
      await _secureStorage.delete(key: _disabledSystemCategoriesKey);
      return;
    }

    await _secureStorage.write(
      key: _disabledSystemCategoriesKey,
      value: jsonEncode(disabled.toList()..sort()),
    );
  }

  Future<String> getSecurityLevel() async {
    final saved = await _secureStorage.read(key: _securityLevelKey);
    if (saved == null || saved.trim().isEmpty) {
      return defaultSecurityLevel;
    }
    return saved.trim();
  }

  Future<void> saveSecurityLevel(String level) async {
    final normalized = level.trim();
    if (normalized.isEmpty || normalized == defaultSecurityLevel) {
      await _secureStorage.delete(key: _securityLevelKey);
      return;
    }
    await _secureStorage.write(key: _securityLevelKey, value: normalized);
  }
}
