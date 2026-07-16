import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/asset.dart';
import '../../data/models/category.dart';
import '../../data/models/category_field.dart';
import '../../core/theme/app_theme.dart';
import 'asset_form_screen.dart';

class AssetListScreen extends StatefulWidget {
  final Category category;

  const AssetListScreen({super.key, required this.category});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final _db = DatabaseHelper();
  List<Asset> _assets = [];
  List<CategoryField> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _db.getAssetsByCategory(widget.category.id),
      _db.getCategoryFields(widget.category.id),
    ]);
    setState(() {
      _assets = results[0] as List<Asset>;
      _fields = results[1] as List<CategoryField>;
      _isLoading = false;
    });
  }

  CategoryField? get _valueField =>
      _fields.where((f) => f.isValueField).firstOrNull;

  CategoryField? get _primaryField =>
      _fields.where((f) => f.isRequired && !f.isSensitive).firstOrNull;

  String _formatValue(Asset asset) {
    final vf = _valueField;
    if (vf == null) return '';
    final v = asset.numericValue(vf.name);
    if (v == null) return '';
    final currency = asset.currencyCode;
    if (v >= 1000000) return '$currency ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '$currency ${(v / 1000).toStringAsFixed(1)}K';
    return '$currency ${v.toStringAsFixed(2)}';
  }

  Future<void> _confirmDelete(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${asset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _db.deleteAsset(asset.id);
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${asset.name}" deleted')),
      );
    }
  }

  Future<void> _openForm({Asset? asset}) async {
    final category = await _db.getCategoryById(
      widget.category.id,
      withFields: true,
    );
    if (category == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetFormScreen(category: category, asset: asset),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _assets.length,
                    itemBuilder: (_, i) => _buildCard(_assets[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${widget.category.name.toLowerCase()} yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first entry',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded),
            label: Text('Add ${widget.category.name.replaceAll(RegExp(r's$'), '')}'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Asset asset) {
    final subtitle = _primaryField != null
        ? asset.fieldValues[_primaryField!.name]
        : null;
    final value = _formatValue(asset);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: const [
          BoxShadow(color: AppTheme.cardShadowColor, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: InkWell(
        onTap: () => _openForm(asset: asset),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(Icons.insert_drive_file_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              // Value
              if (value.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              // Delete
              IconButton(
                onPressed: () => _confirmDelete(asset),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppTheme.textSecondary),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
