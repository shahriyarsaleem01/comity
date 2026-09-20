import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';
import 'committee_detail_screen.dart';

class CreateCommitteeScreen extends StatefulWidget {
  const CreateCommitteeScreen({super.key});

  @override
  State<CreateCommitteeScreen> createState() => _CreateCommitteeScreenState();
}

class _CreateCommitteeScreenState extends State<CreateCommitteeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _monthlyAmountController = TextEditingController();
  final _totalMembersController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyAmountController.dispose();
    _totalMembersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _createCommittee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final committeeService = context.read<CommitteeService>();
      final user = authService.firebase.currentUser;
      if (user == null) return;

      final committee = await committeeService.createCommittee(
        name: _nameController.text.trim(),
        organizerId: user.uid,
        monthlyAmount: int.parse(_monthlyAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        totalMembers: int.parse(_totalMembersController.text),
        startDate: _startDate,
      );

      await authService.addCommitteeToUser(user.uid, committee.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CommitteeDetailScreen(committeeId: committee.id),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Committee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Committee Name
            ComityTextField(
              controller: _nameController,
              label: 'Committee Name',
              hint: 'e.g., Family Committee, Friends Group',
              prefixIcon: Icons.group,
              validator: ValidationUtils.nameValidator,
            ),
            const SizedBox(height: 24),

            // Monthly Amount
            ComityTextField(
              controller: _monthlyAmountController,
              label: 'Monthly Amount (per person)',
              hint: 'e.g., 1000',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              validator: ValidationUtils.amountValidator,
            ),
            const SizedBox(height: 24),

            // Total Members
            ComityTextField(
              controller: _totalMembersController,
              label: 'Total Members',
              hint: 'e.g., 15',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.people,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Number of members is required';
                }
                final num = int.tryParse(value);
                if (num == null || num < 2 || num > 50) {
                  return 'Enter a number between 2 and 50';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Start Date
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppDateUtils.formatFullDate(_startDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Preview
            _PreviewCard(
              name: _nameController.text.isEmpty ? 'Committee Name' : _nameController.text,
              monthlyAmount: _monthlyAmountController.text.isEmpty
                  ? 0
                  : int.tryParse(_monthlyAmountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
              totalMembers: _totalMembersController.text.isEmpty
                  ? 0
                  : int.tryParse(_totalMembersController.text) ?? 0,
              startDate: _startDate,
            ),
            const SizedBox(height: 32),

            ComityButton(
              text: 'Create Committee',
              onPressed: _createCommittee,
              isLoading: _isLoading,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String name;
  final int monthlyAmount;
  final int totalMembers;
  final DateTime startDate;

  const _PreviewCard({
    required this.name,
    required this.monthlyAmount,
    required this.totalMembers,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final pot = monthlyAmount * totalMembers;

    return Card(
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            _PreviewRow(label: 'Name', value: name),
            _PreviewRow(label: 'Monthly Amount', value: NumberUtils.formatCurrency(monthlyAmount)),
            _PreviewRow(label: 'Total Members', value: '$totalMembers'),
            _PreviewRow(label: 'Monthly Pot', value: NumberUtils.formatCurrency(pot)),
            _PreviewRow(label: 'Duration', value: '$totalMembers months'),
            _PreviewRow(label: 'Start Date', value: AppDateUtils.formatFullDate(startDate)),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}