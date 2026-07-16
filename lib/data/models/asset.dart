import 'package:uuid/uuid.dart';

/// A single user asset belonging to any dynamic category.
///
/// Core metadata is stored in the `assets` table.
/// The dynamic field values (keyed by [CategoryField.name]) are loaded from
/// `asset_field_values` and exposed via [fieldValues].
class Asset {
  final String id;
  final String categoryId;
  final String name;
  final String? notes;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Dynamic field values: fieldName → raw string value.
  ///
  /// Numeric, date, and boolean values are stored as their string
  /// representations and should be parsed using [CategoryField.fieldType].
  final Map<String, String?> fieldValues;

  Asset({
    String? id,
    required this.categoryId,
    required this.name,
    this.notes,
    this.currencyCode = 'USD',
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String?>? fieldValues,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        fieldValues = fieldValues ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'notes': notes,
      'currencyCode': currencyCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Asset.fromMap(
    Map<String, dynamic> map, {
    Map<String, String?> fieldValues = const {},
  }) {
    return Asset(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      fieldValues: Map<String, String?>.from(fieldValues),
    );
  }

  Asset copyWith({
    String? categoryId,
    String? name,
    String? notes,
    String? currencyCode,
    Map<String, String?>? fieldValues,
  }) {
    return Asset(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      fieldValues: fieldValues ?? Map<String, String?>.from(this.fieldValues),
    );
  }

  /// Returns the value of [fieldName] parsed as a [double], or null.
  double? numericValue(String fieldName) {
    final raw = fieldValues[fieldName];
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
  }
}
