import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';
import 'member_detail_screen.dart';

class JoinCommitteeScreen extends StatefulWidget {
  const JoinCommitteeScreen({super.key});

  @override
  State<JoinCommitteeScreen> createState() => _JoinCommitteeScreenState();
}

class _JoinCommitteeScreenState extends State<JoinCommitteeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _committeeFound = false;
  Committee? _committee;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findCommittee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _committeeFound = false;
    });

    try {
      final committeeService = context.read<CommitteeService>();
      final snapshot = await committeeService.firebase.getCommitteeByCode(
        _codeController.text.trim().toUpperCase(),
      );

      if (snapshot.docs.isEmpty) {
        setState(() => _error = 'Committee not found. Check the code.');
        return;
      }

      final committee = Committee.fromFirestore(snapshot.docs.first);
      setState(() {
        _committee = committee;
        _committeeFound = true;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinCommittee() async {
    if (_committee == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final committeeService = context.read<CommitteeService>();
      final user = authService.firebase.currentUser;
      if (user == null) return;

      // Check if already a member
      final existing = await committeeService.firebase.getMembershipByCommitteeAndUser(
        _committee!.id,
        user.uid,
      );
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already a member of this committee')),
          );
        }
        return;
      }

      // Add user to user's committee list
      await authService.addCommitteeToUser(user.uid, _committee!.id);

      // Update the membership record with userId
      // The membership was created by organizer with empty userId
      // We need to find it and update
      final membershipsSnapshot = await committeeService.getCommitteeMembersOnce(_committee!.id);
      for (final doc in membershipsSnapshot.docs) {
        final membership = Membership.fromFirestore(doc);
        if (membership.userId.isEmpty && membership.phoneNumber == PhoneUtils.formatPhoneNumber(user.phoneNumber ?? '')) {
          await committeeService.updateMembership(doc.id, {'userId': user.uid});
          break;
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MemberDetailScreen(membershipId: ''),
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
      appBar: AppBar(title: const Text('Join Committee')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.group_add,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Join a Committee',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the committee code shared by the organizer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              ComityTextField(
                controller: _codeController,
                label: 'Committee Code',
                hint: 'e.g., COM-ABC123',
                prefixIcon: Icons.vpn_key,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Committee code is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ComityButton(
                text: 'Find Committee',
                onPressed: _isLoading ? null : _findCommittee,
                isLoading: _isLoading,
                icon: Icons.search,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              if (_committeeFound && _committee != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Committee Found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _PreviewRow(label: 'Name', value: _committee!.name),
                        _PreviewRow(label: 'Monthly Amount', value: NumberUtils.formatCurrency(_committee!.monthlyAmount)),
                        _PreviewRow(label: 'Members', value: '${_committee!.totalMembers}'),
                        _PreviewRow(label: 'Duration', value: '${_committee!.totalMonths} months'),
                        _PreviewRow(label: 'Start Date', value: AppDateUtils.formatFullDate(_committee!.startDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ComityButton(
                  text: 'Join Committee',
                  onPressed: _isLoading ? null : _joinCommittee,
                  isLoading: _isLoading,
                  icon: Icons.check_circle,
                ),
              ],

              const Spacer(),
            ],
          ),
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