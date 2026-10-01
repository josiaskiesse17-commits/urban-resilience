import 'package:flutter/material.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppPalette.primary,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('Camille Bernard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('camille.bernard@exemple.fr', style: TextStyle(color: AppPalette.textMuted)),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppPalette.primary),
              title: const Text('Préférences d\'alerte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppPalette.error),
              title: const Text('Déconnexion', style: TextStyle(color: AppPalette.error)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}