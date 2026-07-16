import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/asset.dart';
import '../../data/models/category.dart';
import '../../data/models/category_field.dart';
import '../../core/theme/app_theme.dart';

class AssetFormScreen extends StatefulWidget {
  /// Category must be loaded with [withFields: true].
  final Category category;
  final Asset? asset;

  const AssetFormScreen({super.key, required this.category, this.asset});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  final Map<String, TextEditingController> _ctrlMap = {};

  String _currencyCode = 'USD';
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = false;

  List<CategoryField> get _fields => widget.category.fields;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.asset?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.asset?.notes ?? '');
    _currencyCode = widget.asset?.currencyCode ?? 'USD';

    for (final field in _fields) {
      _ctrlMap[field.name] = TextEditingController(
        text: widget.asset?.fieldValues[field.name] ?? field.defaultValue ?? '',
      );
    }
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _ctrlMap.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final rows = await _db.getCurrencies();
    setState(() => _currencies = rows);
  }

  Future<void> _pickDate(String fieldName) async {
    final existing = _ctrlMap[fieldName]?.text;
    final initial = existing != null && existing.isNotEmpty
        ? DateTime.tryParse(existing) ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _ctrlMap[fieldName]?.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final values = <String, String?>{
        for (final f in _fields)
          f.name: _ctrlMap[f.name]?.text.trim().nullIfEmpty,
      };

      final asset = Asset(
        id: widget.asset?.id,
        categoryId: widget.category.id,
        name: _nameCtrl.text.trim(),
        notes: _notesCtrl.text.trim().nullIfEmpty,
        currencyCode: _currencyCode,
        createdAt: widget.asset?.createdAt,
        fieldValues: values,
      );

      if (widget.asset == null) {
        await _db.insertAsset(asset, _fields);
      } else {
        await _db.updateAsset(asset, _fields);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.asset == null
                ? '${widget.category.name.replaceAll(RegExp(r's$'), '')} added'
                : 'Updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.asset == null ? 'Add ${widget.category.name}' : 'Edit ${widget.asset!.name}';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('General'),
            _textField(
              controller: _nameCtrl,
              label: 'Name',
              hint: 'Label for this entry',
              isRequired: true,
            ),
            const SizedBox(height: 12),
            _currencyDropdown(),
            const SizedBox(height: 24),
            if (_fields.isNotEmpty) ...[
              _section('Details'),
              for (final field in _fields) ...[
                _buildFieldInput(field),
                const SizedBox(height: 12),
              ],
            ],
            _section('Notes'),
            _textField(
              controller: _notesCtrl,
              label: 'Notes',
              hint: 'Optional notes',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildFieldInput(CategoryField field) {
    switch (field.fieldType) {
      case FieldType.boolean:
        return _boolField(field);
      case FieldType.date:
        return _dateField(field);
      default:
        return _textField(
          controller: _ctrlMap[field.name]!,
          label: field.label,
          isRequired: field.isRequired,
          obscure: field.isSensitive,
          keyboardType: field.fieldType == FieldType.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : field.fieldType == FieldType.url
                  ? TextInputType.url
                  : TextInputType.text,
          inputFormatters: field.fieldType == FieldType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          suffixIcon: field.isSensitive
              ? _ObscureToggle(controller: _ctrlMap[field.name]!)
              : null,
        );
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  Widget _dateField(CategoryField field) {
    return GestureDetector(
      onTap: () => _pickDate(field.name),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _ctrlMap[field.name],
          decoration: InputDecoration(
            labelText: field.isRequired ? '${field.label} *' : field.label,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
          ),
          validator: field.isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null
              : null,
        ),
      ),
    );
  }

  Widget _boolField(CategoryField field) {
    final ctrl = _ctrlMap[field.name]!;
    return StatefulBuilder(
      builder: (_, setSub) => SwitchListTile(
        title: Text(field.label),
        value: ctrl.text == 'true',
        onChanged: (v) {
          ctrl.text = v ? 'true' : 'false';
          setSub(() {});
        },
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.dividerColor),
        ),
      ),
    );
  }

  Widget _currencyDropdown() {
    if (_currencies.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      value: _currencyCode,
      decoration: InputDecoration(
        labelText: 'Currency',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      items: _currencies
          .map((c) => DropdownMenuItem<String>(
                value: c['code'] as String,
                child: Text('${c['code']} — ${c['name']}'),
              ))
          .toList(),
      onChanged: (v) => setState(() => _currencyCode = v ?? 'USD'),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Helper: toggle obscure visibility
// ──────────────────────────────────────────────────────────────

class _ObscureToggle extends StatefulWidget {
  final TextEditingController controller;
  const _ObscureToggle({required this.controller});

  @override
  State<_ObscureToggle> createState() => _ObscureToggleState();
}

class _ObscureToggleState extends State<_ObscureToggle> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: AppTheme.textSecondary,
      ),
      onPressed: () {
        setState(() => _visible = !_visible);
        // Rebuild parent to pass new obscureText value
        // The parent _AssetFormScreenState rebuilds via _buildFieldInput rebuild on setState
        (context.findAncestorStateOfType<_AssetFormScreenState>())
            ?.setState(() {});
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// String extension
// ──────────────────────────────────────────────────────────────

extension _StringX on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
