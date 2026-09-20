import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';
import 'join_committee_screen.dart';
import 'member_detail_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.firebase.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Committees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToJoinCommittee(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: context.read<CommitteeService>().getMembershipsByUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final memberships = snapshot.data?.docs ?? [];

                if (memberships.isEmpty) {
                  return EmptyState(
                    icon: Icons.group_add,
                    title: 'No Committees Yet',
                    message: 'Join a committee using a committee code',
                    action: ComityButton(
                      text: 'Join Committee',
                      onPressed: _navigateToJoinCommittee,
                      icon: Icons.person_add,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: memberships.length,
                  itemBuilder: (context, index) {
                    final membership = Membership.fromFirestore(memberships[index]);
                    return _MembershipCard(membership: membership);
                  },
                );
              },
            ),
    );
  }

  void _navigateToJoinCommittee() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinCommitteeScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final Membership membership;

  const _MembershipCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberDetailScreen(membershipId: membership.id),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CommitteeAvatar(name: membership.displayName, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Position: #${membership.payoutPosition}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (membership.payoutReceived)
                    const Chip(
                      label: Text('Completed', style: TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: 'Monthly',
                      value: NumberUtils.formatCurrency(membership.monthlyContribution),
                      icon: Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Payout Month',
                      value: 'Month ${membership.payoutMonth}',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Paid',
                      value: '${membership.monthsPaid}/${membership.payoutMonth}',
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),
              if (membership.payoutReceived) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payout received for Month ${membership.payoutMonth}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
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
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}