import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';

class MemberDetailScreen extends StatefulWidget {
  final String membershipId;

  const MemberDetailScreen({super.key, required this.membershipId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final CommitteeService _committeeService = CommitteeService();
  String? _currentMembershipId;

  @override
  void initState() {
    super.initState();
    _currentMembershipId = widget.membershipId;
    _resolveMembershipId();
  }

  Future<void> _resolveMembershipId() async {
    if (_currentMembershipId != null && _currentMembershipId!.isNotEmpty) return;

    final authService = context.read<AuthService>();
    final user = authService.firebase.currentUser;
    if (user == null) return;

    final snapshot = await _committeeService.getMembershipsByUserOnce(user.uid);
    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() => _currentMembershipId = snapshot.docs.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMembershipId == null || _currentMembershipId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Committee')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _committeeService.firebase.getMembershipStream(_currentMembershipId!),
      builder: (context, membershipSnapshot) {
        if (membershipSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!membershipSnapshot.hasData || !membershipSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Committee')),
            body: const Center(child: Text('Committee not found')),
          );
        }

        final membership = Membership.fromFirestore(membershipSnapshot.data!);

        return StreamBuilder<DocumentSnapshot>(
          stream: _committeeService.firebase.getCommitteeStream(membership.committeeId),
          builder: (context, committeeSnapshot) {
            if (committeeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!committeeSnapshot.hasData || !committeeSnapshot.data!.exists) {
              return Scaffold(
                appBar: AppBar(title: const Text('My Committee')),
                body: const Center(child: Text('Committee not found')),
              );
            }

            final committee = Committee.fromFirestore(committeeSnapshot.data!);

            return _MemberDetailContent(
              membership: membership,
              committee: committee,
            );
          },
        );
      },
    );
  }
}

class _MemberDetailContent extends StatelessWidget {
  final Membership membership;
  final Committee committee;

  const _MemberDetailContent({
    required this.membership,
    required this.committee,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    // Header Card
    children.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CommitteeAvatar(name: committee.name, radius: 40),
              const SizedBox(height: 16),
              Text(
                committee.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Code: ${committee.committeeCode}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(height: 16),
              StatusChip(
                label: CommitteeUtils.getStatusText(committee.status),
                color: CommitteeUtils.getStatusColor(committee.status),
              ),
            ],
          ),
        ),
      ));

    // Spacer
    children.add(const SizedBox(height: 24));

    // My Position Card
    children.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Position',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PositionItem(
                      label: 'Payout Position',
                      value: '#${membership.payoutPosition}',
                      icon: Icons.confirmation_number,
                    ),
                  ),
                  Expanded(
                    child: _PositionItem(
                      label: 'Payout Month',
                      value: 'Month ${membership.payoutMonth}',
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPayoutStatusWidget(context),
            ],
          ),
        ),
      ));

    // Spacer
    children.add(const SizedBox(height: 24));

    // Payment Progress
    children.add(_buildPaymentProgressCard(context));

    // Payment History
    children.add(
      _PaymentHistorySection(
        membershipId: membership.id,
        committee: committee,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(committee.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildPayoutCompleted(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout Completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                Text(
                  'You received your payout for Month ${membership.payoutMonth}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutMonthActive(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: AppTheme.accentColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Payout Month!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                ),
                Text(
                  'Contact organizer to receive your payout',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutStatusWidget(BuildContext context) {
    final isCompleted = committee.status == 'completed';
    final isActive = committee.status == 'active';
    final isPayoutMonth = membership.payoutMonth == committee.currentMonthIndex;

    if (isCompleted && membership.payoutReceived) {
      return _buildPayoutCompleted(context);
    } else if (isActive && isPayoutMonth && !membership.payoutReceived) {
      return _buildPayoutMonthActive(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPaymentProgressCard(BuildContext context) {
    final isActive = committee.status == 'active';
    final isCompleted = committee.status == 'completed';

    if (!isActive && !isCompleted) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Months Paid: ${membership.monthsPaid} / ${membership.payoutMonth}'),
                Text(
                  '${((membership.monthsPaid / membership.payoutMonth) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: membership.payoutMonth > 0 ? membership.monthsPaid / membership.payoutMonth : 0,
              backgroundColor: AppTheme.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PositionItem(
                    label: 'Monthly Payment',
                    value: NumberUtils.formatCurrency(membership.monthlyContribution),
                    icon: Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _PositionItem(
                    label: 'Total Paid',
                    value: NumberUtils.formatCurrency(membership.monthlyContribution * membership.monthsPaid),
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PositionItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.primaryColor),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _PaymentHistorySection extends StatelessWidget {
  final String membershipId;
  final Committee committee;

  const _PaymentHistorySection({
    required this.membershipId,
    required this.committee,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: CommitteeService().firebase.getPaymentsByMembership(membershipId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data?.docs ?? [];

            if (payments.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No payments recorded yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              );
            }

            payments.sort((a, b) => ((a.data() as Map<String, dynamic>)['month'] as int)
                .compareTo((b.data() as Map<String, dynamic>)['month'] as int));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = Payment.fromFirestore(payments[index]);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        'M${payment.month}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text('Month ${payment.month}'),
                    subtitle: Text(AppDateUtils.formatShortDate(payment.datePaid)),
                    trailing: AmountDisplay(amount: payment.amount, style: const TextStyle(fontSize: 14)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}