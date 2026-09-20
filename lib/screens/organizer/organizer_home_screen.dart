import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/committee_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../utils/utils.dart';
import 'create_committee_screen.dart';
import 'committee_detail_screen.dart';

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  bool _isLoading = false;

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
            onPressed: () => _navigateToCreateCommittee(),
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
              stream: context.read<CommitteeService>().firebase.getCommitteesByOrganizer(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final committees = snapshot.data?.docs ?? [];

                if (committees.isEmpty) {
                  return EmptyState(
                    icon: Icons.group_add,
                    title: 'No Committees Yet',
                    message: 'Create your first committee to get started',
                    action: ComityButton(
                      text: 'Create Committee',
                      onPressed: _navigateToCreateCommittee,
                      icon: Icons.add,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: committees.length,
                  itemBuilder: (context, index) {
                    final committee = Committee.fromFirestore(committees[index]);
                    return _CommitteeCard(committee: committee);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateCommittee,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateCommittee() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCommitteeScreen()),
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

class _CommitteeCard extends StatelessWidget {
  final Committee committee;

  const _CommitteeCard({required this.committee});

  @override
  Widget build(BuildContext context) {
    final statusColor = CommitteeUtils.getStatusColor(committee.status);
    final statusText = CommitteeUtils.getStatusText(committee.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommitteeDetailScreen(committeeId: committee.id),
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
                  CommitteeAvatar(name: committee.name, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          committee.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: 'Members',
                      value: '${committee.totalMembers}',
                      icon: Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Monthly',
                      value: NumberUtils.formatCurrency(committee.monthlyAmount),
                      icon: Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Pot',
                      value: NumberUtils.formatCurrency(committee.monthlyPot),
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: 'Month',
                      value: '${committee.currentMonthIndex}/${committee.totalMonths}',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Started',
                      value: AppDateUtils.formatShortDate(committee.startDate),
                      icon: Icons.event,
                    ),
                  ),
                ],
              ),
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