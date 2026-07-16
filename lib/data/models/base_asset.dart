import 'package:uuid/uuid.dart';

abstract class BaseAsset {
  final String id;
  final String category;
  final String name;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseAsset({
    String? id,
    required this.category,
    required this.name,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap();
  
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
