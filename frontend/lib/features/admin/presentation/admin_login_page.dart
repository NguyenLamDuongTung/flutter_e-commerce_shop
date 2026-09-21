import 'package:flutter/material.dart';

import '../../auth/presentation/login_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage(adminMode: true);
  }
}
