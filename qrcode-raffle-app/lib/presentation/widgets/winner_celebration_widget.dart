import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/participant.dart';

class WinnerCelebrationWidget extends StatelessWidget {
  final Participant winner;
  final String prize;
  final bool requireConfirmation;
  final int? confirmationTimeoutMinutes;
  final VoidCallback? onConfirm;
  final VoidCallback? onRedraw;
  final VoidCallback? onClose;

  const WinnerCelebrationWidget({
    super.key,
    required this.winner,
    required this.prize,
    this.requireConfirmation = false,
    this.confirmationTimeoutMinutes,
    this.onConfirm,
    this.onRedraw,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy animation
          _TrophyAnimation()
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .then()
              .shimmer(
                duration: 2000.ms,
                color: Colors.yellow.withOpacity(0.3),
              ),

          const SizedBox(height: 24),

          // Winner label
          Text(
            'GANHADOR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              color: AppColors.success.withOpacity(0.8),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),

          // Winner name
          Text(
            winner.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms),

          const SizedBox(height: 4),

          // Winner email
          Text(
            winner.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 24),

          // Prize card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    prize,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms),

          const SizedBox(height: 32),

          // Actions
          if (requireConfirmation && confirmationTimeoutMinutes != null)
            _ConfirmationCountdown(
              timeoutMinutes: confirmationTimeoutMinutes!,
              onTimeout: onRedraw,
            ).animate().fadeIn(delay: 700.ms)
          else
            _ActionButtons(
              onConfirm: onConfirm,
              onRedraw: onRedraw,
              onClose: onClose,
            ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }
}

class _TrophyAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.success.withOpacity(0.3),
                AppColors.success.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Trophy icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.emoji_events,
            size: 56,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationCountdown extends StatefulWidget {
  final int timeoutMinutes;
  final VoidCallback? onTimeout;

  const _ConfirmationCountdown({
    required this.timeoutMinutes,
    this.onTimeout,
  });

  int get timeoutSeconds => timeoutMinutes * 60;

  @override
  State<_ConfirmationCountdown> createState() => _ConfirmationCountdownState();
}

class _ConfirmationCountdownState extends State<_ConfirmationCountdown>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timeoutSeconds),
    );
    _controller.forward();
    _controller.addListener(_onTick);
  }

  void _onTick() {
    final newRemaining = ((1 - _controller.value) * widget.timeoutSeconds).ceil();
    if (newRemaining != _remainingSeconds) {
      setState(() => _remainingSeconds = newRemaining);
    }
    if (_controller.isCompleted) {
      widget.onTimeout?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds <= 10;

    return Column(
      children: [
        // Waiting message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_bottom,
                color: isUrgent ? AppColors.error : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Aguardando confirmação do ganhador...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Countdown
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: 1 - _controller.value,
                strokeWidth: 6,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUrgent ? AppColors.error : AppColors.warning,
                ),
              ),
            ),
            Text(
              '$_remainingSeconds',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isUrgent ? AppColors.error : Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'segundos',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onRedraw;
  final VoidCallback? onClose;

  const _ActionButtons({
    this.onConfirm,
    this.onRedraw,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Confirm button
        if (onConfirm != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirmar Ganhador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (onConfirm != null && onRedraw != null)
          const SizedBox(height: 12),

        // Redraw button
        if (onRedraw != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRedraw,
              icon: const Icon(Icons.refresh),
              label: const Text('Sortear Novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[600]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (onClose != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClose,
            child: const Text(
              'Fechar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact winner display for list views
class WinnerBadge extends StatelessWidget {
  final String winnerName;
  final bool compact;

  const WinnerBadge({
    super.key,
    required this.winnerName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: compact ? 14 : 16,
            color: AppColors.success,
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              winnerName,
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
