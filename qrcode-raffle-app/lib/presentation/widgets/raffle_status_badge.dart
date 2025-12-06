import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/raffle.dart';

class RaffleStatusBadge extends StatelessWidget {
  final RaffleStatus status;
  final bool compact;

  const RaffleStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color get _color {
    switch (status) {
      case RaffleStatus.active:
        return AppColors.statusActive;
      case RaffleStatus.closed:
        return AppColors.statusClosed;
      case RaffleStatus.drawn:
        return AppColors.statusDrawn;
    }
  }

  IconData get _icon {
    switch (status) {
      case RaffleStatus.active:
        return Icons.play_circle_outline;
      case RaffleStatus.closed:
        return Icons.pause_circle_outline;
      case RaffleStatus.drawn:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: compact ? 14 : 16,
            color: _color,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
