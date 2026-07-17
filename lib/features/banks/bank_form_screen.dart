import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/bank_account.dart';
import '../../core/theme/app_theme.dart';

class BankFormScreen extends StatefulWidget {
  final BankAccount? account;

  const BankFormScreen({super.key, this.account});

  @override
  State<BankFormScreen> createState() => _BankFormScreenState();
}

class _BankFormScreenState extends State<BankFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  final List<String> _accountTypeOptions = const [
    'Checking',
    'Savings',
    'Money Market',
    'Certificate of Deposit (CD)',
    'Business Checking',
    'Other',
  ];
  
  late TextEditingController _nameController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountTypeController;
  late TextEditingController _accountNumberController;
  late TextEditingController _routingNumberController;
  late TextEditingController _swiftCodeController;
  late TextEditingController _onlineUrlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordHintController;
  late TextEditingController _balanceController;
  late TextEditingController _beneficiariesController;
  late TextEditingController _notesController;
  List<Map<String, dynamic>> _currencies = [];
  String _selectedCurrencyCode = 'USD';
  final Map<TextEditingController, bool> _obscureStates = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankNameController = TextEditingController(text: widget.account?.bankName ?? '');
    _accountTypeController = TextEditingController(text: widget.account?.accountType ?? '');
    _accountNumberController = TextEditingController(text: widget.account?.accountNumber ?? '');
    _routingNumberController = TextEditingController(text: widget.account?.routingNumber ?? '');
    _swiftCodeController = TextEditingController(text: widget.account?.swiftCode ?? '');
    _onlineUrlController = TextEditingController(text: widget.account?.onlineAccessUrl ?? '');
    _usernameController = TextEditingController(text: widget.account?.username ?? '');
    _passwordHintController = TextEditingController(text: widget.account?.passwordHint ?? '');
    _balanceController = TextEditingController(text: widget.account?.balance?.toString() ?? '');
    _beneficiariesController = TextEditingController(text: widget.account?.beneficiaries ?? '');
    _notesController = TextEditingController(text: widget.account?.notes ?? '');
    _selectedCurrencyCode = widget.account?.currencyCode ?? 'USD';
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountTypeController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _swiftCodeController.dispose();
    _onlineUrlController.dispose();
    _usernameController.dispose();
    _passwordHintController.dispose();
    _balanceController.dispose();
    _beneficiariesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final account = BankAccount(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountType: _accountTypeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        routingNumber: _routingNumberController.text.trim().isEmpty 
            ? null 
            : _routingNumberController.text.trim(),
        swiftCode: _swiftCodeController.text.trim().isEmpty 
            ? null 
            : _swiftCodeController.text.trim(),
        onlineAccessUrl: _onlineUrlController.text.trim().isEmpty 
            ? null 
            : _onlineUrlController.text.trim(),
        username: _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim(),
        passwordHint: _passwordHintController.text.trim().isEmpty 
            ? null 
            : _passwordHintController.text.trim(),
        balance: _balanceController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_balanceController.text.trim()),
        currencyCode: _selectedCurrencyCode,
        beneficiaries: _beneficiariesController.text.trim().isEmpty 
            ? null 
            : _beneficiariesController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: widget.account?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.account == null) {
        await _dbHelper.insertBankAccount(account);
      } else {
        await _dbHelper.updateBankAccount(account);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.account == null 
                ? 'Bank account added successfully' 
                : 'Bank account updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Add Bank Account' : 'Edit Bank Account'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              'Basic Information',
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Account Name',
                  hint: 'e.g., Main Checking Account',
                  icon: Icons.label_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'e.g., Chase, Bank of America',
                  icon: Icons.account_balance,
                  isRequired: true,
                ),
                _buildAccountTypeDropdown(
                  controller: _accountTypeController,
                  label: 'Account Type',
                  icon: Icons.category_outlined,
                  isRequired: true,
                ),
              ],
            ),
            
            _buildSection(
              'Account Details',
              [
                _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Optional',
                  icon: Icons.numbers,
                  obscureText: true,
                ),
                _buildTextField(
                  controller: _routingNumberController,
                  label: 'Routing Number',
                  icon: Icons.route,
                ),
                _buildTextField(
                  controller: _swiftCodeController,
                  label: 'SWIFT Code',
                  icon: Icons.code,
                ),
                _buildCurrencyDropdown(),
                _buildTextField(
                  controller: _balanceController,
                  label: 'Current Balance',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            
            _buildSection(
              'Online Access',
              [
                _buildTextField(
                  controller: _onlineUrlController,
                  label: 'Online Banking URL',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_outlined,
                ),
                _buildTextField(
                  controller: _passwordHintController,
                  label: 'Password Hint',
                  hint: 'Store hints, not actual passwords',
                  icon: Icons.lock_outlined,
                ),
              ],
            ),
            
            _buildSection(
              'Additional Information',
              [
                _buildTextField(
                  controller: _beneficiariesController,
                  label: 'Beneficiaries',
                  icon: Icons.people_outlined,
                  maxLines: 2,
                ),
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes',
                  hint: 'Any additional information...',
                  icon: Icons.note_outlined,
                  maxLines: 3,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.account == null ? 'Add Account' : 'Update Account'),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isObscured = _obscureStates.putIfAbsent(controller, () => obscureText);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isObscured,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: obscureText
              ? IconButton(
                  tooltip: isObscured ? 'Show' : 'Hide',
                  onPressed: () => setState(() {
                    _obscureStates[controller] = !isObscured;
                  }),
                  icon: Icon(
                    isObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                  ),
                )
              : null,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildAccountTypeDropdown({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
  }) {
    final currentValue = controller.text.trim();
    final options = <String>[
      ..._accountTypeOptions,
      if (currentValue.isNotEmpty && !_accountTypeOptions.contains(currentValue)) currentValue,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue.isEmpty ? null : currentValue,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          prefixIcon: Icon(icon),
        ),
        isExpanded: true,
        items: options
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ),
            )
            .toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _loadCurrencies() async {
    final rows = await _dbHelper.getCurrencies();
    if (!mounted) {
      return;
    }
    setState(() {
      _currencies = rows;
      final exists = _currencies.any(
        (currency) => currency['code'].toString() == _selectedCurrencyCode,
      );
      if (!exists) {
        _selectedCurrencyCode = 'USD';
      }
    });
  }

  Widget _buildCurrencyDropdown() {
    final options = _currencies.isEmpty
        ? const ['USD']
        : _currencies.map((currency) => currency['code'].toString()).toList();

    final selected = options.contains(_selectedCurrencyCode)
        ? _selectedCurrencyCode
        : options.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selected,
        decoration: const InputDecoration(
          labelText: 'Currency *',
          prefixIcon: Icon(Icons.currency_exchange),
        ),
        items: options
            .map(
              (code) => DropdownMenuItem<String>(
                value: code,
                child: Text(code),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() => _selectedCurrencyCode = value);
        },
      ),
    );
  }
}
