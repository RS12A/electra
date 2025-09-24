import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:electra_flutter/main.dart' as app;
import 'package:electra_flutter/core/offline/models/queue_item.dart';
import 'package:electra_flutter/core/offline/models/sync_config.dart';
import 'package:electra_flutter/core/offline/providers/offline_providers.dart';
import 'package:electra_flutter/core/offline/widgets/offline_status_indicator.dart';
import 'package:electra_flutter/core/offline/widgets/sync_control_widget.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Sync Integration Tests', () {
    testWidgets('Complete offline to online sync workflow', (tester) async {
      // Initialize the app
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TestOfflineScreen(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Test 1: Initial offline state
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byType(OfflineStatusIndicator), findsOneWidget);

      // Test 2: Queue an operation while offline
      await tester.tap(find.text('Queue Vote'));
      await tester.pumpAndSettle();

      // Verify operation was queued
      expect(find.text('1'), findsOneWidget); // Pending items badge
      expect(find.text('Pending'), findsOneWidget);

      // Test 3: Simulate network connection
      await tester.tap(find.text('Simulate Online'));
      await tester.pumpAndSettle();

      // Verify online state
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);

      // Test 4: Trigger manual sync
      await tester.tap(find.text('Sync Now'));
      await tester.pumpAndSettle();

      // Verify sync started
      expect(find.text('Syncing'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Wait for sync to complete (with timeout)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Test 5: Verify sync completion
      expect(find.text('All Synced'), findsOneWidget);
      expect(find.text('No pending operations'), findsOneWidget);

      // Test 6: Test conflict resolution
      await tester.tap(find.text('Queue Duplicate Vote'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync Now'));
      await tester.pumpAndSettle();

      // Wait for sync to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify conflict was handled (vote should be rejected)
      expect(find.textContaining('rejected'), findsOneWidget);
    });

    testWidgets('Network quality affects sync behavior', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TestNetworkQualityScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test poor network quality blocks sync
      await tester.tap(find.text('Poor Quality'));
      await tester.pumpAndSettle();

      expect(find.text('Poor Signal'), findsOneWidget);
      expect(find.text('Sync Now'), findsNothing);

      // Test good quality enables sync
      await tester.tap(find.text('Good Quality'));
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
    });

    testWidgets('Batch processing handles multiple operations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TestBatchSyncScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Queue multiple operations
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Queue Operation'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget); // Pending count

      // Start sync
      await tester.tap(find.text('Simulate Online'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync Now'));
      await tester.pumpAndSettle();

      // Monitor batch progress
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify all operations synced
      expect(find.text('All Synced'), findsOneWidget);
    });

    testWidgets('Retry mechanism handles failures', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TestRetryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Queue operation that will fail
      await tester.tap(find.text('Queue Failing Operation'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simulate Online'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync Now'));
      await tester.pumpAndSettle();

      // Wait for initial failure
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify retry is scheduled
      expect(find.textContaining('retry'), findsOneWidget);

      // Simulate server fix and retry
      await tester.tap(find.text('Fix Server'));
      await tester.pumpAndSettle();

      // Wait for automatic retry
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      // Verify successful retry
      expect(find.text('All Synced'), findsOneWidget);
    });
  });
}

/// Test screen for offline sync workflow
class TestOfflineScreen extends ConsumerStatefulWidget {
  const TestOfflineScreen({super.key});

  @override
  ConsumerState<TestOfflineScreen> createState() => _TestOfflineScreenState();
}

class _TestOfflineScreenState extends ConsumerState<TestOfflineScreen> {
  bool _isOnline = false;
  bool _duplicateVote = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Test'),
        actions: [
          CompactOfflineStatusIndicator(
            onTap: () {
              // Show detailed status
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineStatusIndicator(showDetails: true),
          const SizedBox(height: 20),
          const SyncControlWidget(showAdvancedControls: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final queueOperations = ref.read(offlineQueueProvider);
              await queueOperations.queueVote(
                electionId: 'test-election',
                selections: {'president': 'candidate-1'},
                ballotToken: _duplicateVote ? 'duplicate-token' : 'unique-token',
                userId: 'test-user',
              );
            },
            child: Text(_duplicateVote ? 'Queue Duplicate Vote' : 'Queue Vote'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isOnline = !_isOnline;
              });
              _simulateNetworkChange();
            },
            child: Text(_isOnline ? 'Simulate Offline' : 'Simulate Online'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _duplicateVote = !_duplicateVote;
              });
            },
            child: Text(_duplicateVote ? 'Unique Vote' : 'Duplicate Vote'),
          ),
        ],
      ),
    );
  }

  void _simulateNetworkChange() {
    // This would integrate with a mock network service
    // For the test, we'll update the network status directly
    final networkStatus = NetworkStatus(
      isConnected: _isOnline,
      connectionType: _isOnline ? 'wifi' : 'none',
      quality: _isOnline ? NetworkQuality.good : NetworkQuality.offline,
      lastUpdated: DateTime.now(),
      syncRecommended: _isOnline,
    );

    // Update network status in the provider
    // This would normally be handled by the NetworkMonitorService
  }
}

/// Test screen for network quality scenarios
class TestNetworkQualityScreen extends ConsumerStatefulWidget {
  const TestNetworkQualityScreen({super.key});

  @override
  ConsumerState<TestNetworkQualityScreen> createState() => _TestNetworkQualityScreenState();
}

class _TestNetworkQualityScreenState extends ConsumerState<TestNetworkQualityScreen> {
  NetworkQuality _quality = NetworkQuality.offline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Quality Test')),
      body: Column(
        children: [
          const OfflineStatusIndicator(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _setQuality(NetworkQuality.poor),
                child: const Text('Poor Quality'),
              ),
              ElevatedButton(
                onPressed: () => _setQuality(NetworkQuality.good),
                child: const Text('Good Quality'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SyncControlWidget(),
        ],
      ),
    );
  }

  void _setQuality(NetworkQuality quality) {
    setState(() {
      _quality = quality;
    });
    // Update network status with new quality
  }
}

/// Test screen for batch sync scenarios
class TestBatchSyncScreen extends ConsumerStatefulWidget {
  const TestBatchSyncScreen({super.key});

  @override
  ConsumerState<TestBatchSyncScreen> createState() => _TestBatchSyncScreenState();
}

class _TestBatchSyncScreenState extends ConsumerState<TestBatchSyncScreen> {
  bool _isOnline = false;
  int _operationCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Sync Test')),
      body: Column(
        children: [
          const OfflineStatusIndicator(),
          const SizedBox(height: 20),
          Text('Operations Queued: $_operationCount'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final queueOperations = ref.read(offlineQueueProvider);
              await queueOperations.queueNotificationAck(
                notificationId: 'notification-${_operationCount + 1}',
                userId: 'test-user',
              );
              setState(() {
                _operationCount++;
              });
            },
            child: const Text('Queue Operation'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isOnline = !_isOnline;
              });
            },
            child: Text(_isOnline ? 'Simulate Offline' : 'Simulate Online'),
          ),
          const SizedBox(height: 20),
          const SyncControlWidget(),
        ],
      ),
    );
  }
}

/// Test screen for retry mechanism scenarios
class TestRetryScreen extends ConsumerStatefulWidget {
  const TestRetryScreen({super.key});

  @override
  ConsumerState<TestRetryScreen> createState() => _TestRetryScreenState();
}

class _TestRetryScreenState extends ConsumerState<TestRetryScreen> {
  bool _serverFixed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retry Test')),
      body: Column(
        children: [
          const OfflineStatusIndicator(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final queueOperations = ref.read(offlineQueueProvider);
              await queueOperations.queueProfileUpdate(
                profileData: {
                  'name': 'Test User',
                  'failOnServer': !_serverFixed,
                },
                userId: 'test-user',
              );
            },
            child: const Text('Queue Failing Operation'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _serverFixed = !_serverFixed;
              });
            },
            child: Text(_serverFixed ? 'Break Server' : 'Fix Server'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate online
            },
            child: const Text('Simulate Online'),
          ),
          const SizedBox(height: 20),
          const SyncControlWidget(),
        ],
      ),
    );
  }
}