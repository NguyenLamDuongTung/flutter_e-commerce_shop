import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';

class ShopHomePage extends ConsumerWidget {
  const ShopHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOVA',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign in'),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(user.fullName)),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();

                if (context.mounted) {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.logout),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 600),
            padding: const EdgeInsets.all(32),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Technology, beautifully simple.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Phones, laptops, tablets, watches and audio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 22),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Explore products'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
