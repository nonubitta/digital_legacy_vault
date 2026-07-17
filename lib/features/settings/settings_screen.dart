import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/database/database_helper.dart';
import '../../core/utils/app_settings_helper.dart';
import '../../core/utils/access_code_helper.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dbHelper = DatabaseHelper();
  final _appSettings = AppSettingsHelper();
  final _accessCodeHelper = AccessCodeHelper();
  final _vaultNameController = TextEditingController();
  static final RegExp _accessCodePattern = RegExp(r'^[A-Za-z0-9]{4,8}$');
  List<Map<String, dynamic>> _currencies = [];
  bool _isSavingVaultName = false;
  bool _hasSecurityQuestions = false;
  bool _showHomeAmounts = true;
  bool _isLoading = true;

  String _normalizeAccessCode(String code) => code.trim().toUpperCase();

  String? _validateAccessCode(String? value) {
    final code = _normalizeAccessCode(value ?? '');
    if (!_accessCodePattern.hasMatch(code)) {
      return 'Enter 4 to 8 letters or numbers.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    _loadVaultName();
    _loadShowHomeAmounts();
    _loadSecurityQuestionsStatus();
  }

  @override
  void dispose() {
    _vaultNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    setState(() => _isLoading = true);
    final rows = await _dbHelper.getCurrencies();
    setState(() {
      _currencies = rows;
      _isLoading = false;
    });
  }

  Future<void> _loadVaultName() async {
    final name = await _appSettings.getVaultName();
    if (!mounted) return;
    _vaultNameController.text = name;
  }

  Future<void> _loadSecurityQuestionsStatus() async {
    final hasQuestions = await _accessCodeHelper.hasSecurityQuestions();
    if (!mounted) return;
    setState(() => _hasSecurityQuestions = hasQuestions);
  }

  Future<void> _loadShowHomeAmounts() async {
    final showHomeAmounts = await _appSettings.getShowHomeAmounts();
    if (!mounted) return;
    setState(() => _showHomeAmounts = showHomeAmounts);
  }

  Future<void> _saveVaultName() async {
    final name = _vaultNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }

    setState(() => _isSavingVaultName = true);
    try {
      await _appSettings.saveVaultName(name);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vault name updated.')));
    } finally {
      if (mounted) {
        setState(() => _isSavingVaultName = false);
      }
    }
  }

  Future<void> _showCurrencyDialog({Map<String, dynamic>? currency}) async {
    final isEdit = currency != null;
    final codeController = TextEditingController(
      text: isEdit ? currency['code'].toString() : '',
    );
    final nameController = TextEditingController(
      text: isEdit ? currency['name'].toString() : '',
    );
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                await _dbHelper.upsertCurrency(
                  code: code,
                  name: name,
                  rateToUsd: rate,
                );
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
          SnackBar(
            content: Text(isEdit ? 'Currency updated' : 'Currency added'),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Currency deleted')));
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
                  const SnackBar(
                    content: Text('Backup JSON copied to clipboard.'),
                  ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _showUpdateSecurityCodeDialog() async {
    final hasCode = await _accessCodeHelper.hasAccessCode();
    if (!hasCode) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No security code is set yet. Please set one from the sign-in screen.',
          ),
        ),
      );
      return;
    }

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Security Code'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                maxLength: 8,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Current code',
                  hintText: 'Enter current code',
                ),
                validator: (value) {
                  final code = (value ?? '').trim();
                  if (code.isEmpty) return 'Current code is required.';
                  return _validateAccessCode(value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: newController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                maxLength: 8,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'New code',
                  hintText: '4 to 8 letters or numbers',
                ),
                validator: (value) {
                  final normalized = _normalizeAccessCode(value ?? '');
                  final validationError = _validateAccessCode(value);
                  if (validationError != null) return validationError;
                  if (normalized ==
                      _normalizeAccessCode(currentController.text)) {
                    return 'New code must be different.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final isCurrentValid = await _accessCodeHelper.verifyAccessCode(
                _normalizeAccessCode(currentController.text),
              );
              if (!isCurrentValid) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Current code is incorrect.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    backgroundColor: Color.fromARGB(255, 247, 223, 153),
                  ),
                );
                return;
              }
              await _accessCodeHelper.saveAccessCode(
                _normalizeAccessCode(newController.text),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Security code updated.')));
    }
  }

  Future<void> _showSecurityQuestionsDialog() async {
    final hadSecurityQuestions = _hasSecurityQuestions;
    final existing = await _accessCodeHelper.getSecurityQuestions();
    final questionControllers = List<TextEditingController>.generate(
      5,
      (index) => TextEditingController(
        text: index < existing.length
            ? (existing[index]['question'] ?? '')
            : '',
      ),
    );
    final answerControllers = List<TextEditingController>.generate(
      5,
      (index) => TextEditingController(
        text: index < existing.length ? (existing[index]['answer'] ?? '') : '',
      ),
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _hasSecurityQuestions
              ? 'Update Security Questions'
              : 'Add Security Questions',
        ),
        content: SizedBox(
          width: 700,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set 5 questions and 5 answers you can use for account recovery.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 5; i++) ...[
                    TextFormField(
                      controller: questionControllers[i],
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Question ${i + 1}',
                        hintText: 'Write your security question',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Question ${i + 1} is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: answerControllers[i],
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Answer ${i + 1}',
                        hintText: 'Write the answer',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Answer ${i + 1} is required.';
                        }
                        return null;
                      },
                    ),
                    if (i < 4) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = List<Map<String, String>>.generate(
                5,
                (index) => {
                  'question': questionControllers[index].text.trim(),
                  'answer': answerControllers[index].text.trim(),
                },
              );
              await _accessCodeHelper.saveSecurityQuestions(payload);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(_hasSecurityQuestions ? 'Update' : 'Add'),
          ),
        ],
      ),
    );

    for (final controller in questionControllers) {
      controller.dispose();
    }
    for (final controller in answerControllers) {
      controller.dispose();
    }

    if (saved == true) {
      await _loadSecurityQuestionsStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hadSecurityQuestions
                ? 'Security questions updated.'
                : 'Security questions saved.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vault Name',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSavingVaultName ? null : _saveVaultName,
                      icon: _isSavingVaultName
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Set the name shown on your home screen title.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _vaultNameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveVaultName(),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Legacy Vault',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Currencies',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCurrencyDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Currency'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage allowed currencies and rates as units per 1 USD.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      for (var i = 0; i < _currencies.length; i++) ...[
                        Builder(
                          builder: (context) {
                            final currency = _currencies[i];
                            final code = currency['code'].toString();
                            final name = currency['name'].toString();
                            final rate = (currency['rateToUsd'] as num)
                                .toDouble();

                            return ListTile(
                              visualDensity: const VisualDensity(vertical: -1),
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
                              subtitle: Text(
                                '1 USD = ${rate.toStringAsFixed(4)} $code',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showCurrencyDialog(currency: currency),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: code == 'USD'
                                        ? null
                                        : () => _deleteCurrency(currency),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: code == 'USD'
                                          ? Colors.grey
                                          : AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (i < _currencies.length - 1)
                          Divider(
                            color: AppTheme.navyBorder.withOpacity(0.7),
                            height: 1,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Security',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your vault security code.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -1),
                        leading: const Icon(Icons.visibility_outlined),
                        title: const Text('Show home screen amounts'),
                        subtitle: const Text(
                          'Display the actual total instead of *****',
                        ),
                        trailing: Switch(
                          value: _showHomeAmounts,
                          onChanged: (value) async {
                            setState(() => _showHomeAmounts = value);
                            await _appSettings.saveShowHomeAmounts(value);
                          },
                        ),
                      ),
                      Divider(
                        color: AppTheme.navyBorder.withOpacity(0.7),
                        height: 1,
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -1),
                        leading: const Icon(Icons.lock_reset_outlined),
                        title: const Text('Update Security Code'),
                        subtitle: const Text('Change login security code'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showUpdateSecurityCodeDialog,
                      ),
                      Divider(
                        color: AppTheme.navyBorder.withOpacity(0.7),
                        height: 1,
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -1),
                        leading: const Icon(Icons.quiz_outlined),
                        title: Text(
                          _hasSecurityQuestions
                              ? 'Update Security Questions'
                              : 'Add Security Questions',
                        ),
                        subtitle: Text(
                          _hasSecurityQuestions
                              ? 'Edit your 5 security questions and answers'
                              : 'Set up 5 security questions and answers',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showSecurityQuestionsDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Backup',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -1),
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Export Data'),
                        subtitle: const Text(
                          'Generate backup JSON for your vault',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _exportData,
                      ),
                      Divider(
                        color: AppTheme.navyBorder.withOpacity(0.7),
                        height: 1,
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -1),
                        leading: const Icon(Icons.upload_rounded),
                        title: const Text('Import Data'),
                        subtitle: const Text('Restore vault from backup JSON'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _importData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'About',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: const ListTile(
                    visualDensity: VisualDensity(vertical: -1),
                    leading: Icon(Icons.info_outline_rounded),
                    title: Text('Developed by Gurmeet Singh Khalsa'),
                  ),
                ),
              ],
            ),
    );
  }
}
