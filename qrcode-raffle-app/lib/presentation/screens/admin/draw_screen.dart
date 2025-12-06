import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../providers/draw_provider.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/slot_machine_widget.dart';
import '../../widgets/winner_celebration_widget.dart';

class DrawScreen extends ConsumerStatefulWidget {
  final String raffleId;

  // NAVA SUMMIT Colors
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color primaryPink = Color(0xFFDB2777);
  static const Color darkBg = Color(0xFF09090B);
  static const Color cardBg = Color(0xFF18181B);
  static const Color cardBorder = Color(0xFF27272A);
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color errorRed = Color(0xFFEF4444);

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(drawProvider(widget.raffleId));

    return Scaffold(
      backgroundColor: DrawScreen.darkBg,
      body: Stack(
        children: [
          // Background gradient with decorative elements
          _buildBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                Expanded(child: _buildContent(context, ref, state)),
              ],
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                DrawScreen.primaryPurple,
                DrawScreen.primaryPink,
                DrawScreen.successGreen,
                Colors.yellow,
                Colors.orange,
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

  Widget _buildBackground() {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0A2E),
                DrawScreen.darkBg,
                Color(0xFF0A0A0A),
              ],
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          right: -100,
          top: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DrawScreen.primaryPurple.withOpacity(0.3),
                  DrawScreen.primaryPurple.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DrawScreen.primaryPink.withOpacity(0.2),
                  DrawScreen.primaryPink.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DrawState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => _handleClose(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.raffle?.name ?? 'Sorteio',
              style: const TextStyle(
                color: DrawScreen.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (state.raffle != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                onPressed: () => context.push('/display/${widget.raffleId}'),
                tooltip: 'Modo projecao',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DrawState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(DrawScreen.primaryPurple),
        ),
      );
    }

    if (state.hasError) {
      return _buildError(context, ref, state.error!);
    }

    if (state.raffle == null) {
      return _buildNotFound(context);
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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: DrawScreen.cardBg.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DrawScreen.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: DrawScreen.primaryPurple.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Prize section with gradient header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              DrawScreen.primaryPurple.withOpacity(0.3),
                              DrawScreen.primaryPink.withOpacity(0.2),
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
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [DrawScreen.primaryPurple, DrawScreen.primaryPink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: DrawScreen.primaryPurple.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [DrawScreen.primaryPurple, DrawScreen.primaryPink],
                              ).createShader(bounds),
                              child: const Text(
                                'PREMIO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              raffle.prize,
                              style: const TextStyle(
                                color: DrawScreen.textPrimary,
                                fontSize: 24,
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
                        color: DrawScreen.cardBorder,
                      ),

                      // Participants section
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: DrawScreen.infoBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.people_alt_rounded,
                                    color: DrawScreen.infoBlue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [DrawScreen.infoBlue, Color(0xFF60A5FA)],
                                      ).createShader(bounds),
                                      child: Text(
                                        '${state.participants.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'participante${state.participants.length != 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        color: DrawScreen.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Confirmation info badge
                            if (raffle.requireConfirmation) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: DrawScreen.warningOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: DrawScreen.warningOrange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: DrawScreen.warningOrange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confirmacao em ${raffle.confirmationTimeoutMinutes ?? 5} min',
                                      style: const TextStyle(
                                        color: DrawScreen.warningOrange,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 36),

            // Draw button
            Container(
              width: cardWidth,
              height: 64,
              decoration: BoxDecoration(
                gradient: hasParticipants
                    ? const LinearGradient(
                        colors: [DrawScreen.primaryPurple, DrawScreen.primaryPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasParticipants ? null : DrawScreen.cardBg,
                borderRadius: BorderRadius.circular(32),
                boxShadow: hasParticipants
                    ? [
                        BoxShadow(
                          color: DrawScreen.primaryPurple.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
                border: hasParticipants ? null : Border.all(color: DrawScreen.cardBorder),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasParticipants ? () => _startDraw(ref) : null,
                  borderRadius: BorderRadius.circular(32),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.casino_rounded,
                          size: 28,
                          color: hasParticipants ? Colors.white : DrawScreen.textTertiary,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'SORTEAR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: hasParticipants ? Colors.white : DrawScreen.textTertiary,
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
              const SizedBox(height: 20),
              Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: DrawScreen.errorRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DrawScreen.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: DrawScreen.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Nenhum participante inscrito',
                      style: TextStyle(
                        color: DrawScreen.errorRed,
                        fontSize: 14,
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
          onConfirm: state.isConfirming ? null : () => _confirmWinner(ref),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DrawScreen.successGreen.withOpacity(0.2),
                    DrawScreen.successGreen.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DrawScreen.successGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: DrawScreen.successGreen, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'CONFIRMADO',
                    style: TextStyle(
                      color: DrawScreen.successGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: DrawScreen.errorRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DrawScreen.errorRed.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.timer_off_rounded,
                size: 72,
                color: DrawScreen.errorRed,
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 28),
            const Text(
              'Tempo Esgotado',
              style: TextStyle(
                color: DrawScreen.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'O ganhador nao confirmou presenca a tempo',
              style: TextStyle(
                color: DrawScreen.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DrawScreen.primaryPurple, DrawScreen.primaryPink],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DrawScreen.primaryPurple.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _redraw(ref),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Sortear Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DrawScreen.cardBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: DrawScreen.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sorteio nao encontrado',
            style: TextStyle(
              color: DrawScreen.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
            style: TextButton.styleFrom(
              foregroundColor: DrawScreen.primaryPurple,
            ),
          ),
        ],
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
                color: DrawScreen.errorRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: DrawScreen.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              error,
              style: const TextStyle(
                color: DrawScreen.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DrawScreen.primaryPurple, DrawScreen.primaryPink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(drawProvider(widget.raffleId).notifier).loadRaffle(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startDraw(WidgetRef ref) {
    final notifier = ref.read(drawProvider(widget.raffleId).notifier);
    notifier.startSpinning();
    notifier.performDraw();
  }

  void _confirmWinner(WidgetRef ref) {
    ref.read(drawProvider(widget.raffleId).notifier).confirmWinner();
    ref.read(raffleListProvider.notifier).refresh();
  }

  void _redraw(WidgetRef ref) {
    ref.read(drawProvider(widget.raffleId).notifier).redraw();
  }

  void _handleClose(BuildContext context) {
    ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh();
    context.pop();
  }
}
