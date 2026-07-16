import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() => _isLoading = true);
    final rows = await _dbHelper.getCurrencies();
    setState(() {
      _currencies = rows;
      _isLoading = false;
    });
  }

  Future<void> _showCurrencyDialog({Map<String, dynamic>? currency}) async {
    final isEdit = currency != null;
    final codeController = TextEditingController(text: isEdit ? currency['code'].toString() : '');
    final nameController = TextEditingController(text: isEdit ? currency['name'].toString() : '');
    final rateController = TextEditingController(
      text: isEdit ? (currency['rateToUsd'] as num).toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Currency' : 'Add Currency'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !isEdit,
                  decoration: const InputDecoration(
                    labelText: 'Currency Code *',
                    hintText: 'e.g., EUR, INR, AED',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) {
                    final code = (value ?? '').trim().toUpperCase();
                    final codeRegex = RegExp(r'^[A-Z]{3,6}$');
                    if (code.isEmpty) {
                      return 'Currency code is required';
                    }
                    if (!codeRegex.hasMatch(code)) {
                      return 'Use 3 to 6 uppercase letters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Name *',
                    hintText: 'e.g., Euro, Indian Rupee',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Currency name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Currency Units per 1 USD *',
                    hintText: 'e.g., 83 for INR, 0.92 for EUR',
                    prefixIcon: Icon(Icons.calculate_outlined),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid number greater than 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final code = codeController.text.trim().toUpperCase();
                final name = nameController.text.trim();
                final rate = double.parse(rateController.text.trim());
                await _dbHelper.upsertCurrency(code: code, name: name, rateToUsd: rate);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _loadCurrencies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Currency updated' : 'Currency added')),
        );
      }
    }
  }

  Future<void> _deleteCurrency(Map<String, dynamic> currency) async {
    final code = currency['code'].toString();
    if (code == 'USD') {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Currency'),
        content: Text('Delete $code from your currency list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteCurrency(code);
      await _loadCurrencies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Currency deleted')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final json = await _dbHelper.exportVaultDataJson();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Copy this backup JSON and store it safely.'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 260),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.navyChip,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.navyBorder),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup JSON copied to clipboard.')),
                );
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste backup JSON to restore data. This will replace current data.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Paste backup JSON here',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Backup JSON is required.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dbHelper.importVaultDataJson(controller.text.trim());
      await _loadCurrencies();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data import completed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Currencies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage allowed currencies and rates as units per 1 USD.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Backup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Export your vault as JSON and import it later on this device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Export Data'),
                        subtitle: const Text('Generate backup JSON for your vault'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _exportData,
                      ),
                      Divider(color: AppTheme.navyBorder.withOpacity(0.7), height: 1),
                      ListTile(
                        leading: const Icon(Icons.upload_rounded),
                        title: const Text('Import Data'),
                        subtitle: const Text('Restore vault from backup JSON'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _importData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ..._currencies.map(
                  (currency) {
                    final code = currency['code'].toString();
                    final name = currency['name'].toString();
                    final rate = (currency['rateToUsd'] as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.navyChip,
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text('1 USD = ${rate.toStringAsFixed(4)} $code'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showCurrencyDialog(currency: currency),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: code == 'USD' ? null : () => _deleteCurrency(currency),
                              icon: Icon(
                                Icons.delete_outline,
                                color: code == 'USD' ? Colors.grey : AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCurrencyDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Currency'),
      ),
    );
  }
}
