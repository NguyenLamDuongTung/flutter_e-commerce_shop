import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Admin'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(user?.fullName ?? 'Admin')),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();

              if (context.mounted) {
                context.go('/admin/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Admin authentication works.\nDashboard data is the next UI stage.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
