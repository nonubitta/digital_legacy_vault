import 'base_asset.dart';

class BankAccount extends BaseAsset {
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String currencyCode;
  final String? routingNumber;
  final String? swiftCode;
  final String? onlineAccessUrl;
  final String? username;
  final String? passwordHint;
  final double? balance;
  final String? beneficiaries;

  BankAccount({
    super.id,
    required super.name,
    super.notes,
    super.createdAt,
    super.updatedAt,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    this.currencyCode = 'USD',
    this.routingNumber,
    this.swiftCode,
    this.onlineAccessUrl,
    this.username,
    this.passwordHint,
    this.balance,
    this.beneficiaries,
  }) : super(category: 'Banks');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bankName': bankName,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'currencyCode': currencyCode,
      'routingNumber': routingNumber,
      'swiftCode': swiftCode,
      'onlineAccessUrl': onlineAccessUrl,
      'username': username,
      'passwordHint': passwordHint,
      'balance': balance,
      'beneficiaries': beneficiaries,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'],
      name: map['name'],
      notes: map['notes'],
      createdAt: BaseAsset.parseDate(map['createdAt']),
      updatedAt: BaseAsset.parseDate(map['updatedAt']),
      bankName: map['bankName'],
      accountType: map['accountType'],
      accountNumber: map['accountNumber'],
      currencyCode: map['currencyCode'] ?? 'USD',
      routingNumber: map['routingNumber'],
      swiftCode: map['swiftCode'],
      onlineAccessUrl: map['onlineAccessUrl'],
      username: map['username'],
      passwordHint: map['passwordHint'],
      balance: map['balance'] != null ? double.tryParse(map['balance'].toString()) : null,
      beneficiaries: map['beneficiaries'],
    );
  }
}
