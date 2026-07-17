import 'base_asset.dart';

class Property extends BaseAsset {
  final String propertyType; // House, Apartment, Land, Commercial, etc.
  final String address;
  final String currencyCode;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final double? currentValue;
  final String? deedLocation;
  final String? mortgageProvider;
  final String? mortgageAccountNumber;
  final double? mortgageBalance;
  final String? propertyTaxInfo;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;

  Property({
    super.id,
    required super.name,
    super.notes,
    super.createdAt,
    super.updatedAt,
    required this.propertyType,
    required this.address,
    this.currencyCode = 'USD',
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.purchasePrice,
    this.purchaseDate,
    this.currentValue,
    this.deedLocation,
    this.mortgageProvider,
    this.mortgageAccountNumber,
    this.mortgageBalance,
    this.propertyTaxInfo,
    this.insuranceProvider,
    this.insurancePolicyNumber,
  }) : super(category: 'Real Estate');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'propertyType': propertyType,
      'address': address,
      'currencyCode': currencyCode,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'currentValue': currentValue,
      'deedLocation': deedLocation,
      'mortgageProvider': mortgageProvider,
      'mortgageAccountNumber': mortgageAccountNumber,
      'mortgageBalance': mortgageBalance,
      'propertyTaxInfo': propertyTaxInfo,
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'],
      name: map['name'],
      notes: map['notes'],
      createdAt: BaseAsset.parseDate(map['createdAt']),
      updatedAt: BaseAsset.parseDate(map['updatedAt']),
      propertyType: map['propertyType'],
      address: map['address'],
      currencyCode: map['currencyCode'] ?? 'USD',
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      country: map['country'],
      purchasePrice: map['purchasePrice'] != null ? double.tryParse(map['purchasePrice'].toString()) : null,
      purchaseDate: BaseAsset.parseDate(map['purchaseDate']),
      currentValue: map['currentValue'] != null ? double.tryParse(map['currentValue'].toString()) : null,
      deedLocation: map['deedLocation'],
      mortgageProvider: map['mortgageProvider'],
      mortgageAccountNumber: map['mortgageAccountNumber'],
      mortgageBalance: map['mortgageBalance'] != null ? double.tryParse(map['mortgageBalance'].toString()) : null,
      propertyTaxInfo: map['propertyTaxInfo'],
      insuranceProvider: map['insuranceProvider'],
      insurancePolicyNumber: map['insurancePolicyNumber'],
    );
  }
}
