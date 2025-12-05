import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CreateRaffleScreen extends StatelessWidget {
  const CreateRaffleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sorteio'),
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
                  Icons.add_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Criar Novo Sorteio',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              const Text(
                'Esta tela será implementada na Fase 3.\n'
                'Aqui o administrador poderá criar um novo sorteio '
                'com todas as configurações disponíveis.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
