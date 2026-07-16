import 'package:uuid/uuid.dart';
import 'category_field.dart';

class Category {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final String? description;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Populated when queried with fields (not stored in this table).
  final List<CategoryField> fields;

  Category({
    String? id,
    required this.name,
    this.icon,
    this.color,
    this.description,
    this.isSystem = false,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.fields = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'description': description,
      'isSystem': isSystem ? 1 : 0,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map, {List<CategoryField> fields = const []}) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      description: map['description'] as String?,
      isSystem: (map['isSystem'] as int? ?? 0) == 1,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      fields: fields,
    );
  }

  Category copyWith({
    String? name,
    String? icon,
    String? color,
    String? description,
    bool? isSystem,
    int? sortOrder,
    List<CategoryField>? fields,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      fields: fields ?? this.fields,
    );
  }
}
