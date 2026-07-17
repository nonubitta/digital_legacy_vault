import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccessCodeHelper {
  static final AccessCodeHelper _instance = AccessCodeHelper._internal();
  factory AccessCodeHelper() => _instance;
  AccessCodeHelper._internal();

  static const String _accessCodeKey = 'vault_access_code';
  static const String _securityQuestionsKey = 'vault_security_questions';
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

  Future<bool> hasSecurityQuestions() async {
    final items = await getSecurityQuestions();
    if (items.length != 5) return false;
    return items.every(
      (item) =>
          (item['question'] ?? '').trim().isNotEmpty &&
          (item['answer'] ?? '').trim().isNotEmpty,
    );
  }

  Future<List<Map<String, String>>> getSecurityQuestions() async {
    final raw = await _secureStorage.read(key: _securityQuestionsKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) {
            final question = (item['question'] ?? '').toString();
            final answer = (item['answer'] ?? '').toString();
            return {'question': question, 'answer': answer};
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSecurityQuestions(List<Map<String, String>> items) async {
    final normalized = items
        .map(
          (item) => {
            'question': (item['question'] ?? '').trim(),
            'answer': (item['answer'] ?? '').trim(),
          },
        )
        .toList();

    await _secureStorage.write(
      key: _securityQuestionsKey,
      value: jsonEncode(normalized),
    );
  }
}