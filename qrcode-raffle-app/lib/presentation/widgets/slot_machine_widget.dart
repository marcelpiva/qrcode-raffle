import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SlotMachineWidget extends StatefulWidget {
  final List<String> names;
  final String? winnerName;
  final VoidCallback? onAnimationComplete;
  final Duration spinDuration;

  const SlotMachineWidget({
    super.key,
    required this.names,
    this.winnerName,
    this.onAnimationComplete,
    this.spinDuration = const Duration(seconds: 4),
  });

  @override
  State<SlotMachineWidget> createState() => _SlotMachineWidgetState();
}

class _SlotMachineWidgetState extends State<SlotMachineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _speedAnimation;

  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  int _currentIndex = 0;
  bool _isSpinning = false;
  bool _showWinner = false;

  // Extended list for smooth scrolling
  late List<String> _extendedNames;

  static const double _itemHeight = 80.0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _buildExtendedList();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.spinDuration,
    );

    // Speed curve: fast at start, slow down at end
    _speedAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutExpo,
      ),
    );
  }

  void _buildExtendedList() {
    // Create extended list by repeating names multiple times
    _extendedNames = [];
    for (int i = 0; i < 20; i++) {
      _extendedNames.addAll(widget.names..shuffle());
    }
    // Add winner at the end if specified
    if (widget.winnerName != null) {
      _extendedNames.add(widget.winnerName!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void startSpin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _showWinner = false;
    });

    _controller.reset();
    _controller.forward();

    // Calculate target position (winner should be at center)
    final targetIndex = _extendedNames.length - 1;
    final targetOffset = targetIndex * _itemHeight;

    // Animate scroll with easing
    _scrollController.animateTo(
      targetOffset,
      duration: widget.spinDuration,
      curve: Curves.easeOutExpo,
    ).then((_) {
      setState(() {
        _isSpinning = false;
        _showWinner = true;
      });
      widget.onAnimationComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slot machine container
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Names list
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _extendedNames.length,
                    itemBuilder: (context, index) {
                      return _NameItem(
                        name: _extendedNames[index],
                        isHighlighted: _showWinner && index == _extendedNames.length - 1,
                      );
                    },
                  ),
                ),
              ),

              // Center highlight
              Center(
                child: Container(
                  height: _itemHeight,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Side decorations
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Spin button (only if not showing winner)
        if (!_showWinner)
          _SpinButton(
            isSpinning: _isSpinning,
            onPressed: _isSpinning ? null : startSpin,
          ),
      ],
    );
  }
}

class _NameItem extends StatelessWidget {
  final String name;
  final bool isHighlighted;

  const _NameItem({
    required this.name,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontSize: isHighlighted ? 28 : 22,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          color: isHighlighted ? AppColors.primary : Colors.white,
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SpinButton extends StatelessWidget {
  final bool isSpinning;
  final VoidCallback? onPressed;

  const _SpinButton({
    required this.isSpinning,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSpinning ? 180 : 200,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSpinning ? Colors.grey : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: isSpinning ? 0 : 8,
          shadowColor: AppColors.primary.withOpacity(0.5),
        ),
        child: isSpinning
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sorteando...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.casino, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'SORTEAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Alternative simple slot animation for testing
class SimpleSlotMachine extends StatefulWidget {
  final List<String> names;
  final String winnerName;
  final VoidCallback? onComplete;

  const SimpleSlotMachine({
    super.key,
    required this.names,
    required this.winnerName,
    this.onComplete,
  });

  @override
  State<SimpleSlotMachine> createState() => _SimpleSlotMachineState();
}

class _SimpleSlotMachineState extends State<SimpleSlotMachine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayIndex = 0;
  Timer? _timer;
  bool _showFinal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startAnimation();
  }

  void _startAnimation() {
    _controller.forward();

    // Rapid cycling through names
    int interval = 50;
    _timer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final progress = _controller.value;

      // Slow down as we approach the end
      if (progress > 0.7) {
        interval = 100 + ((progress - 0.7) * 1000).toInt();
      }
      if (progress > 0.9) {
        interval = 300 + ((progress - 0.9) * 2000).toInt();
      }

      if (progress >= 1.0) {
        timer.cancel();
        setState(() {
          _showFinal = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete?.call();
        });
        return;
      }

      setState(() {
        _displayIndex = (_displayIndex + 1) % widget.names.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _showFinal ? widget.winnerName : widget.names[_displayIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_showFinal ? AppColors.success : AppColors.primary).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: _showFinal ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: _showFinal ? AppColors.success : Colors.white,
            ),
            child: Text(
              displayName,
              textAlign: TextAlign.center,
            ),
          ),
          if (!_showFinal) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _controller.value,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
