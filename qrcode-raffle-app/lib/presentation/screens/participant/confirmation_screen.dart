import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/pin_input_widget.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final String raffleId;

  const ConfirmationScreen({
    super.key,
    required this.raffleId,
  });

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  final _confettiController =
      ConfettiController(duration: const Duration(seconds: 5));
  String _pin = '';

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_pin.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite seu código de 5 dígitos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref
        .read(confirmationProvider(widget.raffleId).notifier)
        .confirmPresence(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(confirmationProvider(widget.raffleId));

    // Listen for success
    ref.listen<ConfirmationState>(
      confirmationProvider(widget.raffleId),
      (previous, next) {
        if (next.isSuccess && !previous!.isSuccess) {
          _confettiController.play();
        }
        if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Presença'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(state),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.success,
                AppColors.warning,
                Colors.blue,
                Colors.orange,
              ],
              numberOfParticles: 50,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ConfirmationState state) {
    if (state.isSuccess) {
      return _buildSuccessState();
    }

    return _buildConfirmationForm(state);
  }

  Widget _buildConfirmationForm(ConfirmationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.white,
                  ),
                ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 16),
                Text(
                  'Parabéns!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Você foi sorteado!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // PIN input section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppColors.primary,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                Text(
                  'Digite seu código de confirmação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 8),
                Text(
                  'Use o código de 5 dígitos que você criou ao se inscrever.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
                PinInputWidget(
                  length: 5,
                  autofocus: true,
                  obscureText: true,
                  error: state.error,
                  onChanged: (value) {
                    setState(() {
                      _pin = value;
                    });
                  },
                  onCompleted: (value) {
                    setState(() {
                      _pin = value;
                    });
                    _onSubmit();
                  },
                ).animate().fadeIn(delay: 550.ms).scale(begin: const Offset(0.9, 0.9)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: state.isConfirming ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: state.isConfirming
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirmar Presença',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Help text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Se você não lembra do código, procure um organizador do evento.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 64,
                color: Colors.white,
              ),
            ).animate().scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 32),
            Text(
              'Presença confirmada!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            Text(
              'Parabéns! Seu prêmio está garantido.\n'
              'Procure um organizador para retirá-lo.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Voltar ao início',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
