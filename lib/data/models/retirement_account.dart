import 'base_asset.dart';

class RetirementAccount extends BaseAsset {
  final String accountType; // 401k, Roth IRA, Traditional IRA, etc.
  final String provider;
  final String accountNumber;
  final String currencyCode;
  final double? currentBalance;
  final String? employerName;
  final String? onlineAccessUrl;
  final String? username;
  final String? passwordHint;
  final String? beneficiaries;
  final DateTime? vestingDate;
  final double? employerMatch;

  RetirementAccount({
    super.id,
    required super.name,
    super.notes,
    super.createdAt,
    super.updatedAt,
    required this.accountType,
    required this.provider,
    required this.accountNumber,
    this.currencyCode = 'USD',
    this.currentBalance,
    this.employerName,
    this.onlineAccessUrl,
    this.username,
    this.passwordHint,
    this.beneficiaries,
    this.vestingDate,
    this.employerMatch,
  }) : super(category: 'Retirement');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'accountType': accountType,
      'provider': provider,
      'accountNumber': accountNumber,
      'currencyCode': currencyCode,
      'currentBalance': currentBalance,
      'employerName': employerName,
      'onlineAccessUrl': onlineAccessUrl,
      'username': username,
      'passwordHint': passwordHint,
      'beneficiaries': beneficiaries,
      'vestingDate': vestingDate?.toIso8601String(),
      'employerMatch': employerMatch,
    };
  }

  factory RetirementAccount.fromMap(Map<String, dynamic> map) {
    return RetirementAccount(
      id: map['id'],
      name: map['name'],
      notes: map['notes'],
      createdAt: BaseAsset.parseDate(map['createdAt']),
      updatedAt: BaseAsset.parseDate(map['updatedAt']),
      accountType: map['accountType'],
      provider: map['provider'],
      accountNumber: map['accountNumber'],
      currencyCode: map['currencyCode'] ?? 'USD',
      currentBalance: map['currentBalance'] != null ? double.tryParse(map['currentBalance'].toString()) : null,
      employerName: map['employerName'],
      onlineAccessUrl: map['onlineAccessUrl'],
      username: map['username'],
      passwordHint: map['passwordHint'],
      beneficiaries: map['beneficiaries'],
      vestingDate: BaseAsset.parseDate(map['vestingDate']),
      employerMatch: map['employerMatch'] != null ? double.tryParse(map['employerMatch'].toString()) : null,
    );
  }
}
