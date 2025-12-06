import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';

class SuccessScreen extends StatefulWidget {
  final String title;
  final String message;
  final String? subtitle;
  final String buttonText;
  final VoidCallback onDismiss;
  final bool showConfetti;

  const SuccessScreen({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.buttonText = 'Continuar',
    required this.onDismiss,
    this.showConfetti = true,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();

  /// Helper method to navigate to success screen
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String? subtitle,
    String buttonText = 'Continuar',
    required VoidCallback onDismiss,
    bool showConfetti = true,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          title: title,
          message: message,
          subtitle: subtitle,
          buttonText: buttonText,
          onDismiss: onDismiss,
          showConfetti: showConfetti,
        ),
      ),
    );
  }
}

class _SuccessScreenState extends State<SuccessScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Success icon with animated circles
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                ).animate().scale(
                                      duration: 600.ms,
                                      curve: Curves.elasticOut,
                                    ),
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(40),
                                    shape: BoxShape.circle,
                                  ),
                                ).animate().scale(
                                      delay: 100.ms,
                                      duration: 600.ms,
                                      curve: Curves.elasticOut,
                                    ),
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ).animate().scale(
                                      delay: 200.ms,
                                      duration: 600.ms,
                                      curve: Curves.elasticOut,
                                    ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Title
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                            const SizedBox(height: 12),

                            // Message
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 400.ms),

                            // Subtitle (optional)
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.success.withAlpha(40),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        widget.subtitle!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 500.ms),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),

          // Confetti
          if (widget.showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.success,
                  AppColors.info,
                  AppColors.warning,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
