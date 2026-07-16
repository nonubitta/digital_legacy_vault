import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/retirement_account.dart';
import '../../core/theme/app_theme.dart';

class RetirementFormScreen extends StatefulWidget {
  final RetirementAccount? account;

  const RetirementFormScreen({super.key, this.account});

  @override
  State<RetirementFormScreen> createState() => _RetirementFormScreenState();
}

class _RetirementFormScreenState extends State<RetirementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  
  late TextEditingController _nameController;
  late TextEditingController _accountTypeController;
  late TextEditingController _providerController;
  late TextEditingController _accountNumberController;
  late TextEditingController _balanceController;
  late TextEditingController _employerController;
  late TextEditingController _onlineUrlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordHintController;
  late TextEditingController _beneficiariesController;
  late TextEditingController _employerMatchController;
  late TextEditingController _notesController;
  List<Map<String, dynamic>> _currencies = [];
  String _selectedCurrencyCode = 'USD';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _accountTypeController = TextEditingController(text: widget.account?.accountType ?? '');
    _providerController = TextEditingController(text: widget.account?.provider ?? '');
    _accountNumberController = TextEditingController(text: widget.account?.accountNumber ?? '');
    _balanceController = TextEditingController(text: widget.account?.currentBalance?.toString() ?? '');
    _employerController = TextEditingController(text: widget.account?.employerName ?? '');
    _onlineUrlController = TextEditingController(text: widget.account?.onlineAccessUrl ?? '');
    _usernameController = TextEditingController(text: widget.account?.username ?? '');
    _passwordHintController = TextEditingController(text: widget.account?.passwordHint ?? '');
    _beneficiariesController = TextEditingController(text: widget.account?.beneficiaries ?? '');
    _employerMatchController = TextEditingController(text: widget.account?.employerMatch?.toString() ?? '');
    _notesController = TextEditingController(text: widget.account?.notes ?? '');
    _selectedCurrencyCode = widget.account?.currencyCode ?? 'USD';
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountTypeController.dispose();
    _providerController.dispose();
    _accountNumberController.dispose();
    _balanceController.dispose();
    _employerController.dispose();
    _onlineUrlController.dispose();
    _usernameController.dispose();
    _passwordHintController.dispose();
    _beneficiariesController.dispose();
    _employerMatchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final account = RetirementAccount(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        accountType: _accountTypeController.text.trim(),
        provider: _providerController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        currencyCode: _selectedCurrencyCode,
        currentBalance: _balanceController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_balanceController.text.trim()),
        employerName: _employerController.text.trim().isEmpty ? null : _employerController.text.trim(),
        onlineAccessUrl: _onlineUrlController.text.trim().isEmpty ? null : _onlineUrlController.text.trim(),
        username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        passwordHint: _passwordHintController.text.trim().isEmpty ? null : _passwordHintController.text.trim(),
        beneficiaries: _beneficiariesController.text.trim().isEmpty ? null : _beneficiariesController.text.trim(),
        employerMatch: _employerMatchController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_employerMatchController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.account?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.account == null) {
        await _dbHelper.insertRetirementAccount(account);
      } else {
        await _dbHelper.updateRetirementAccount(account);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.account == null 
                ? 'Retirement account added successfully' 
                : 'Retirement account updated successfully'),
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
        title: Text(widget.account == null ? 'Add Retirement Account' : 'Edit Retirement Account'),
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
                  hint: 'e.g., My 401k',
                  icon: Icons.label_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _accountTypeController,
                  label: 'Account Type',
                  hint: 'e.g., 401k, Roth IRA, Traditional IRA',
                  icon: Icons.category_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _providerController,
                  label: 'Provider',
                  hint: 'e.g., Fidelity, Vanguard',
                  icon: Icons.business,
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
                  icon: Icons.numbers,
                  isRequired: true,
                  obscureText: true,
                ),
                _buildCurrencyDropdown(),
                _buildTextField(
                  controller: _balanceController,
                  label: 'Current Balance',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _employerController,
                  label: 'Employer Name',
                  icon: Icons.work_outlined,
                ),
                _buildTextField(
                  controller: _employerMatchController,
                  label: 'Employer Match (%)',
                  icon: Icons.percent,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            
            _buildSection(
              'Online Access',
              [
                _buildTextField(
                  controller: _onlineUrlController,
                  label: 'Online Access URL',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: obscureText 
              ? Icon(Icons.visibility_off_outlined, color: AppTheme.textSecondary)
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
