import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Resilience'),
        actions: [
          IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Home'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/map'),
                child: const Text('View Risk Map'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/risk/ai-test'),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Test AI Risk Analyst'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
