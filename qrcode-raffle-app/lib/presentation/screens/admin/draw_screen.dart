import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/draw_provider.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/slot_machine_widget.dart';
import '../../widgets/winner_celebration_widget.dart';

class DrawScreen extends ConsumerStatefulWidget {
  final String raffleId;

  const DrawScreen({
    super.key,
    required this.raffleId,
  });

  @override
  ConsumerState<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends ConsumerState<DrawScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    // Set system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(drawProvider(widget.raffleId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _handleClose(context),
        ),
        title: Text(
          state.raffle?.name ?? 'Sorteio',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (state.raffle != null)
            IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () => context.push('/display/${widget.raffleId}'),
              tooltip: 'Modo projeção',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundDark,
                  const Color(0xFF151515),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: _buildContent(context, ref, state),
          ),

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
                Colors.yellow,
                Colors.orange,
                Colors.pink,
                Colors.purple,
                Colors.cyan,
              ],
              numberOfParticles: 50,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.03,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DrawState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError) {
      return _buildError(context, ref, state.error!);
    }

    if (state.raffle == null) {
      return const Center(
        child: Text(
          'Sorteio não encontrado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    switch (state.phase) {
      case DrawPhase.ready:
        return _buildReadyPhase(context, ref, state);
      case DrawPhase.spinning:
        return _buildSpinningPhase(context, ref, state);
      case DrawPhase.winner:
      case DrawPhase.confirming:
        return _buildWinnerPhase(context, ref, state);
      case DrawPhase.confirmed:
        return _buildConfirmedPhase(context, ref, state);
      case DrawPhase.timeout:
        return _buildTimeoutPhase(context, ref, state);
      default:
        return _buildReadyPhase(context, ref, state);
    }
  }

  Widget _buildReadyPhase(BuildContext context, WidgetRef ref, DrawState state) {
    final raffle = state.raffle!;
    final hasParticipants = state.participants.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 360.0 : screenWidth - 48;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main card with prize and participants
            Container(
              width: cardWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha(20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(30),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Prize section with gradient header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withAlpha(40),
                          AppColors.secondary.withAlpha(20),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Trophy icon with glow
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(100),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PRÊMIO',
                          style: TextStyle(
                            color: AppColors.mutedForegroundDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          raffle.prize,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withAlpha(10),
                  ),

                  // Participants section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.info.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_alt_rounded,
                                color: AppColors.info,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.participants.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'participante${state.participants.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: AppColors.mutedForegroundDark,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Confirmation info badge
                        if (raffle.requireConfirmation) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warning.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Confirmação em ${raffle.confirmationTimeoutMinutes ?? 5} min',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 32),

            // Draw button
            Container(
              width: cardWidth,
              height: 56,
              decoration: BoxDecoration(
                gradient: hasParticipants ? AppColors.primaryGradient : null,
                color: hasParticipants ? null : AppColors.mutedDark,
                borderRadius: BorderRadius.circular(28),
                boxShadow: hasParticipants
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasParticipants ? () => _startDraw(ref) : null,
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.casino_rounded,
                          size: 26,
                          color: hasParticipants ? Colors.white : AppColors.mutedForegroundDark,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SORTEAR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: hasParticipants ? Colors.white : AppColors.mutedForegroundDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  delay: 200.ms,
                ),

            // No participants message
            if (!hasParticipants) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Nenhum participante inscrito',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpinningPhase(BuildContext context, WidgetRef ref, DrawState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.winner != null)
              SimpleSlotMachine(
                names: state.participantNames,
                winnerName: state.winner!.name,
                onComplete: () {
                  _confettiController.play();
                  ref.read(drawProvider(widget.raffleId).notifier).setPhase(
                    state.raffle!.requireConfirmation
                        ? DrawPhase.confirming
                        : DrawPhase.winner,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerPhase(BuildContext context, WidgetRef ref, DrawState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: WinnerCelebrationWidget(
          winner: state.winner!,
          prize: state.raffle!.prize,
          requireConfirmation: state.isConfirming,
          confirmationTimeoutMinutes: state.raffle!.confirmationTimeoutMinutes,
          onConfirm: state.isConfirming
              ? null
              : () => _confirmWinner(ref),
          onRedraw: () => _redraw(ref),
          onClose: () => _handleClose(context),
        ),
      ),
    );
  }

  Widget _buildConfirmedPhase(BuildContext context, WidgetRef ref, DrawState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Confirmed badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'CONFIRMADO',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            WinnerCelebrationWidget(
              winner: state.winner!,
              prize: state.raffle!.prize,
              onClose: () => _handleClose(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutPhase(BuildContext context, WidgetRef ref, DrawState state) {
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
                Icons.timer_off,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tempo Esgotado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O ganhador não confirmou presença a tempo',
              style: TextStyle(
                color: AppColors.mutedForegroundDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _redraw(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Sortear Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(drawProvider(widget.raffleId).notifier).loadRaffle(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  void _startDraw(WidgetRef ref) {
    final notifier = ref.read(drawProvider(widget.raffleId).notifier);
    notifier.startSpinning();

    // Perform the actual draw and then show animation
    notifier.performDraw();
  }

  void _confirmWinner(WidgetRef ref) {
    ref.read(drawProvider(widget.raffleId).notifier).confirmWinner();
    // Refresh raffle list
    ref.read(raffleListProvider.notifier).refresh();
  }

  void _redraw(WidgetRef ref) {
    ref.read(drawProvider(widget.raffleId).notifier).redraw();
  }

  void _handleClose(BuildContext context) {
    // Refresh raffle detail before closing
    ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh();
    context.pop();
  }
}
