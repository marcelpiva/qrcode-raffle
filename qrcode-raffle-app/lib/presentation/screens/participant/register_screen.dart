import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/raffle_info_card.dart';
import '../../widgets/pin_input_widget.dart';
import '../shared/success_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String raffleId;

  const RegisterScreen({
    super.key,
    required this.raffleId,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _pin = '';
  bool _showPinField = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final state = ref.read(registrationProvider(widget.raffleId));

      // Check if PIN is required but not provided
      if (state.raffleInfo?.requireConfirmation == true && _pin.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, digite seu código de 5 dígitos'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      ref.read(registrationProvider(widget.raffleId).notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            pin: _pin.isNotEmpty ? _pin : null,
          );
    }
  }

  void _onCountdownExpired() {
    ref.read(registrationProvider(widget.raffleId).notifier).loadRaffleInfo();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider(widget.raffleId));

    // Listen for success
    ref.listen<RegistrationState>(
      registrationProvider(widget.raffleId),
      (previous, next) {
        if (next.isSuccess && !previous!.isSuccess) {
          // Navigate to success screen
          SuccessScreen.show(
            context: context,
            title: 'Inscrição Confirmada!',
            message: 'Parabéns, ${next.registeredParticipant?.name ?? ''}!',
            subtitle: 'Você está participando do sorteio. Boa sorte!',
            buttonText: 'Voltar ao Início',
            onDismiss: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
          );
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
        title: const Text('Participar do Sorteio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(RegistrationState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.raffleInfo == null) {
      return _buildError(state.error!);
    }

    if (state.raffleInfo == null) {
      return _buildError('Sorteio não encontrado');
    }

    final raffle = state.raffleInfo!;

    // Check if raffle is open for registration
    if (!raffle.isActive) {
      return _buildClosedState(raffle);
    }

    if (raffle.hasNotStarted) {
      return _buildNotStartedState(raffle);
    }

    if (raffle.isExpired) {
      return _buildExpiredState(raffle);
    }

    if (raffle.isEventRaffle && !raffle.allowLinkRegistration) {
      return _buildEventRaffleNotice(raffle);
    }

    return _buildRegistrationForm(raffle, state);
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              error,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(registrationProvider(widget.raffleId).notifier)
                  .loadRaffleInfo(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedState(raffle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.statusClosed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.statusClosed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              raffle.isClosed
                  ? 'Inscrições encerradas'
                  : 'Sorteio já realizado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Este sorteio não está mais aceitando inscrições.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            RaffleInfoCard(raffle: raffle, showCountdown: false),
          ],
        ),
      ),
    );
  }

  Widget _buildNotStartedState(raffle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RaffleInfoCard(
            raffle: raffle,
            onCountdownExpired: _onCountdownExpired,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 48,
                  color: AppColors.info,
                ),
                const SizedBox(height: 16),
                Text(
                  'As inscrições ainda não foram abertas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aguarde o início do período de inscrições.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredState(raffle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RaffleInfoCard(raffle: raffle, showCountdown: false),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.timer_off,
                  size: 48,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  'O tempo para inscrições expirou',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Infelizmente o período de inscrições já terminou.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRaffleNotice(raffle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RaffleInfoCard(raffle: raffle),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: AppColors.info,
                ),
                const SizedBox(height: 16),
                Text(
                  'Inscrição automática',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Este sorteio não aceita inscrições manuais. '
                  'Os participantes são selecionados automaticamente '
                  'com base na presença nas palestras do evento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(raffle, RegistrationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RaffleInfoCard(
              raffle: raffle,
              onCountdownExpired: _onCountdownExpired,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
            const SizedBox(height: 24),
            Text(
              'Seus dados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                hintText: 'Digite seu nome',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, digite seu nome';
                }
                if (value.trim().length < 3) {
                  return 'Nome muito curto';
                }
                return null;
              },
            ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                hintText: raffle.allowedDomain != null
                    ? 'seu.email@${raffle.allowedDomain}'
                    : 'Digite seu e-mail',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: raffle.allowedDomain != null
                    ? 'Apenas e-mails @${raffle.allowedDomain}'
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, digite seu e-mail';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'E-mail inválido';
                }
                if (raffle.allowedDomain != null) {
                  final domain = value.split('@').last.toLowerCase();
                  if (domain != raffle.allowedDomain!.toLowerCase()) {
                    return 'Apenas e-mails @${raffle.allowedDomain}';
                  }
                }
                return null;
              },
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

            // PIN field (if required)
            if (raffle.requireConfirmation) ...[
              const SizedBox(height: 24),
              Text(
                'Código de confirmação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 8),
              Text(
                'Crie um código de 5 dígitos para confirmar sua presença caso seja sorteado.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ).animate().fadeIn(delay: 280.ms),
              const SizedBox(height: 16),
              PinInputWidget(
                length: 5,
                autofocus: false,
                onChanged: (value) {
                  setState(() {
                    _pin = value;
                  });
                },
                onCompleted: (value) {
                  setState(() {
                    _pin = value;
                  });
                },
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
            ],

            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: state.isRegistering ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isRegistering
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Participar do Sorteio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

