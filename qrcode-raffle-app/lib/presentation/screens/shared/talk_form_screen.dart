import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class TalkFormData {
  final String title;
  final String speaker;
  final String description;
  final DateTime? startTime;
  final DateTime? endTime;

  TalkFormData({
    this.title = '',
    this.speaker = '',
    this.description = '',
    this.startTime,
    this.endTime,
  });

  TalkFormData copyWith({
    String? title,
    String? speaker,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TalkFormData(
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class TalkFormScreen extends StatefulWidget {
  final TalkFormData? initialData;
  final String title;
  final Color accentColor;

  const TalkFormScreen({
    super.key,
    this.initialData,
    this.title = 'Nova Palestra',
    this.accentColor = AppColors.primary,
  });

  static Future<TalkFormData?> show({
    required BuildContext context,
    TalkFormData? initialData,
    String? title,
    Color accentColor = AppColors.primary,
  }) async {
    return Navigator.of(context).push<TalkFormData>(
      MaterialPageRoute(
        builder: (_) => TalkFormScreen(
          initialData: initialData,
          title: title ?? (initialData?.title.isNotEmpty == true ? 'Editar Palestra' : 'Nova Palestra'),
          accentColor: accentColor,
        ),
      ),
    );
  }

  @override
  State<TalkFormScreen> createState() => _TalkFormScreenState();
}

class _TalkFormScreenState extends State<TalkFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _speakerController;
  late final TextEditingController _descController;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData?.title ?? '');
    _speakerController = TextEditingController(text: widget.initialData?.speaker ?? '');
    _descController = TextEditingController(text: widget.initialData?.description ?? '');
    _startTime = widget.initialData?.startTime;
    _endTime = widget.initialData?.endTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart
        ? (_startTime != null ? TimeOfDay.fromDateTime(_startTime!) : TimeOfDay.now())
        : (_endTime != null ? TimeOfDay.fromDateTime(_endTime!) : TimeOfDay.now());

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: widget.accentColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final now = DateTime.now();
      setState(() {
        if (isStart) {
          _startTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        } else {
          _endTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        }
      });
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Título da palestra é obrigatório'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    Navigator.of(context).pop(TalkFormData(
      title: _titleController.text.trim(),
      speaker: _speakerController.text.trim(),
      description: _descController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
    ));
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.accentColor.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: widget.accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _titleController.text.isEmpty ? 'Título da Palestra' : _titleController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_speakerController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _speakerController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_startTime != null || _endTime != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  [
                                    if (_startTime != null) DateFormat('HH:mm').format(_startTime!),
                                    if (_endTime != null) DateFormat('HH:mm').format(_endTime!),
                                  ].join(' - '),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 32),

                    // Title field
                    _buildLabel('Título da Palestra', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'Ex: Introdução à Inteligência Artificial',
                      icon: Icons.title_rounded,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // Speaker field
                    _buildLabel('Palestrante (opcional)', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _speakerController,
                      hint: 'Nome do palestrante',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    // Description field
                    _buildLabel('Descrição (opcional)', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descController,
                      hint: 'Descreva a palestra...',
                      icon: Icons.description_rounded,
                      isDark: isDark,
                      maxLines: 3,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 32),

                    // Time selector
                    _buildLabel('Horário (opcional)', isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeButton(
                            label: 'Início',
                            time: _startTime,
                            onTap: () => _selectTime(true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeButton(
                            label: 'Fim',
                            time: _endTime,
                            onTap: () => _selectTime(false),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Salvar Palestra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.accentColor, width: 2),
        ),
        prefixIcon: maxLines > 1
            ? Padding(
                padding: EdgeInsets.only(bottom: (maxLines - 1) * 24.0),
                child: Icon(icon, color: widget.accentColor),
              )
            : Icon(icon, color: widget.accentColor),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required DateTime? time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final hasTime = time != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: hasTime
              ? widget.accentColor.withAlpha(20)
              : (isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime ? widget.accentColor.withAlpha(60) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 20,
              color: hasTime
                  ? widget.accentColor
                  : (isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              hasTime ? DateFormat('HH:mm').format(time!) : label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: hasTime ? FontWeight.w600 : FontWeight.normal,
                color: hasTime
                    ? widget.accentColor
                    : (isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
