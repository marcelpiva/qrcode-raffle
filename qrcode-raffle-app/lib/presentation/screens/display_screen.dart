import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../providers/draw_provider.dart';
import '../widgets/countdown_timer_widget.dart';

/// Full-screen display mode for projection
class DisplayScreen extends ConsumerStatefulWidget {
  final String raffleId;

  const DisplayScreen({
    super.key,
    required this.raffleId,
  });

  @override
  ConsumerState<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends ConsumerState<DisplayScreen> {
  late ConfettiController _confettiController;
  Timer? _pollTimer;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));

    // Full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Start polling for updates
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.read(displayProvider(widget.raffleId).notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String get _registrationUrl {
    final baseUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
    return '$baseUrl/register/${widget.raffleId}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(displayProvider(widget.raffleId));
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main content
            if (state.isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (state.error != null)
              _buildError(state.error!)
            else if (state.raffle != null)
              _buildDisplayContent(context, state, isLandscape),

            // Confetti
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
                ],
                numberOfParticles: 100,
                maxBlastForce: 50,
                minBlastForce: 20,
                emissionFrequency: 0.02,
                gravity: 0.05,
              ),
            ),

            // Controls overlay
            if (_showControls)
              _buildControlsOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayContent(BuildContext context, DisplayState state, bool isLandscape) {
    final raffle = state.raffle!;

    // If there's a winner, show celebration
    if (raffle.isDrawn && raffle.winner != null) {
      return _buildWinnerDisplay(raffle);
    }

    // Otherwise show QR code and info
    if (isLandscape) {
      return _buildLandscapeLayout(state, raffle);
    } else {
      return _buildPortraitLayout(state, raffle);
    }
  }

  Widget _buildPortraitLayout(DisplayState state, dynamic raffle) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Title
            Text(
              raffle.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Prize
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    raffle.prize,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // QR Code
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: _registrationUrl,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),

            Text(
              'Escaneie para participar',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Participant counter
            _AnimatedCounter(count: state.participantCount),

            const SizedBox(height: 24),

            // Countdown if scheduled
            if (raffle.hasSchedule && !raffle.isDrawn)
              _buildCountdown(raffle),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(DisplayState state, dynamic raffle) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          children: [
            // Left side - Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    raffle.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          raffle.prize,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _AnimatedCounter(count: state.participantCount, large: true),
                  const SizedBox(height: 24),
                  if (raffle.hasSchedule && !raffle.isDrawn)
                    _buildCountdown(raffle),
                ],
              ),
            ),

            const SizedBox(width: 60),

            // Right side - QR Code
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: _registrationUrl,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  'Escaneie para participar',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerDisplay(dynamic raffle) {
    // Trigger confetti
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_confettiController.state.toString().contains('playing')) {
        _confettiController.play();
      }
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 80,
              color: AppColors.success,
            ),
          ).animate().scale(
                duration: 800.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 32),

          Text(
            'GANHADOR',
            style: TextStyle(
              color: AppColors.success.withOpacity(0.8),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          Text(
            raffle.winner!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

          const SizedBox(height: 8),

          Text(
            raffle.winner!.email,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 24,
            ),
          ).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                Text(
                  raffle.prize,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 900.ms).scale(delay: 900.ms),
        ],
      ),
    );
  }

  Widget _buildCountdown(dynamic raffle) {
    final CountdownMode mode;
    final DateTime targetTime;

    if (raffle.hasNotStarted && raffle.startsAt != null) {
      mode = CountdownMode.opensIn;
      targetTime = raffle.startsAt!;
    } else if (raffle.endsAt != null && !raffle.isExpired) {
      mode = CountdownMode.closesIn;
      targetTime = raffle.endsAt!;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: mode == CountdownMode.closesIn
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mode == CountdownMode.closesIn
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.info.withOpacity(0.3),
        ),
      ),
      child: CountdownTimerWidget(
        targetTime: targetTime,
        mode: mode,
        onExpired: () {
          ref.read(displayProvider(widget.raffleId).notifier).refresh();
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(displayProvider(widget.raffleId).notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => context.pop(),
              ),
            ),
            // Center controls
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Toque para esconder controles',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Sair do modo projeção'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _AnimatedCounter extends StatelessWidget {
  final int count;
  final bool large;

  const _AnimatedCounter({
    required this.count,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 32 : 24,
        vertical: large ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            color: AppColors.info,
            size: large ? 40 : 32,
          ),
          SizedBox(width: large ? 16 : 12),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Text(
                '$value',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 56 : 40,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          SizedBox(width: large ? 12 : 8),
          Text(
            'participante${count != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: large ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
