import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/investment.dart';
import '../../core/theme/app_theme.dart';
import 'investment_form_screen.dart';

class InvestmentsListScreen extends StatefulWidget {
  const InvestmentsListScreen({super.key});

  @override
  State<InvestmentsListScreen> createState() => _InvestmentsListScreenState();
}

class _InvestmentsListScreenState extends State<InvestmentsListScreen> {
  final _dbHelper = DatabaseHelper();
  List<Investment> _investments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    final investments = await _dbHelper.getAllInvestments();
    setState(() {
      _investments = investments;
      _isLoading = false;
    });
  }

  Future<void> _deleteInvestment(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text('Are you sure you want to delete "${investment.name}"?'),
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
      await _dbHelper.deleteInvestment(investment.id);
      _loadInvestments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _investments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 80,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No investments yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first investment',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInvestments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _investments.length,
                    itemBuilder: (context, index) {
                      final investment = _investments[index];
                      return _buildInvestmentCard(investment);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Investment'),
      ),
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToForm(investment: investment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          investment.provider,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(investment: investment);
                      } else if (value == 'delete') {
                        _deleteInvestment(investment);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Type', investment.investmentType),
              if (investment.tickerSymbol != null)
                _buildInfoRow('Symbol', investment.tickerSymbol!),
              if (investment.currentValue != null)
                _buildInfoRow('Value', '${investment.currencyCode} ${investment.currentValue!.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({Investment? investment}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvestmentFormScreen(investment: investment),
      ),
    );
    _loadInvestments();
  }
}
