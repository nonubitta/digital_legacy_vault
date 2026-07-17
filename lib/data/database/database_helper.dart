import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/category_field.dart';
import '../models/asset.dart';
import '../models/base_asset.dart';
import '../models/bank_account.dart';
import '../models/retirement_account.dart';
import '../models/investment.dart';
import '../models/property.dart';
import '../models/vehicle.dart';
import '../../core/utils/encryption_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _categoryRealEstate = 'Real Estate';
  static const _categoryPersonalProperty = 'Personal Property';

  static Database? _database;
  final _encryptionHelper = EncryptionHelper();
  static const _uuid = Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'legacy_vault.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Schema
  // ──────────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL UNIQUE,
        icon        TEXT,
        color       TEXT,
        description TEXT,
        isSystem    INTEGER NOT NULL DEFAULT 0,
        sortOrder   INTEGER NOT NULL DEFAULT 0,
        createdAt   TEXT NOT NULL,
        updatedAt   TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category_fields (
        id           TEXT PRIMARY KEY,
        categoryId   TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        name         TEXT NOT NULL,
        label        TEXT NOT NULL,
        fieldType    TEXT NOT NULL DEFAULT 'text',
        isRequired   INTEGER NOT NULL DEFAULT 0,
        isSensitive  INTEGER NOT NULL DEFAULT 0,
        isValueField INTEGER NOT NULL DEFAULT 0,
        sortOrder    INTEGER NOT NULL DEFAULT 0,
        defaultValue TEXT,
        createdAt    TEXT NOT NULL,
        updatedAt    TEXT NOT NULL,
        UNIQUE(categoryId, name)
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id           TEXT PRIMARY KEY,
        categoryId   TEXT NOT NULL REFERENCES categories(id),
        name         TEXT NOT NULL,
        notes        TEXT,
        currencyCode TEXT NOT NULL DEFAULT 'USD',
        createdAt    TEXT NOT NULL,
        updatedAt    TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_field_values (
        id        TEXT PRIMARY KEY,
        assetId   TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
        fieldId   TEXT NOT NULL REFERENCES category_fields(id),
        value     TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(assetId, fieldId)
      )
    ''');

    await db.execute('''
      CREATE TABLE currencies (
        code      TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        rateToUsd REAL NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await _seedDefaultData(db);
  }

  /// App is new and not distributed — drop everything and recreate.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    for (final t in [
      'asset_field_values', 'assets', 'category_fields', 'categories', 'currencies',
      'banks', 'retirement', 'investments', 'properties', 'vehicles',
    ]) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
    await db.execute('PRAGMA foreign_keys = ON');
    await _onCreate(db, newVersion);
  }

  // ──────────────────────────────────────────────────────────────
  // Seed
  // ──────────────────────────────────────────────────────────────

  Future<void> _seedDefaultData(Database db) async {
    await _seedDefaultCurrency(db);
    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCurrency(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('currencies', {
      'code': 'USD', 'name': 'US Dollar', 'rateToUsd': 1.0,
      'createdAt': now, 'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    final specs = <(String, String, String, int, List<_FieldSpec>)>[
      ('Banks', 'account_balance', '#1565C0', 0, [
        _FieldSpec('bankName', 'Bank Name', isRequired: true),
        _FieldSpec('accountType', 'Account Type', isRequired: true),
        _FieldSpec('accountNumber', 'Account Number', isRequired: true, isSensitive: true),
        _FieldSpec('routingNumber', 'Routing Number', isSensitive: true),
        _FieldSpec('swiftCode', 'SWIFT / BIC Code'),
        _FieldSpec('onlineAccessUrl', 'Online Access URL', fieldType: 'url'),
        _FieldSpec('username', 'Username', isSensitive: true),
        _FieldSpec('passwordHint', 'Password Hint', isSensitive: true),
        _FieldSpec('balance', 'Balance', fieldType: 'number', isValueField: true),
        _FieldSpec('beneficiaries', 'Beneficiaries'),
      ]),
      ('Retirement', 'savings', '#2E7D32', 1, [
        _FieldSpec('accountType', 'Account Type', isRequired: true),
        _FieldSpec('provider', 'Provider', isRequired: true),
        _FieldSpec('accountNumber', 'Account Number', isRequired: true, isSensitive: true),
        _FieldSpec('currentBalance', 'Current Balance', fieldType: 'number', isValueField: true),
        _FieldSpec('employerName', 'Employer Name'),
        _FieldSpec('onlineAccessUrl', 'Online Access URL', fieldType: 'url'),
        _FieldSpec('username', 'Username', isSensitive: true),
        _FieldSpec('passwordHint', 'Password Hint', isSensitive: true),
        _FieldSpec('beneficiaries', 'Beneficiaries'),
        _FieldSpec('vestingDate', 'Vesting Date', fieldType: 'date'),
        _FieldSpec('employerMatch', 'Employer Match %', fieldType: 'number'),
      ]),
      ('Investments', 'trending_up', '#E65100', 2, [
        _FieldSpec('investmentType', 'Investment Type', isRequired: true),
        _FieldSpec('provider', 'Provider', isRequired: true),
        _FieldSpec('accountNumber', 'Account Number', isRequired: true, isSensitive: true),
        _FieldSpec('currentValue', 'Current Value', fieldType: 'number', isValueField: true),
        _FieldSpec('numberOfShares', 'Number of Shares', fieldType: 'number'),
        _FieldSpec('tickerSymbol', 'Ticker Symbol'),
        _FieldSpec('onlineAccessUrl', 'Online Access URL', fieldType: 'url'),
        _FieldSpec('username', 'Username', isSensitive: true),
        _FieldSpec('passwordHint', 'Password Hint', isSensitive: true),
        _FieldSpec('beneficiaries', 'Beneficiaries'),
        _FieldSpec('purchaseDate', 'Purchase Date', fieldType: 'date'),
        _FieldSpec('purchasePrice', 'Purchase Price', fieldType: 'number'),
      ]),
      (_categoryRealEstate, 'home', '#6A1B9A', 3, [
        _FieldSpec('propertyType', 'Property Type', isRequired: true),
        _FieldSpec('address', 'Address', isRequired: true),
        _FieldSpec('city', 'City'),
        _FieldSpec('state', 'State / Province'),
        _FieldSpec('zipCode', 'ZIP / Postal Code'),
        _FieldSpec('country', 'Country'),
        _FieldSpec('purchasePrice', 'Purchase Price', fieldType: 'number'),
        _FieldSpec('purchaseDate', 'Purchase Date', fieldType: 'date'),
        _FieldSpec('currentValue', 'Current Value', fieldType: 'number', isValueField: true),
        _FieldSpec('deedLocation', 'Deed Location'),
        _FieldSpec('mortgageProvider', 'Mortgage Provider'),
        _FieldSpec('mortgageAccountNumber', 'Mortgage Account Number', isSensitive: true),
        _FieldSpec('mortgageBalance', 'Mortgage Balance', fieldType: 'number'),
        _FieldSpec('propertyTaxInfo', 'Property Tax Info'),
        _FieldSpec('insuranceProvider', 'Insurance Provider'),
        _FieldSpec('insurancePolicyNumber', 'Insurance Policy Number', isSensitive: true),
      ]),
      (_categoryPersonalProperty, 'directions_car', '#00838F', 4, [
        _FieldSpec('vehicleType', 'Property Type', isRequired: true),
        _FieldSpec('make', 'Make', isRequired: true),
        _FieldSpec('model', 'Model', isRequired: true),
        _FieldSpec('year', 'Year', fieldType: 'number', isRequired: true),
        _FieldSpec('vin', 'VIN', isSensitive: true),
        _FieldSpec('licensePlate', 'License Plate'),
        _FieldSpec('color', 'Color'),
        _FieldSpec('purchasePrice', 'Purchase Price', fieldType: 'number'),
        _FieldSpec('purchaseDate', 'Purchase Date', fieldType: 'date'),
        _FieldSpec('currentValue', 'Current Value', fieldType: 'number', isValueField: true),
        _FieldSpec('titleLocation', 'Title Location'),
        _FieldSpec('registrationInfo', 'Registration Info'),
        _FieldSpec('insuranceProvider', 'Insurance Provider'),
        _FieldSpec('insurancePolicyNumber', 'Insurance Policy Number', isSensitive: true),
        _FieldSpec('loanProvider', 'Loan Provider'),
        _FieldSpec('loanAccountNumber', 'Loan Account Number', isSensitive: true),
        _FieldSpec('loanBalance', 'Loan Balance', fieldType: 'number'),
      ]),
      ('Insurances', 'badge', '#5E35B1', 5, [
        _FieldSpec('policyType', 'Policy Type', isRequired: true),
        _FieldSpec('provider', 'Provider', isRequired: true),
        _FieldSpec('policyNumber', 'Policy Number', isSensitive: true),
        _FieldSpec('insuredItem', 'Insured Item / Person'),
        _FieldSpec('coverageAmount', 'Coverage Amount', fieldType: 'number', isValueField: true),
        _FieldSpec('premiumAmount', 'Premium Amount', fieldType: 'number'),
        _FieldSpec('renewalDate', 'Renewal Date', fieldType: 'date'),
        _FieldSpec('beneficiary', 'Beneficiary'),
      ]),
      ('Businesses & Income', 'trending_up', '#2E7D32', 6, [
        _FieldSpec('incomeType', 'Income Type', isRequired: true),
        _FieldSpec('sourceName', 'Source Name', isRequired: true),
        _FieldSpec('ownershipPercent', 'Ownership %', fieldType: 'number'),
        _FieldSpec('monthlyIncome', 'Monthly Income', fieldType: 'number'),
        _FieldSpec('annualIncome', 'Annual Income', fieldType: 'number', isValueField: true),
        _FieldSpec('accountNumber', 'Account / Tax ID', isSensitive: true),
        _FieldSpec('contactName', 'Contact Name'),
        _FieldSpec('contactPhone', 'Contact Phone'),
      ]),
      ('Debt', 'credit_card', '#C62828', 7, [
        _FieldSpec('debtType', 'Debt Type', isRequired: true),
        _FieldSpec('lender', 'Lender', isRequired: true),
        _FieldSpec('accountNumber', 'Account Number', isSensitive: true),
        _FieldSpec('currentBalance', 'Current Balance', fieldType: 'number', isValueField: true),
        _FieldSpec('interestRate', 'Interest Rate %', fieldType: 'number'),
        _FieldSpec('minimumPayment', 'Minimum Payment', fieldType: 'number'),
        _FieldSpec('dueDate', 'Due Date', fieldType: 'date'),
        _FieldSpec('securedBy', 'Secured By'),
      ]),
    ];

    for (final (name, icon, color, sort, fields) in specs) {
      final catId = _uuid.v4();
      await db.insert('categories', {
        'id': catId, 'name': name, 'icon': icon, 'color': color,
        'isSystem': 1, 'sortOrder': sort, 'createdAt': now, 'updatedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      for (var i = 0; i < fields.length; i++) {
        final f = fields[i];
        await db.insert('category_fields', {
          'id': _uuid.v4(), 'categoryId': catId,
          'name': f.name, 'label': f.label, 'fieldType': f.fieldType,
          'isRequired': f.isRequired ? 1 : 0,
          'isSensitive': f.isSensitive ? 1 : 0,
          'isValueField': f.isValueField ? 1 : 0,
          'sortOrder': i, 'defaultValue': null,
          'createdAt': now, 'updatedAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Encryption helpers
  // ──────────────────────────────────────────────────────────────

  String? _encrypt(String? value) {
    if (value == null || value.isEmpty) return value;
    return _encryptionHelper.encryptData(value);
  }

  String? _decrypt(String? value) {
    if (value == null || value.isEmpty) return value;
    try {
      return _encryptionHelper.decryptData(value);
    } catch (_) {
      return value;
    }
  }

  Future<Category> _requiredCategory(String name) async {
    final category = await getCategoryByName(name, withFields: true);
    if (category == null) {
      throw StateError('Missing seeded category: $name');
    }
    return category;
  }

  Map<String, String?> _fieldValuesFromMap(
    Map<String, dynamic> map,
    List<CategoryField> fields,
  ) {
    return {
      for (final field in fields)
        if (map.containsKey(field.name)) field.name: map[field.name]?.toString(),
    };
  }

  Map<String, dynamic> _mapFromAsset(Asset asset) {
    return {
      'id': asset.id,
      'name': asset.name,
      'notes': asset.notes,
      'createdAt': asset.createdAt,
      'updatedAt': asset.updatedAt,
      'currencyCode': asset.currencyCode,
      ...asset.fieldValues,
    };
  }

  Future<Asset> _assetFromLegacyMap({
    required String categoryName,
    required Map<String, dynamic> map,
    Map<String, String?>? fieldValues,
  }) async {
    final category = await _requiredCategory(categoryName);
    return Asset(
      id: map['id'] as String?,
      categoryId: category.id,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      createdAt: BaseAsset.parseDate(map['createdAt']),
      updatedAt: BaseAsset.parseDate(map['updatedAt']),
      fieldValues: fieldValues ?? _fieldValuesFromMap(map, category.fields),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Category CRUD
  // ──────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories({bool withFields = false}) async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'sortOrder ASC, name ASC');
    final categories = <Category>[];
    for (final row in rows) {
      final fields = withFields ? await getCategoryFields(row['id'] as String) : <CategoryField>[];
      categories.add(Category.fromMap(row, fields: fields));
    }
    return categories;
  }

  Future<Category?> getCategoryById(String id, {bool withFields = false}) async {
    final db = await database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final fields = withFields ? await getCategoryFields(id) : <CategoryField>[];
    return Category.fromMap(rows.first, fields: fields);
  }

  Future<Category?> getCategoryByName(String name, {bool withFields = false}) async {
    final db = await database;
    final rows = await db.query('categories', where: 'name = ?', whereArgs: [name]);
    if (rows.isEmpty) return null;
    final catId = rows.first['id'] as String;
    final fields = withFields ? await getCategoryFields(catId) : <CategoryField>[];
    return Category.fromMap(rows.first, fields: fields);
  }

  Future<String> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
    return category.id;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    final map = category.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    return db.update('categories', map, where: 'id = ?', whereArgs: [category.id]);
  }

  /// Deletes a non-system category along with all its fields and assets (cascade).
  Future<int> deleteCategory(String id) async {
    final db = await database;
    final rows = await db.query('categories', columns: ['isSystem'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty && (rows.first['isSystem'] as int) == 1) {
      throw StateError('Cannot delete a system category.');
    }
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────────────────────────────
  // CategoryField CRUD
  // ──────────────────────────────────────────────────────────────

  Future<List<CategoryField>> getCategoryFields(String categoryId) async {
    final db = await database;
    final rows = await db.query(
      'category_fields',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'sortOrder ASC',
    );
    return rows.map(CategoryField.fromMap).toList();
  }

  Future<String> insertCategoryField(CategoryField field) async {
    final db = await database;
    await db.insert('category_fields', field.toMap());
    return field.id;
  }

  Future<int> updateCategoryField(CategoryField field) async {
    final db = await database;
    final map = field.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    return db.update('category_fields', map, where: 'id = ?', whereArgs: [field.id]);
  }

  Future<int> deleteCategoryField(String fieldId) async {
    final db = await database;
    return db.delete('category_fields', where: 'id = ?', whereArgs: [fieldId]);
  }

  // ──────────────────────────────────────────────────────────────
  // Asset CRUD
  // ──────────────────────────────────────────────────────────────

  Future<String> insertAsset(Asset asset, List<CategoryField> fields) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('assets', asset.toMap());
      for (final field in fields) {
        final raw = asset.fieldValues[field.name];
        final value = field.isSensitive ? _encrypt(raw) : raw;
        await txn.insert('asset_field_values', {
          'id': _uuid.v4(), 'assetId': asset.id, 'fieldId': field.id,
          'value': value, 'createdAt': now, 'updatedAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    return asset.id;
  }

  Future<int> updateAsset(Asset asset, List<CategoryField> fields) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    int result = 0;

    await db.transaction((txn) async {
      final map = asset.toMap();
      map['updatedAt'] = now;
      result = await txn.update('assets', map, where: 'id = ?', whereArgs: [asset.id]);

      for (final field in fields) {
        final raw = asset.fieldValues[field.name];
        final value = field.isSensitive ? _encrypt(raw) : raw;
        await txn.insert('asset_field_values', {
          'id': _uuid.v4(), 'assetId': asset.id, 'fieldId': field.id,
          'value': value, 'createdAt': now, 'updatedAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    return result;
  }

  Future<int> deleteAsset(String id) async {
    final db = await database;
    return db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns all assets for a given category, with field values populated.
  Future<List<Asset>> getAssetsByCategory(String categoryId) async {
    final db = await database;
    final fields = await getCategoryFields(categoryId);
    final fieldById = {for (final f in fields) f.id: f};

    final rows = await db.query('assets',
        where: 'categoryId = ?', whereArgs: [categoryId], orderBy: 'name ASC');

    final assets = <Asset>[];
    for (final row in rows) {
      final assetId = row['id'] as String;
      final valueRows = await db.query('asset_field_values',
          where: 'assetId = ?', whereArgs: [assetId]);

      final fieldValues = <String, String?>{};
      for (final vRow in valueRows) {
        final field = fieldById[vRow['fieldId'] as String];
        if (field == null) continue;
        final raw = vRow['value'] as String?;
        fieldValues[field.name] = field.isSensitive ? _decrypt(raw) : raw;
      }

      assets.add(Asset.fromMap(row, fieldValues: fieldValues));
    }

    return assets;
  }

  /// Returns a single asset with all field values populated.
  Future<Asset?> getAssetById(String id) async {
    final db = await database;
    final rows = await db.query('assets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final categoryId = rows.first['categoryId'] as String;
    final fields = await getCategoryFields(categoryId);
    final fieldById = {for (final f in fields) f.id: f};

    final valueRows = await db.query('asset_field_values',
        where: 'assetId = ?', whereArgs: [id]);

    final fieldValues = <String, String?>{};
    for (final vRow in valueRows) {
      final field = fieldById[vRow['fieldId'] as String];
      if (field == null) continue;
      final raw = vRow['value'] as String?;
      fieldValues[field.name] = field.isSensitive ? _decrypt(raw) : raw;
    }

    return Asset.fromMap(rows.first, fieldValues: fieldValues);
  }

  // ──────────────────────────────────────────────────────────────
  // Legacy typed CRUD adapters
  // ──────────────────────────────────────────────────────────────

  Future<int> insertBankAccount(BankAccount account) async {
    final category = await _requiredCategory('Banks');
    final asset = await _assetFromLegacyMap(categoryName: 'Banks', map: account.toMap());
    await insertAsset(asset, category.fields);
    return 1;
  }

  Future<List<BankAccount>> getAllBankAccounts() async {
    final category = await _requiredCategory('Banks');
    final assets = await getAssetsByCategory(category.id);
    return assets.map((asset) => BankAccount.fromMap(_mapFromAsset(asset))).toList();
  }

  Future<int> updateBankAccount(BankAccount account) async {
    final category = await _requiredCategory('Banks');
    final asset = await _assetFromLegacyMap(categoryName: 'Banks', map: account.toMap());
    return updateAsset(asset, category.fields);
  }

  Future<int> deleteBankAccount(String id) async {
    return deleteAsset(id);
  }

  Future<int> insertRetirementAccount(RetirementAccount account) async {
    final category = await _requiredCategory('Retirement');
    final asset = await _assetFromLegacyMap(categoryName: 'Retirement', map: account.toMap());
    await insertAsset(asset, category.fields);
    return 1;
  }

  Future<List<RetirementAccount>> getAllRetirementAccounts() async {
    final category = await _requiredCategory('Retirement');
    final assets = await getAssetsByCategory(category.id);
    return assets.map((asset) => RetirementAccount.fromMap(_mapFromAsset(asset))).toList();
  }

  Future<int> updateRetirementAccount(RetirementAccount account) async {
    final category = await _requiredCategory('Retirement');
    final asset = await _assetFromLegacyMap(categoryName: 'Retirement', map: account.toMap());
    return updateAsset(asset, category.fields);
  }

  Future<int> deleteRetirementAccount(String id) async {
    return deleteAsset(id);
  }

  Future<int> insertInvestment(Investment investment) async {
    final category = await _requiredCategory('Investments');
    final asset = await _assetFromLegacyMap(categoryName: 'Investments', map: investment.toMap());
    await insertAsset(asset, category.fields);
    return 1;
  }

  Future<List<Investment>> getAllInvestments() async {
    final category = await _requiredCategory('Investments');
    final assets = await getAssetsByCategory(category.id);
    return assets.map((asset) => Investment.fromMap(_mapFromAsset(asset))).toList();
  }

  Future<int> updateInvestment(Investment investment) async {
    final category = await _requiredCategory('Investments');
    final asset = await _assetFromLegacyMap(categoryName: 'Investments', map: investment.toMap());
    return updateAsset(asset, category.fields);
  }

  Future<int> deleteInvestment(String id) async {
    return deleteAsset(id);
  }

  Future<int> insertProperty(Property property) async {
    final category = await _requiredCategory(_categoryRealEstate);
    final asset = await _assetFromLegacyMap(categoryName: _categoryRealEstate, map: property.toMap());
    await insertAsset(asset, category.fields);
    return 1;
  }

  Future<List<Property>> getAllProperties() async {
    final category = await _requiredCategory(_categoryRealEstate);
    final assets = await getAssetsByCategory(category.id);
    return assets.map((asset) => Property.fromMap(_mapFromAsset(asset))).toList();
  }

  Future<int> updateProperty(Property property) async {
    final category = await _requiredCategory(_categoryRealEstate);
    final asset = await _assetFromLegacyMap(categoryName: _categoryRealEstate, map: property.toMap());
    return updateAsset(asset, category.fields);
  }

  Future<int> deleteProperty(String id) async {
    return deleteAsset(id);
  }

  Future<int> insertVehicle(Vehicle vehicle) async {
    final category = await _requiredCategory(_categoryPersonalProperty);
    final asset = await _assetFromLegacyMap(categoryName: _categoryPersonalProperty, map: vehicle.toMap());
    await insertAsset(asset, category.fields);
    return 1;
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final category = await _requiredCategory(_categoryPersonalProperty);
    final assets = await getAssetsByCategory(category.id);
    return assets.map((asset) => Vehicle.fromMap(_mapFromAsset(asset))).toList();
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final category = await _requiredCategory(_categoryPersonalProperty);
    final asset = await _assetFromLegacyMap(categoryName: _categoryPersonalProperty, map: vehicle.toMap());
    return updateAsset(asset, category.fields);
  }

  Future<int> deleteVehicle(String id) async {
    return deleteAsset(id);
  }

  // ──────────────────────────────────────────────────────────────
  // Dashboard helpers
  // ──────────────────────────────────────────────────────────────

  /// Returns asset count per category name.
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.name, COUNT(a.id) AS cnt
      FROM categories c
      LEFT JOIN assets a ON a.categoryId = c.id
      GROUP BY c.id, c.name
      ORDER BY c.sortOrder ASC
    ''');
    return {for (final r in rows) r['name'] as String: (r['cnt'] as int? ?? 0)};
  }

  /// Returns the USD-equivalent total of each category value field.
  Future<Map<String, double>> getCategoryUsdTotals() async {
    final db = await database;

    final currencyRows = await db.query('currencies', columns: ['code', 'rateToUsd']);
    final rates = <String, double>{
      for (final r in currencyRows)
        r['code'] as String: (r['rateToUsd'] as num).toDouble(),
    };

    double rate(String? code) {
      final r = rates[code ?? 'USD'] ?? 1.0;
      return r <= 0 ? 1.0 : r;
    }

    final catRows = await db.rawQuery('''
      SELECT c.id AS catId, c.name AS catName, cf.id AS fieldId
      FROM categories c
      LEFT JOIN category_fields cf ON cf.categoryId = c.id AND cf.isValueField = 1
      ORDER BY c.sortOrder ASC
    ''');

    final totals = <String, double>{};
    for (final row in catRows) {
      final catName = row['catName'] as String;
      final fieldId = row['fieldId'] as String?;
      if (fieldId == null) {
        totals[catName] = 0;
        continue;
      }

      final valueRows = await db.rawQuery('''
        SELECT afv.value, a.currencyCode
        FROM asset_field_values afv
        JOIN assets a ON a.id = afv.assetId
        WHERE afv.fieldId = ?
      ''', [fieldId]);

      double total = 0;
      for (final vr in valueRows) {
        final v = double.tryParse(vr['value']?.toString() ?? '');
        if (v != null) total += v / rate(vr['currencyCode'] as String?);
      }
      totals[catName] = total;
    }

    return totals;
  }

  // ──────────────────────────────────────────────────────────────
  // Currency CRUD
  // ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    final db = await database;
    return db.query('currencies', orderBy: 'code ASC');
  }

  Future<int> upsertCurrency({
    required String code,
    required String name,
    required double rateToUsd,
  }) async {
    final db = await database;
    final existing = await db.query('currencies',
        where: 'code = ?', whereArgs: [code], limit: 1);
    final now = DateTime.now().toIso8601String();
    return db.insert('currencies', {
      'code': code, 'name': name, 'rateToUsd': rateToUsd,
      'createdAt': existing.isNotEmpty ? existing.first['createdAt'] : now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteCurrency(String code) async {
    if (code == 'USD') return 0;
    final db = await database;
    return db.delete('currencies', where: 'code = ?', whereArgs: [code]);
  }

  // ──────────────────────────────────────────────────────────────
  // Backup / Restore
  // ──────────────────────────────────────────────────────────────

  Future<String> exportVaultDataJson() async {
    final db = await database;

    final categories = await db.query('categories');
    final categoryFields = await db.query('category_fields');
    final assets = await db.query('assets');
    final assetFieldValues = await db.query('asset_field_values');
    final currencies = await db.query('currencies');

    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'categories': categories,
        'category_fields': categoryFields,
        'assets': assets,
        'asset_field_values': assetFieldValues,
        'currencies': currencies,
      },
    });
  }

  Future<void> importVaultDataJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format. Root must be an object.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup format. Missing data object.');
    }

    List<Map<String, dynamic>> tableRows(String key) {
      final value = data[key];
      if (value == null) return [];
      if (value is! List) {
        throw FormatException('Invalid backup format for $key.');
      }
      return value
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    }

    final categories = tableRows('categories');
    final categoryFields = tableRows('category_fields');
    final assets = tableRows('assets');
    final assetFieldValues = tableRows('asset_field_values');
    final currencies = tableRows('currencies');

    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');

      await txn.delete('asset_field_values');
      await txn.delete('assets');
      await txn.delete('category_fields');
      await txn.delete('categories');
      await txn.delete('currencies');

      for (final row in categories) {
        await txn.insert('categories', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in categoryFields) {
        await txn.insert('category_fields', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in assets) {
        await txn.insert('assets', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in assetFieldValues) {
        await txn.insert('asset_field_values', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in currencies) {
        await txn.insert('currencies', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Ensure baseline currency exists if import payload omitted it.
      final usd = await txn.query('currencies', where: 'code = ?', whereArgs: ['USD']);
      if (usd.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await txn.insert('currencies', {
          'code': 'USD',
          'name': 'US Dollar',
          'rateToUsd': 1.0,
          'createdAt': now,
          'updatedAt': now,
        });
      }

      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }
}

// ──────────────────────────────────────────────────────────────
// Internal helper used only during seeding
// ──────────────────────────────────────────────────────────────

class _FieldSpec {
  final String name;
  final String label;
  final String fieldType;
  final bool isRequired;
  final bool isSensitive;
  final bool isValueField;

  const _FieldSpec(
    this.name,
    this.label, {
    this.fieldType = 'text',
    this.isRequired = false,
    this.isSensitive = false,
    this.isValueField = false,
  });
}
