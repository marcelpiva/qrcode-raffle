import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool showConfetti;
  final ConfettiController? controller;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.showConfetti = false,
    this.controller,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _confettiController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _confettiController = widget.controller!;
    } else {
      _confettiController = ConfettiController(duration: const Duration(seconds: 5));
      _ownsController = true;
    }

    if (widget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _confettiController.play();
    } else if (!widget.showConfetti && oldWidget.showConfetti) {
      _confettiController.stop();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _confettiController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Top center confetti
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
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            gravity: 0.1,
          ),
        ),

        // Left side confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -0.5, // Right and down
            shouldLoop: false,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.success,
              Colors.yellow,
              Colors.orange,
            ],
            numberOfParticles: 15,
            maxBlastForce: 15,
            minBlastForce: 5,
            emissionFrequency: 0.08,
            gravity: 0.15,
          ),
        ),

        // Right side confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -2.6, // Left and down
            shouldLoop: false,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.success,
              Colors.yellow,
              Colors.pink,
            ],
            numberOfParticles: 15,
            maxBlastForce: 15,
            minBlastForce: 5,
            emissionFrequency: 0.08,
            gravity: 0.15,
          ),
        ),
      ],
    );
  }
}

/// A standalone confetti celebration that can be triggered programmatically
class CelebrationConfetti extends StatefulWidget {
  final VoidCallback? onComplete;

  const CelebrationConfetti({
    super.key,
    this.onComplete,
  });

  @override
  State<CelebrationConfetti> createState() => CelebrationConfettiState();
}

class CelebrationConfettiState extends State<CelebrationConfetti> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 5));
    _controller.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (_controller.state == ConfettiControllerState.stopped) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    super.dispose();
  }

  void play() {
    _controller.play();
  }

  void stop() {
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Center burst
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _controller,
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
              Colors.white,
            ],
            numberOfParticles: 50,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.03,
            gravity: 0.1,
            particleDrag: 0.05,
          ),
        ),
      ],
    );
  }
}

/// Simple confetti burst from top
class TopConfettiBurst extends StatelessWidget {
  final ConfettiController controller;

  const TopConfettiBurst({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
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
        numberOfParticles: 40,
        maxBlastForce: 25,
        minBlastForce: 10,
        emissionFrequency: 0.05,
        gravity: 0.15,
      ),
    );
  }
}
