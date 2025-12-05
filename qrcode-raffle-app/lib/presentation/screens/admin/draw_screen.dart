import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DrawScreen extends StatelessWidget {
  final String raffleId;

  const DrawScreen({
    super.key,
    required this.raffleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizar Sorteio'),
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
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.casino,
                  size: 64,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Realizar Sorteio',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'ID: $raffleId',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Esta tela será implementada na Fase 4.\n'
                'Aqui teremos a animação de slot machine '
                'e confetti para o sorteio.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
