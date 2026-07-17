import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/vehicle.dart';
import '../../core/theme/app_theme.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _vinController;
  late TextEditingController _licensePlateController;
  late TextEditingController _colorController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _currentValueController;
  late TextEditingController _titleLocationController;
  late TextEditingController _registrationController;
  late TextEditingController _insuranceProviderController;
  late TextEditingController _insurancePolicyController;
  late TextEditingController _loanProviderController;
  late TextEditingController _loanAccountController;
  late TextEditingController _loanBalanceController;
  late TextEditingController _notesController;
  List<Map<String, dynamic>> _currencies = [];
  String _selectedCurrencyCode = 'USD';
  final Map<TextEditingController, bool> _obscureStates = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _typeController = TextEditingController(text: widget.vehicle?.vehicleType ?? '');
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(text: widget.vehicle?.year.toString() ?? '');
    _vinController = TextEditingController(text: widget.vehicle?.vin ?? '');
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _colorController = TextEditingController(text: widget.vehicle?.color ?? '');
    _purchasePriceController = TextEditingController(text: widget.vehicle?.purchasePrice?.toString() ?? '');
    _currentValueController = TextEditingController(text: widget.vehicle?.currentValue?.toString() ?? '');
    _titleLocationController = TextEditingController(text: widget.vehicle?.titleLocation ?? '');
    _registrationController = TextEditingController(text: widget.vehicle?.registrationInfo ?? '');
    _insuranceProviderController = TextEditingController(text: widget.vehicle?.insuranceProvider ?? '');
    _insurancePolicyController = TextEditingController(text: widget.vehicle?.insurancePolicyNumber ?? '');
    _loanProviderController = TextEditingController(text: widget.vehicle?.loanProvider ?? '');
    _loanAccountController = TextEditingController(text: widget.vehicle?.loanAccountNumber ?? '');
    _loanBalanceController = TextEditingController(text: widget.vehicle?.loanBalance?.toString() ?? '');
    _notesController = TextEditingController(text: widget.vehicle?.notes ?? '');
    _selectedCurrencyCode = widget.vehicle?.currencyCode ?? 'USD';
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _vinController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _titleLocationController.dispose();
    _registrationController.dispose();
    _insuranceProviderController.dispose();
    _insurancePolicyController.dispose();
    _loanProviderController.dispose();
    _loanAccountController.dispose();
    _loanBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        name: _nameController.text.trim(),
        vehicleType: _typeController.text.trim(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        currencyCode: _selectedCurrencyCode,
        vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
        licensePlate: _licensePlateController.text.trim().isEmpty ? null : _licensePlateController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        purchasePrice: _purchasePriceController.text.trim().isEmpty ? null : double.tryParse(_purchasePriceController.text.trim()),
        currentValue: _currentValueController.text.trim().isEmpty ? null : double.tryParse(_currentValueController.text.trim()),
        titleLocation: _titleLocationController.text.trim().isEmpty ? null : _titleLocationController.text.trim(),
        registrationInfo: _registrationController.text.trim().isEmpty ? null : _registrationController.text.trim(),
        insuranceProvider: _insuranceProviderController.text.trim().isEmpty ? null : _insuranceProviderController.text.trim(),
        insurancePolicyNumber: _insurancePolicyController.text.trim().isEmpty ? null : _insurancePolicyController.text.trim(),
        loanProvider: _loanProviderController.text.trim().isEmpty ? null : _loanProviderController.text.trim(),
        loanAccountNumber: _loanAccountController.text.trim().isEmpty ? null : _loanAccountController.text.trim(),
        loanBalance: _loanBalanceController.text.trim().isEmpty ? null : double.tryParse(_loanBalanceController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.vehicle?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.vehicle == null) {
        await _dbHelper.insertVehicle(vehicle);
      } else {
        await _dbHelper.updateVehicle(vehicle);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle == null 
                ? 'Vehicle added successfully' 
                : 'Vehicle updated successfully'),
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
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
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
                  label: 'Vehicle Name',
                  hint: 'e.g., My Car',
                  icon: Icons.label_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _typeController,
                  label: 'Vehicle Type',
                  hint: 'e.g., Car, Motorcycle, Boat',
                  icon: Icons.category_outlined,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _makeController,
                  label: 'Make',
                  hint: 'e.g., Toyota, Honda',
                  icon: Icons.business,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _modelController,
                  label: 'Model',
                  hint: 'e.g., Camry, Accord',
                  icon: Icons.directions_car,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _yearController,
                  label: 'Year',
                  hint: 'e.g., 2020',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ],
            ),
            
            _buildSection(
              'Vehicle Details',
              [
                _buildTextField(
                  controller: _vinController,
                  label: 'VIN',
                  icon: Icons.numbers,
                  obscureText: true,
                ),
                _buildTextField(
                  controller: _licensePlateController,
                  label: 'License Plate',
                  icon: Icons.credit_card,
                ),
                _buildTextField(
                  controller: _colorController,
                  label: 'Color',
                  icon: Icons.palette_outlined,
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
                  controller: _titleLocationController,
                  label: 'Title Location',
                  hint: 'Where the title is stored',
                  icon: Icons.description_outlined,
                ),
                _buildTextField(
                  controller: _registrationController,
                  label: 'Registration Information',
                  icon: Icons.app_registration,
                  maxLines: 2,
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
              'Loan',
              [
                _buildTextField(
                  controller: _loanProviderController,
                  label: 'Loan Provider',
                  icon: Icons.account_balance,
                ),
                _buildTextField(
                  controller: _loanAccountController,
                  label: 'Loan Account Number',
                  icon: Icons.numbers,
                  obscureText: true,
                ),
                _buildTextField(
                  controller: _loanBalanceController,
                  label: 'Loan Balance',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
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
              onPressed: _isLoading ? null : _saveVehicle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.vehicle == null ? 'Add Vehicle' : 'Update Vehicle'),
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
                if (label == 'Year') {
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                    return 'Please enter a valid year';
                  }
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
