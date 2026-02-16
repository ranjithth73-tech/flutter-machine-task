import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/features/auth/presentation/pages/login_page.dart';
import 'package:smart_task_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_task_manager/features/task/presentation/pages/task_list_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Use a slight delay or listen to stream immediately
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateChangesProvider);

    return authStateAsync.when(
      data: (user) {
        if (user != null) {
          return const TaskListPage();
        } else {
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}
