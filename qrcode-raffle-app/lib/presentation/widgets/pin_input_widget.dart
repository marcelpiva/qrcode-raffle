import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class PinInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool autofocus;
  final String? error;

  const PinInputWidget({
    super.key,
    this.length = 5,
    this.onCompleted,
    this.onChanged,
    this.obscureText = false,
    this.autofocus = false,
    this.error,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final pastedText = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < pastedText.length && (index + i) < widget.length; i++) {
        _controllers[index + i].text = pastedText[i];
      }
      final nextIndex = (index + pastedText.length).clamp(0, widget.length - 1);
      _focusNodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    _updatePin();
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _controllers[index - 1].clear();
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  void _updatePin() {
    _currentPin = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(_currentPin);

    if (_currentPin.length == widget.length) {
      widget.onCompleted?.call(_currentPin);
    }
  }

  void clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _currentPin = '';
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Container(
              width: 50,
              height: 60,
              margin: EdgeInsets.only(
                right: index < widget.length - 1 ? 8 : 0,
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) => _onKeyPressed(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  obscureText: widget.obscureText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: hasError
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? AppColors.error
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? AppColors.error
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError ? AppColors.error : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) => _onChanged(index, value),
                ),
              ),
            );
          }),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
