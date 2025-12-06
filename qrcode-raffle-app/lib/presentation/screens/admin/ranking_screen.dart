import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.leaderboard,
                  size: 64,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ranking de Participantes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppColors.info),
                    SizedBox(width: 8),
                    Text(
                      'Em breve',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'O sistema de ranking permitirá:\n\n'
                '• Ver ranking de participação por sorteios\n'
                '• Ver ranking por eventos/trilhas\n'
                '• Criar sorteios VIP para participantes frequentes\n'
                '• Filtrar por mínimo de participações',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
