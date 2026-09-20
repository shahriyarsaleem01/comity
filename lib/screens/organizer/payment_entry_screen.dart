import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';

class PaymentEntryScreen extends StatefulWidget {
  final Committee committee;
  final Membership membership;

  const PaymentEntryScreen({
    super.key,
    required this.committee,
    required this.membership,
  });

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.membership.monthlyContribution.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _markPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final committeeService = context.read<CommitteeService>();
      final authService = context.read<AuthService>();
      final user = authService.firebase.currentUser;
      if (user == null) return;

      await committeeService.markPayment(
        committeeId: widget.committee.id,
        membershipId: widget.membership.id,
        month: widget.committee.currentMonthIndex,
        amount: int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        markedBy: user.uid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment marked successfully')),
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
      appBar: AppBar(title: const Text('Mark Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Member Info
            Card(
              child: ListTile(
                leading: CommitteeAvatar(name: widget.membership.displayName, radius: 28),
                title: Text(widget.membership.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Position #${widget.membership.payoutPosition}'),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Details
            Text(
              'Month ${widget.committee.currentMonthIndex}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Expected: ${NumberUtils.formatCurrency(widget.membership.monthlyContribution)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ComityTextField(
              controller: _amountController,
              label: 'Amount Received',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              validator: ValidationUtils.amountValidator,
            ),
            const SizedBox(height: 32),

            ComityButton(
              text: 'Mark Payment',
              onPressed: _markPayment,
              isLoading: _isLoading,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }
}