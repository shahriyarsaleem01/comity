import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';

class AddMemberScreen extends StatefulWidget {
  final Committee committee;

  const AddMemberScreen({super.key, required this.committee});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _monthlyContributionController = TextEditingController();
  int _payoutPosition = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _monthlyContributionController.text = widget.committee.monthlyAmount.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _monthlyContributionController.dispose();
    super.dispose();
  }

  int _getNextAvailablePosition() {
    // This would need to check existing members - for now return 1
    return widget.committee.totalMembers;
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final committeeService = context.read<CommitteeService>();
      await committeeService.addMember(
        committeeId: widget.committee.id,
        userId: '', // Will be filled when member joins via code
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        monthlyContribution: int.parse(_monthlyContributionController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        payoutPosition: _payoutPosition,
        isOrganizer: false,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
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
    final existingPositions = <int>[]; // Would need to fetch from stream
    final availablePositions = List.generate(
      widget.committee.totalMembers,
      (i) => i + 1,
    ).where((p) => !existingPositions.contains(p)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Add Member to ${widget.committee.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter member details. They will join using the committee code.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            ComityTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter member name',
              prefixIcon: Icons.person,
              validator: ValidationUtils.nameValidator,
            ),
            const SizedBox(height: 16),

            ComityTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '03XX XXXXXXX',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
              validator: ValidationUtils.phoneValidator,
            ),
            const SizedBox(height: 16),

            ComityTextField(
              controller: _monthlyContributionController,
              label: 'Monthly Contribution',
              hint: 'e.g., 1000',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              validator: ValidationUtils.amountValidator,
            ),
            const SizedBox(height: 16),

            // Payout Position Dropdown
            DropdownButtonFormField<int>(
              value: availablePositions.contains(_payoutPosition) ? _payoutPosition : (availablePositions.isNotEmpty ? availablePositions.first : 1),
              decoration: InputDecoration(
                labelText: 'Payout Position',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: availablePositions.map((pos) {
                return DropdownMenuItem(
                  value: pos,
                  child: Text('Position $pos (Month $pos)'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _payoutPosition = value);
              },
            ),
            const SizedBox(height: 32),

            ComityButton(
              text: 'Add Member',
              onPressed: _addMember,
              isLoading: _isLoading,
              icon: Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }
}