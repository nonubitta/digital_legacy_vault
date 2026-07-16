import 'base_asset.dart';

class Investment extends BaseAsset {
  final String investmentType; // Stocks, Bonds, Mutual Funds, etc.
  final String provider; // Vanguard, Fidelity, etc.
  final String accountNumber;
  final String currencyCode;
  final double? currentValue;
  final int? numberOfShares;
  final String? tickerSymbol;
  final String? onlineAccessUrl;
  final String? username;
  final String? passwordHint;
  final String? beneficiaries;
  final DateTime? purchaseDate;
  final double? purchasePrice;

  Investment({
    super.id,
    required super.name,
    super.notes,
    super.createdAt,
    super.updatedAt,
    required this.investmentType,
    required this.provider,
    required this.accountNumber,
    this.currencyCode = 'USD',
    this.currentValue,
    this.numberOfShares,
    this.tickerSymbol,
    this.onlineAccessUrl,
    this.username,
    this.passwordHint,
    this.beneficiaries,
    this.purchaseDate,
    this.purchasePrice,
  }) : super(category: 'Investments');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'investmentType': investmentType,
      'provider': provider,
      'accountNumber': accountNumber,
      'currencyCode': currencyCode,
      'currentValue': currentValue,
      'numberOfShares': numberOfShares,
      'tickerSymbol': tickerSymbol,
      'onlineAccessUrl': onlineAccessUrl,
      'username': username,
      'passwordHint': passwordHint,
      'beneficiaries': beneficiaries,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      name: map['name'],
      notes: map['notes'],
      createdAt: BaseAsset.parseDate(map['createdAt']),
      updatedAt: BaseAsset.parseDate(map['updatedAt']),
      investmentType: map['investmentType'],
      provider: map['provider'],
      accountNumber: map['accountNumber'],
      currencyCode: map['currencyCode'] ?? 'USD',
      currentValue: map['currentValue'] != null ? double.tryParse(map['currentValue'].toString()) : null,
      numberOfShares: map['numberOfShares'],
      tickerSymbol: map['tickerSymbol'],
      onlineAccessUrl: map['onlineAccessUrl'],
      username: map['username'],
      passwordHint: map['passwordHint'],
      beneficiaries: map['beneficiaries'],
      purchaseDate: BaseAsset.parseDate(map['purchaseDate']),
      purchasePrice: map['purchasePrice'] != null ? double.tryParse(map['purchasePrice'].toString()) : null,
    );
  }
}
