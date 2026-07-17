import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/investment.dart';
import '../../core/theme/app_theme.dart';

class InvestmentFormScreen extends StatefulWidget {
  final Investment? investment;

  const InvestmentFormScreen({super.key, this.investment});

  @override
  State<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _providerController;
  late TextEditingController _accountNumberController;
  late TextEditingController _valueController;
  late TextEditingController _sharesController;
  late TextEditingController _tickerController;
  late TextEditingController _onlineUrlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordHintController;
  late TextEditingController _beneficiariesController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _notesController;
  List<Map<String, dynamic>> _currencies = [];
  String _selectedCurrencyCode = 'USD';
  final Map<TextEditingController, bool> _obscureStates = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.investment?.name ?? '');
    _typeController = TextEditingController(text: widget.investment?.investmentType ?? '');
    _providerController = TextEditingController(text: widget.investment?.provider ?? '');
    _accountNumberController = TextEditingController(text: widget.investment?.accountNumber ?? '');
    _valueController = TextEditingController(text: widget.investment?.currentValue?.toString() ?? '');
    _sharesController = TextEditingController(text: widget.investment?.numberOfShares?.toString() ?? '');
    _tickerController = TextEditingController(text: widget.investment?.tickerSymbol ?? '');
    _onlineUrlController = TextEditingController(text: widget.investment?.onlineAccessUrl ?? '');
    _usernameController = TextEditingController(text: widget.investment?.username ?? '');
    _passwordHintController = TextEditingController(text: widget.investment?.passwordHint ?? '');
    _beneficiariesController = TextEditingController(text: widget.investment?.beneficiaries ?? '');
    _purchasePriceController = TextEditingController(text: widget.investment?.purchasePrice?.toString() ?? '');
    _notesController = TextEditingController(text: widget.investment?.notes ?? '');
    _selectedCurrencyCode = widget.investment?.currencyCode ?? 'USD';
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _providerController.dispose();
    _accountNumberController.dispose();
    _valueController.dispose();
    _sharesController.dispose();
    _tickerController.dispose();
    _onlineUrlController.dispose();
    _usernameController.dispose();
    _passwordHintController.dispose();
    _beneficiariesController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final investment = Investment(
        id: widget.investment?.id,
        name: _nameController.text.trim(),
        investmentType: _typeController.text.trim(),
        provider: _providerController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        currencyCode: _selectedCurrencyCode,
        currentValue: _valueController.text.trim().isEmpty ? null : double.tryParse(_valueController.text.trim()),
        numberOfShares: _sharesController.text.trim().isEmpty ? null : int.tryParse(_sharesController.text.trim()),
        tickerSymbol: _tickerController.text.trim().isEmpty ? null : _tickerController.text.trim(),
        onlineAccessUrl: _onlineUrlController.text.trim().isEmpty ? null : _onlineUrlController.text.trim(),
        username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        passwordHint: _passwordHintController.text.trim().isEmpty ? null : _passwordHintController.text.trim(),
        beneficiaries: _beneficiariesController.text.trim().isEmpty ? null : _beneficiariesController.text.trim(),
        purchasePrice: _purchasePriceController.text.trim().isEmpty ? null : double.tryParse(_purchasePriceController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.investment?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.investment == null) {
        await _dbHelper.insertInvestment(investment);
      } else {
        await _dbHelper.updateInvestment(investment);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.investment == null 
                ? 'Investment added successfully' 
                : 'Investment updated successfully'),
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
        title: Text(widget.investment == null ? 'Add Investment' : 'Edit Investment'),
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
                  label: 'Investment Name',
                  hint: 'e.g., Vanguard S&P 500',
                  icon: Icons.label_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _typeController,
                  label: 'Investment Type',
                  hint: 'e.g., Stocks, Bonds, Mutual Funds',
                  icon: Icons.category_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _providerController,
                  label: 'Provider',
                  hint: 'e.g., Vanguard, Fidelity',
                  icon: Icons.business,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  icon: Icons.numbers,
                  isRequired: true,
                  obscureText: true,
                ),
                _buildCurrencyDropdown(),
              ],
            ),
            
            _buildSection(
              'Investment Details',
              [
                _buildTextField(
                  controller: _tickerController,
                  label: 'Ticker Symbol',
                  hint: 'e.g., VFIAX',
                  icon: Icons.show_chart,
                ),
                _buildTextField(
                  controller: _sharesController,
                  label: 'Number of Shares',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _valueController,
                  label: 'Current Value',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _purchasePriceController,
                  label: 'Purchase Price',
                  hint: '0.00',
                  icon: Icons.price_check,
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
              onPressed: _isLoading ? null : _saveInvestment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.investment == null ? 'Add Investment' : 'Update Investment'),
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
