import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';
import 'add_member_screen.dart';
import 'payment_entry_screen.dart';

class CommitteeDetailScreen extends StatefulWidget {
  final String committeeId;

  const CommitteeDetailScreen({super.key, required this.committeeId});

  @override
  State<CommitteeDetailScreen> createState() => _CommitteeDetailScreenState();
}

class _CommitteeDetailScreenState extends State<CommitteeDetailScreen> {
  final CommitteeService _committeeService = CommitteeService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _committeeService.firebase.getCommitteeStream(widget.committeeId),
      builder: (context, committeeSnapshot) {
        if (committeeSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!committeeSnapshot.hasData || !committeeSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Committee')),
            body: const Center(child: Text('Committee not found')),
          );
        }

        final committee = Committee.fromFirestore(committeeSnapshot.data!);
        final isDraft = committee.status == 'draft';
        final isActive = committee.status == 'active';

        return Scaffold(
          appBar: AppBar(
            title: Text(committee.name),
            actions: [
              if (isDraft)
                TextButton.icon(
                  onPressed: _startCommittee,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Start', style: TextStyle(color: Colors.white)),
                )
              else if (isActive)
                TextButton.icon(
                  onPressed: _advanceMonth,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text('Next Month', style: TextStyle(color: Colors.white)),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'share') _shareCode(committee.committeeCode);
                  if (value == 'add_member') _navigateToAddMember(committee);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share Code'),
                      ],
                    ),
                  ),
                  if (isDraft)
                    const PopupMenuItem(
                      value: 'add_member',
                      child: Row(
                        children: [
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text('Add Member'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Committee Header
              _CommitteeHeader(committee: committee),
              const SizedBox(height: 16),

              // Monthly Stats
              if (isActive)
                _MonthlyStats(
                  committeeId: committee.id,
                  currentMonth: committee.currentMonthIndex,
                ),

              // Members List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _committeeService.getCommitteeMembersStream(committee.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data?.docs ?? [];

                    if (members.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const EmptyState(
                              icon: Icons.people,
                              title: 'No Members Yet',
                              message: 'Add members to start the committee',
                            ),
                            ComityButton(
                              text: 'Add Member',
                              onPressed: () => _navigateToAddMember(committee),
                              icon: Icons.person_add,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final membership = Membership.fromFirestore(members[index]);
                        return _MemberListTile(
                          membership: membership,
                          committee: committee,
                          isDraft: isDraft,
                          onTap: () => _showMemberOptions(membership, committee),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: isDraft
              ? FloatingActionButton(
                  onPressed: () => _navigateToAddMember(committee),
                  child: const Icon(Icons.person_add),
                )
              : null,
        );
      },
    );
  }

  Future<void> _startCommittee() async {
    setState(() => _isLoading = true);
    try {
      await _committeeService.startCommittee(widget.committeeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Committee started!')),
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

  Future<void> _advanceMonth() async {
    setState(() => _isLoading = true);
    try {
      await _committeeService.advanceMonth(widget.committeeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advanced to next month')),
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

  void _shareCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Committee Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this code with members to join',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddMember(Committee committee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(committee: committee),
      ),
    );
  }

  void _showMemberOptions(Membership membership, Committee committee) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MemberOptionsSheet(
        membership: membership,
        committee: committee,
      ),
    );
  }
}

class _CommitteeHeader extends StatelessWidget {
  final Committee committee;

  const _CommitteeHeader({required this.committee});

  @override
  Widget build(BuildContext context) {
    final statusColor = CommitteeUtils.getStatusColor(committee.status);
    final statusText = CommitteeUtils.getStatusText(committee.status);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CommitteeAvatar(name: committee.name, radius: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        committee.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${committee.committeeCode}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
                StatusChip(label: statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _StatItem(label: 'Members', value: '${committee.totalMembers}', icon: Icons.people)),
                Expanded(child: _StatItem(label: 'Monthly', value: NumberUtils.formatCurrency(committee.monthlyAmount), icon: Icons.attach_money)),
                Expanded(child: _StatItem(label: 'Pot', value: NumberUtils.formatCurrency(committee.monthlyPot), icon: Icons.account_balance_wallet)),
              ],
            ),
            if (committee.status == 'active') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatItem(label: 'Current Month', value: '${committee.currentMonthIndex}/${committee.totalMonths}', icon: Icons.calendar_today)),
                  Expanded(child: _StatItem(label: 'Start Date', value: AppDateUtils.formatShortDate(committee.startDate), icon: Icons.event)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

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

class _MonthlyStats extends StatelessWidget {
  final String committeeId;
  final int currentMonth;

  const _MonthlyStats({required this.committeeId, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    final committeeService = CommitteeService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month $currentMonth Collection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: committeeService.getPaymentsForMonthStream(committeeId, currentMonth),
              builder: (context, snapshot) {
                final payments = snapshot.data?.docs ?? [];
                int collected = 0;
                for (final doc in payments) {
                  collected += (doc.data() as Map<String, dynamic>)['amount'] as int? ?? 0;
                }

                return FutureBuilder<int>(
                  future: committeeService.getMonthlyPot(committeeId),
                  builder: (context, potSnapshot) {
                    final pot = potSnapshot.data ?? 0;
                    final percentage = pot > 0 ? (collected / pot * 100).clamp(0.0, 100.0) : 0.0;

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Collected', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                                AmountDisplay(amount: collected),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Target', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                                AmountDisplay(amount: pot),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppTheme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}% collected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  final Membership membership;
  final Committee committee;
  final bool isDraft;
  final VoidCallback onTap;

  const _MemberListTile({
    required this.membership,
    required this.committee,
    required this.isDraft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPaidCurrent = membership.hasPaidMonth(committee.currentMonthIndex);
    final isPayoutMonth = membership.payoutMonth == committee.currentMonthIndex;
    final isCompleted = membership.payoutReceived;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CommitteeAvatar(name: membership.displayName, radius: 24),
        title: Row(
          children: [
            Expanded(
              child: Text(
                membership.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (membership.isOrganizer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Organizer',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Position #${membership.payoutPosition}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.attach_money,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${NumberUtils.formatCurrency(membership.monthlyContribution)}/month',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            if (committee.status == 'active') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    hasPaidCurrent ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: hasPaidCurrent ? AppTheme.primaryColor : AppTheme.errorColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasPaidCurrent ? 'Paid this month' : 'Not paid this month',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPaidCurrent ? AppTheme.primaryColor : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: isDraft
            ? null
            : isPayoutMonth && !isCompleted
                ? Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'PAYOUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : isCompleted
                    ? Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'RECEIVED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : null,
      ),
    );
  }
}

class _MemberOptionsSheet extends StatelessWidget {
  final Membership membership;
  final Committee committee;

  const _MemberOptionsSheet({
    required this.membership,
    required this.committee,
  });

  @override
  Widget build(BuildContext context) {
    final committeeService = CommitteeService();
    final isActive = committee.status == 'active';
    final hasPaidCurrent = membership.hasPaidMonth(committee.currentMonthIndex);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            membership.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Position #${membership.payoutPosition} • ${NumberUtils.formatCurrency(membership.monthlyContribution)}/month',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          if (isActive) ...[
            if (!hasPaidCurrent)
              ListTile(
                leading: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                title: const Text('Mark Payment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentEntryScreen(
                        committee: committee,
                        membership: membership,
                      ),
                    ),
                  );
                },
              ),
            if (hasPaidCurrent)
              ListTile(
                leading: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                title: const Text('Unmark Payment'),
                onTap: () async {
                  Navigator.pop(context);
                  await committeeService.unmarkPayment(
                    membershipId: membership.id,
                    month: committee.currentMonthIndex,
                  );
                },
              ),
            if (membership.payoutMonth == committee.currentMonthIndex && !membership.payoutReceived)
              ListTile(
                leading: const Icon(Icons.payment, color: AppTheme.accentColor),
                title: const Text('Mark Payout Received'),
                onTap: () async {
                  Navigator.pop(context);
                  await committeeService.markPayoutReceived(membership.id);
                },
              ),
          ],
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Member'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Edit member screen
            },
          ),
        ],
      ),
    );
  }
}