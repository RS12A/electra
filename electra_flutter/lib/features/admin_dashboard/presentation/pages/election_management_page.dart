import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Election management page for creating and managing elections
///
/// Allows administrators to create, edit, and manage elections
/// with candidate management and voting period configuration.
class ElectionManagementPage extends ConsumerStatefulWidget {
  const ElectionManagementPage({super.key});

  @override
  ConsumerState<ElectionManagementPage> createState() =>
      _ElectionManagementPageState();
}

class _ElectionManagementPageState
    extends ConsumerState<ElectionManagementPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateElectionDialog,
            tooltip: 'Create New Election',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildElectionsList(theme),
    );
  }

  Widget _buildElectionsList(ThemeData theme) {
    // Mock elections data
    final elections = [
      {
        'title': 'Student Union Executive Elections 2024',
        'status': 'Active',
        'startDate': '2024-03-10',
        'endDate': '2024-03-17',
        'totalVotes': 1856,
        'eligibleVoters': 3245,
      },
      {
        'title': 'Faculty Representative Elections',
        'status': 'Pending',
        'startDate': '2024-03-20',
        'endDate': '2024-03-27',
        'totalVotes': 0,
        'eligibleVoters': 2180,
      },
      {
        'title': 'Course Representative Elections',
        'status': 'Completed',
        'startDate': '2024-02-15',
        'endDate': '2024-02-22',
        'totalVotes': 4321,
        'eligibleVoters': 5420,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: elections.length,
      itemBuilder: (context, index) {
        final election = elections[index];
        return _buildElectionCard(election, theme);
      },
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election, ThemeData theme) {
    final status = election['status'] as String;
    final statusColor = status == 'Active'
        ? KWASUColors.success
        : status == 'Pending'
        ? KWASUColors.warning
        : KWASUColors.info;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    election['title'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${election['startDate']} - ${election['endDate']}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${election['totalVotes']} / ${election['eligibleVoters']} votes',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewElectionDetails(election),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editElection(election),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateElectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Election'),
        content: const Text(
          'Election creation functionality will be implemented with full form handling.',
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

  void _viewElectionDetails(Map<String, dynamic> election) {
    // TODO: Navigate to election details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for ${election['title']}')),
    );
  }

  void _editElection(Map<String, dynamic> election) {
    // TODO: Navigate to election edit page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editing ${election['title']}')));
  }

  Future<void> _loadElections() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
