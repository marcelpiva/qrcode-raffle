import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

enum ConfirmationType {
  delete,
  close,
  warning,
  info,
}

class ConfirmationScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? subtitle;
  final String confirmText;
  final String cancelText;
  final ConfirmationType type;
  final VoidCallback? onConfirm;
  final bool isLoading;

  const ConfirmationScreen({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.type = ConfirmationType.warning,
    this.onConfirm,
    this.isLoading = false,
  });

  Color get _primaryColor {
    switch (type) {
      case ConfirmationType.delete:
        return AppColors.error;
      case ConfirmationType.close:
        return AppColors.warning;
      case ConfirmationType.warning:
        return AppColors.warning;
      case ConfirmationType.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case ConfirmationType.delete:
        return Icons.delete_forever_rounded;
      case ConfirmationType.close:
        return Icons.block_rounded;
      case ConfirmationType.warning:
        return Icons.warning_amber_rounded;
      case ConfirmationType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
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
                        // Icon with animated background
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _primaryColor.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _primaryColor.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _icon,
                                size: 40,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 12),

                        // Message
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),

                        // Subtitle (optional)
                        if (subtitle != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withAlpha(8)
                                  : Colors.black.withAlpha(8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withAlpha(15)
                                    : Colors.black.withAlpha(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subtitle!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Buttons
              Column(
                children: [
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (onConfirm != null) {
                                onConfirm!();
                              } else {
                                Navigator.of(context).pop(true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: _primaryColor.withAlpha(100),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              confirmText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.textSecondaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to navigate to confirmation screen and get result
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? subtitle,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    ConfirmationType type = ConfirmationType.warning,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          title: title,
          message: message,
          subtitle: subtitle,
          confirmText: confirmText,
          cancelText: cancelText,
          type: type,
        ),
      ),
    );
    return result ?? false;
  }
}
