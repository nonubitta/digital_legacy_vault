import 'package:uuid/uuid.dart';

/// The data type of a category field.
enum FieldType {
  text,
  number,
  date,
  url,
  boolean;

  static FieldType fromString(String value) {
    return FieldType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FieldType.text,
    );
  }
}

class CategoryField {
  final String id;
  final String categoryId;

  /// Machine-readable name used as the key in [Asset.fieldValues].
  final String name;

  /// Human-readable label shown in the UI.
  final String label;

  final FieldType fieldType;
  final bool isRequired;

  /// Whether the value should be encrypted at rest.
  final bool isSensitive;

  /// Marks the field whose numeric value is used for USD totals on the dashboard.
  final bool isValueField;

  final int sortOrder;
  final String? defaultValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryField({
    String? id,
    required this.categoryId,
    required this.name,
    required this.label,
    this.fieldType = FieldType.text,
    this.isRequired = false,
    this.isSensitive = false,
    this.isValueField = false,
    this.sortOrder = 0,
    this.defaultValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'label': label,
      'fieldType': fieldType.name,
      'isRequired': isRequired ? 1 : 0,
      'isSensitive': isSensitive ? 1 : 0,
      'isValueField': isValueField ? 1 : 0,
      'sortOrder': sortOrder,
      'defaultValue': defaultValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CategoryField.fromMap(Map<String, dynamic> map) {
    return CategoryField(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      label: map['label'] as String,
      fieldType: FieldType.fromString(map['fieldType'] as String? ?? 'text'),
      isRequired: (map['isRequired'] as int? ?? 0) == 1,
      isSensitive: (map['isSensitive'] as int? ?? 0) == 1,
      isValueField: (map['isValueField'] as int? ?? 0) == 1,
      sortOrder: map['sortOrder'] as int? ?? 0,
      defaultValue: map['defaultValue'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  CategoryField copyWith({
    String? name,
    String? label,
    FieldType? fieldType,
    bool? isRequired,
    bool? isSensitive,
    bool? isValueField,
    int? sortOrder,
    String? defaultValue,
  }) {
    return CategoryField(
      id: id,
      categoryId: categoryId,
      name: name ?? this.name,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      isRequired: isRequired ?? this.isRequired,
      isSensitive: isSensitive ?? this.isSensitive,
      isValueField: isValueField ?? this.isValueField,
      sortOrder: sortOrder ?? this.sortOrder,
      defaultValue: defaultValue ?? this.defaultValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
