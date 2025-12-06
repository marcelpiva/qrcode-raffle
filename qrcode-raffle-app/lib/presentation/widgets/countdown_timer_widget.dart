import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum CountdownMode {
  opensIn,
  closesIn,
}

class CountdownTimerWidget extends StatefulWidget {
  final DateTime targetTime;
  final CountdownMode mode;
  final VoidCallback? onExpired;
  final bool showSeconds;
  final bool compact;

  const CountdownTimerWidget({
    super.key,
    required this.targetTime,
    required this.mode,
    this.onExpired,
    this.showSeconds = true,
    this.compact = false,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _timer;
  late Duration _remaining;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final remaining = widget.targetTime.difference(DateTime.now());
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });

    if (remaining.isNegative && !_hasExpired) {
      _hasExpired = true;
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      if (widget.showSeconds) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${hours}h ${minutes}min';
    } else if (minutes > 0) {
      if (widget.showSeconds) {
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes}min';
    } else {
      return '${seconds}s';
    }
  }

  Color get _color {
    if (_remaining.inMinutes < 1) {
      return AppColors.error;
    } else if (_remaining.inMinutes < 5) {
      return AppColors.warning;
    }
    return widget.mode == CountdownMode.opensIn
        ? AppColors.primary
        : AppColors.secondary;
  }

  IconData get _icon {
    return widget.mode == CountdownMode.opensIn
        ? Icons.schedule
        : Icons.timer_outlined;
  }

  String get _label {
    return widget.mode == CountdownMode.opensIn ? 'Abre em' : 'Fecha em';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: _color),
            const SizedBox(width: 4),
            Text(
              '$_label ${_formatDuration(_remaining)}',
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _color.withOpacity(0.1),
            _color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon, size: 20, color: _color),
              const SizedBox(width: 8),
              Text(
                _label,
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_remaining),
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (_remaining.inMinutes < 5) ...[
            const SizedBox(height: 4),
            Text(
              _remaining.inMinutes < 1 ? 'Últimos segundos!' : 'Corra!',
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
