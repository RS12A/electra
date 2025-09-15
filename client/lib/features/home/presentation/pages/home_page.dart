import 'package:flutter/material.dart';
import '../../models/election.dart';
import '../../widgets/election_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const ElectionsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electra'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              _showNotificationsBottomSheet(context);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Elections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Student!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to participate in democracy?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Stats
          Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Active Elections',
                  '2',
                  Icons.how_to_vote,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Your Votes',
                  '1',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Elections
          Text(
            'Recent Elections',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          _buildElectionCard(
            context,
            'Student Union President 2024',
            'Voting ends in 2 days',
            'Not voted',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          
          _buildElectionCard(
            context,
            'Faculty Representative',
            'Completed',
            'Voted',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, 
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionCard(BuildContext context, String title, String subtitle,
      String status, Color statusColor) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.how_to_vote, color: statusColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class ElectionsTab extends StatefulWidget {
  const ElectionsTab({super.key});

  @override
  State<ElectionsTab> createState() => _ElectionsTabState();
}

class _ElectionsTabState extends State<ElectionsTab> {
  List<Election> elections = [];
  bool isLoading = true;
  String? error;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  Future<void> _loadElections() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // TODO: Replace with actual API call when backend is connected
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data for demonstration
      setState(() {
        elections = [
          Election(
            id: '1',
            title: 'Student Union President Election 2024',
            description: 'Annual election for Student Union President position',
            category: 'Student Union',
            startDate: DateTime.now().add(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 7)),
            isActive: true,
            candidateCount: 3,
            hasUserVoted: false,
          ),
          Election(
            id: '2', 
            title: 'Faculty Representative Election',
            description: 'Choose your faculty representative for the academic board',
            category: 'Faculty',
            startDate: DateTime.now().add(const Duration(days: 3)),
            endDate: DateTime.now().add(const Duration(days: 10)),
            isActive: false,
            candidateCount: 2,
            hasUserVoted: false,
          ),
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load elections: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading elections...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadElections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filter: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: ['All', 'Student Union', 'Faculty', 'Club']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Elections list
        Expanded(
          child: elections.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_vote, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No elections available',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later for upcoming elections',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadElections,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: elections.length,
                    itemBuilder: (context, index) {
                      final election = elections[index];
                      return ElectionCard(
                        election: election,
                        onTap: () => _showElectionDetails(election),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showElectionDetails(Election election) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ElectionDetailsSheet(election: election),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool isLoading = false;
  
  // Mock user data - in real app, this would come from API/storage
  String userName = 'John Doe';
  String userEmail = 'john.doe@kwasu.edu.ng';
  String matricNumber = 'KWASU/2021/0123';
  String faculty = 'Engineering';
  String department = 'Computer Science';
  int yearOfStudy = 3;
  bool biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      userName.split(' ').map((e) => e[0]).join('').toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    matricNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Academic info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.school,
                    label: 'Faculty',
                    value: faculty,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.business,
                    label: 'Department',
                    value: department,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.timeline,
                    label: 'Year of Study',
                    value: '$yearOfStudy${_getOrdinalSuffix(yearOfStudy)} Year',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Settings
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Use fingerprint or face ID for secure login'),
                  trailing: Switch(
                    value: biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        biometricEnabled = value;
                      });
                      _showFeatureMessage('Biometric authentication ${value ? 'enabled' : 'disabled'}');
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage your notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeatureMessage('Notification settings'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  subtitle: const Text('Change password and security settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeatureMessage('Security settings'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help or contact support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeatureMessage('Help & support'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[600]),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  onTap: _showSignOutDialog,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App info
          Text(
            'Electra Voting System v1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'KWASU - Secure Digital Voting',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  void _showFeatureMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be implemented'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFeatureMessage('Sign out functionality');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

void _showNotificationsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications),
                  const SizedBox(width: 8),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mark all as read')),
                      );
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5, // Mock data
                itemBuilder: (context, index) {
                  final notifications = [
                    {
                      'title': 'Election Started',
                      'message': 'Student Union President Election 2024 is now open for voting.',
                      'time': '2 hours ago',
                      'isRead': false,
                      'icon': Icons.how_to_vote,
                      'color': Colors.green,
                    },
                    {
                      'title': 'New Election Created',
                      'message': 'Faculty Representative Election has been scheduled.',
                      'time': '1 day ago',
                      'isRead': true,
                      'icon': Icons.announcement,
                      'color': Colors.blue,
                    },
                    {
                      'title': 'System Maintenance',
                      'message': 'Scheduled maintenance will occur tonight at 2:00 AM.',
                      'time': '2 days ago',
                      'isRead': true,
                      'icon': Icons.build,
                      'color': Colors.orange,
                    },
                    {
                      'title': 'Profile Updated',
                      'message': 'Your profile information has been successfully updated.',
                      'time': '3 days ago',
                      'isRead': true,
                      'icon': Icons.person,
                      'color': Colors.purple,
                    },
                    {
                      'title': 'Welcome to Electra',
                      'message': 'Welcome to the KWASU digital voting system.',
                      'time': '1 week ago',
                      'isRead': true,
                      'icon': Icons.celebration,
                      'color': Colors.pink,
                    },
                  ];

                  final notification = notifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: notification['isRead'] as bool ? 1 : 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (notification['color'] as Color).withOpacity(0.1),
                        child: Icon(
                          notification['icon'] as IconData,
                          color: notification['color'] as Color,
                        ),
                      ),
                      title: Text(
                        notification['title'] as String,
                        style: TextStyle(
                          fontWeight: notification['isRead'] as bool 
                              ? FontWeight.normal 
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification['message'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opened: ${notification['title']}'),
                          ),
                        );
                      },
                      trailing: !(notification['isRead'] as bool)
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}