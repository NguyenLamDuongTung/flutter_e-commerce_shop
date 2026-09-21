import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      context.go('/');
      return;
    }

    final error = ref.read(authControllerProvider).error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? 'Registration failed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter your full name.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.length < 8
                        ? 'Use at least 8 characters.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
