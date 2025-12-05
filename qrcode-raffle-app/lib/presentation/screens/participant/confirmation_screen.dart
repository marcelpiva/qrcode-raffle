import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ConfirmationScreen extends StatelessWidget {
  final String raffleId;

  const ConfirmationScreen({
    super.key,
    required this.raffleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Presença'),
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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Confirmar Presença',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sorteio ID: $raffleId',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Esta tela será implementada na Fase 2.\n'
                'Aqui o ganhador do sorteio poderá confirmar '
                'sua presença inserindo seu PIN.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
