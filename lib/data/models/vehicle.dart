import 'base_asset.dart';

class Vehicle extends BaseAsset {
  final String vehicleType; // Car, Motorcycle, Boat, RV, etc.
  final String make;
  final String model;
  final int year;
  final String currencyCode;
  final String? vin;
  final String? licensePlate;
  final String? color;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final double? currentValue;
  final String? titleLocation;
  final String? registrationInfo;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? loanProvider;
  final String? loanAccountNumber;
  final double? loanBalance;

  Vehicle({
    super.id,
    required super.name,
    super.notes,
    super.createdAt,
    super.updatedAt,
    required this.vehicleType,
    required this.make,
    required this.model,
    required this.year,
    this.currencyCode = 'USD',
    this.vin,
    this.licensePlate,
    this.color,
    this.purchasePrice,
    this.purchaseDate,
    this.currentValue,
    this.titleLocation,
    this.registrationInfo,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.loanProvider,
    this.loanAccountNumber,
    this.loanBalance,
  }) : super(category: 'Vehicles');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'vehicleType': vehicleType,
      'make': make,
      'model': model,
      'year': year,
      'currencyCode': currencyCode,
      'vin': vin,
      'licensePlate': licensePlate,
      'color': color,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'currentValue': currentValue,
      'titleLocation': titleLocation,
      'registrationInfo': registrationInfo,
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
      'loanProvider': loanProvider,
      'loanAccountNumber': loanAccountNumber,
      'loanBalance': loanBalance,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      name: map['name'],
      notes: map['notes'],
      createdAt: BaseAsset.parseDate(map['createdAt']),
      updatedAt: BaseAsset.parseDate(map['updatedAt']),
      vehicleType: map['vehicleType'],
      make: map['make'],
      model: map['model'],
      year: map['year'],
      currencyCode: map['currencyCode'] ?? 'USD',
      vin: map['vin'],
      licensePlate: map['licensePlate'],
      color: map['color'],
      purchasePrice: map['purchasePrice'] != null ? double.tryParse(map['purchasePrice'].toString()) : null,
      purchaseDate: BaseAsset.parseDate(map['purchaseDate']),
      currentValue: map['currentValue'] != null ? double.tryParse(map['currentValue'].toString()) : null,
      titleLocation: map['titleLocation'],
      registrationInfo: map['registrationInfo'],
      insuranceProvider: map['insuranceProvider'],
      insurancePolicyNumber: map['insurancePolicyNumber'],
      loanProvider: map['loanProvider'],
      loanAccountNumber: map['loanAccountNumber'],
      loanBalance: map['loanBalance'] != null ? double.tryParse(map['loanBalance'].toString()) : null,
    );
  }
}
