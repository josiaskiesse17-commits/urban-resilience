import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primary = Color(0xFF147B83);
  static const Color primaryLight = Color(0xFFDCEFF1);
  static const Color textDark = Color(0xFF12343B);
  static const Color textGrey = Color(0xFF64777C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBFC),
        elevation: 0,
        title: const Text(
          'Urban Resilience',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mon profil',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: textDark,
            ),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
body: Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Urban Resilience',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),

      const SizedBox(height: 10),

      const Text(
        'Surveillez les risques et signalez les situations dangereuses.',
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 35),

      SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/map');
          },
          icon: const Icon(Icons.map_outlined),
          label: const Text(
            'Voir la carte des risques',
          ),
        ),
      ),

      const SizedBox(height: 14),

      SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/observations');
          },
          icon: const Icon(
            Icons.article_outlined,
          ),
          label: const Text(
            'Voir les publications',
          ),
        ),
      ),

      const SizedBox(height: 14),

      SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton.icon(
          onPressed: () {
            context.push('/observations/report');
          },
          icon: const Icon(
            Icons.add_a_photo_outlined,
          ),
          label: const Text(
            'Signaler une situation',
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}
