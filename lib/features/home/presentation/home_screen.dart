import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';









class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<({IconData icon, String title, String detail})> _steps = [
    (
      icon: Icons.map_outlined,
      title: '1. Ouvrir la carte',
      detail: 'Chaque zone est un point coloré : la couleur indique le risque '
          'le plus élevé actuellement identifié dans cette zone.',
    ),
    (
      icon: Icons.list_alt_outlined,
      title: '2. Choisir la zone',
      detail: 'La fiche des risques actifs liste les risques identifiés de la '
          'zone ainsi que les risques qui ne sont pas encore évalués.',
    ),
    (
      icon: Icons.insights_outlined,
      title: '3. Lire le risque',
      detail: 'La fiche de détail affiche l’évaluation enregistrée, ses '
          'preuves et l’interprétation IA, et les actualise sur place.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risque d’inondation'),
        actions: [
          IconButton(
            tooltip: 'Profil et rôle',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connaissez votre zone avant la prochaine pluie.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chaque zone combine les données environnementales en '
                  'direct, la référence historique du même endroit et le '
                  'profil d’exposition de la communauté enregistré, en une '
                  'seule évaluation. La carte montre où un risque est '
                  'identifié aujourd’hui.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/map'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ouvrir la carte'),
                ),
                const SizedBox(height: 24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: <Widget>[
                      for (int index = 0;
                          index < _steps.length;
                          index++) ...[
                        _StepTile(step: _steps[index]),
                        if (index < _steps.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final ({IconData icon, String title, String detail}) step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      leading: Icon(
        step.icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        step.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        step.detail,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
