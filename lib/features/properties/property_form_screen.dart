import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/property.dart';
import '../../core/theme/app_theme.dart';

class PropertyFormScreen extends StatefulWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _currentValueController;
  late TextEditingController _deedLocationController;
  late TextEditingController _mortgageProviderController;
  late TextEditingController _mortgageAccountController;
  late TextEditingController _mortgageBalanceController;
  late TextEditingController _propertyTaxController;
  late TextEditingController _insuranceProviderController;
  late TextEditingController _insurancePolicyController;
  late TextEditingController _notesController;
  List<Map<String, dynamic>> _currencies = [];
  String _selectedCurrencyCode = 'USD';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property?.name ?? '');
    _typeController = TextEditingController(text: widget.property?.propertyType ?? '');
    _addressController = TextEditingController(text: widget.property?.address ?? '');
    _cityController = TextEditingController(text: widget.property?.city ?? '');
    _stateController = TextEditingController(text: widget.property?.state ?? '');
    _zipCodeController = TextEditingController(text: widget.property?.zipCode ?? '');
    _countryController = TextEditingController(text: widget.property?.country ?? '');
    _purchasePriceController = TextEditingController(text: widget.property?.purchasePrice?.toString() ?? '');
    _currentValueController = TextEditingController(text: widget.property?.currentValue?.toString() ?? '');
    _deedLocationController = TextEditingController(text: widget.property?.deedLocation ?? '');
    _mortgageProviderController = TextEditingController(text: widget.property?.mortgageProvider ?? '');
    _mortgageAccountController = TextEditingController(text: widget.property?.mortgageAccountNumber ?? '');
    _mortgageBalanceController = TextEditingController(text: widget.property?.mortgageBalance?.toString() ?? '');
    _propertyTaxController = TextEditingController(text: widget.property?.propertyTaxInfo ?? '');
    _insuranceProviderController = TextEditingController(text: widget.property?.insuranceProvider ?? '');
    _insurancePolicyController = TextEditingController(text: widget.property?.insurancePolicyNumber ?? '');
    _notesController = TextEditingController(text: widget.property?.notes ?? '');
    _selectedCurrencyCode = widget.property?.currencyCode ?? 'USD';
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _deedLocationController.dispose();
    _mortgageProviderController.dispose();
    _mortgageAccountController.dispose();
    _mortgageBalanceController.dispose();
    _propertyTaxController.dispose();
    _insuranceProviderController.dispose();
    _insurancePolicyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final property = Property(
        id: widget.property?.id,
        name: _nameController.text.trim(),
        propertyType: _typeController.text.trim(),
        address: _addressController.text.trim(),
        currencyCode: _selectedCurrencyCode,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        purchasePrice: _purchasePriceController.text.trim().isEmpty ? null : double.tryParse(_purchasePriceController.text.trim()),
        currentValue: _currentValueController.text.trim().isEmpty ? null : double.tryParse(_currentValueController.text.trim()),
        deedLocation: _deedLocationController.text.trim().isEmpty ? null : _deedLocationController.text.trim(),
        mortgageProvider: _mortgageProviderController.text.trim().isEmpty ? null : _mortgageProviderController.text.trim(),
        mortgageAccountNumber: _mortgageAccountController.text.trim().isEmpty ? null : _mortgageAccountController.text.trim(),
        mortgageBalance: _mortgageBalanceController.text.trim().isEmpty ? null : double.tryParse(_mortgageBalanceController.text.trim()),
        propertyTaxInfo: _propertyTaxController.text.trim().isEmpty ? null : _propertyTaxController.text.trim(),
        insuranceProvider: _insuranceProviderController.text.trim().isEmpty ? null : _insuranceProviderController.text.trim(),
        insurancePolicyNumber: _insurancePolicyController.text.trim().isEmpty ? null : _insurancePolicyController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.property?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.property == null) {
        await _dbHelper.insertProperty(property);
      } else {
        await _dbHelper.updateProperty(property);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.property == null 
                ? 'Property added successfully' 
                : 'Property updated successfully'),
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
        title: Text(widget.property == null ? 'Add Property' : 'Edit Property'),
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
                  label: 'Property Name',
                  hint: 'e.g., Main Residence',
                  icon: Icons.label_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _typeController,
                  label: 'Property Type',
                  hint: 'e.g., House, Apartment, Land',
                  icon: Icons.category_outlined,
                  isRequired: true,
                ),
              ],
            ),
            
            _buildSection(
              'Location',
              [
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city,
                ),
                _buildTextField(
                  controller: _stateController,
                  label: 'State/Province',
                  icon: Icons.map_outlined,
                ),
                _buildTextField(
                  controller: _zipCodeController,
                  label: 'Zip Code',
                  icon: Icons.markunread_mailbox,
                ),
                _buildTextField(
                  controller: _countryController,
                  label: 'Country',
                  icon: Icons.public,
                ),
              ],
            ),
            
            _buildSection(
              'Financial Details',
              [
                _buildCurrencyDropdown(),
                _buildTextField(
                  controller: _purchasePriceController,
                  label: 'Purchase Price',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _currentValueController,
                  label: 'Current Value',
                  hint: '0.00',
                  icon: Icons.price_check,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            
            _buildSection(
              'Documentation',
              [
                _buildTextField(
                  controller: _deedLocationController,
                  label: 'Deed Location',
                  hint: 'Where the deed is stored',
                  icon: Icons.description_outlined,
                ),
                _buildTextField(
                  controller: _propertyTaxController,
                  label: 'Property Tax Information',
                  icon: Icons.receipt_long,
                  maxLines: 2,
                ),
              ],
            ),
            
            _buildSection(
              'Mortgage',
              [
                _buildTextField(
                  controller: _mortgageProviderController,
                  label: 'Mortgage Provider',
                  icon: Icons.business,
                ),
                _buildTextField(
                  controller: _mortgageAccountController,
                  label: 'Mortgage Account Number',
                  icon: Icons.numbers,
                  obscureText: true,
                ),
                _buildTextField(
                  controller: _mortgageBalanceController,
                  label: 'Mortgage Balance',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            
            _buildSection(
              'Insurance',
              [
                _buildTextField(
                  controller: _insuranceProviderController,
                  label: 'Insurance Provider',
                  icon: Icons.shield_outlined,
                ),
                _buildTextField(
                  controller: _insurancePolicyController,
                  label: 'Policy Number',
                  icon: Icons.policy_outlined,
                  obscureText: true,
                ),
              ],
            ),
            
            _buildSection(
              'Additional Information',
              [
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
              onPressed: _isLoading ? null : _saveProperty,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.property == null ? 'Add Property' : 'Update Property'),
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
