import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class TrackFormData {
  final String name;
  final String description;
  final Color color;

  TrackFormData({
    this.name = '',
    this.description = '',
    this.color = AppColors.primary,
  });

  TrackFormData copyWith({
    String? name,
    String? description,
    Color? color,
  }) {
    return TrackFormData(
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }
}

class TrackFormScreen extends StatefulWidget {
  final TrackFormData? initialData;
  final String title;

  const TrackFormScreen({
    super.key,
    this.initialData,
    this.title = 'Nova Trilha',
  });

  static Future<TrackFormData?> show({
    required BuildContext context,
    TrackFormData? initialData,
    String? title,
  }) async {
    return Navigator.of(context).push<TrackFormData>(
      MaterialPageRoute(
        builder: (_) => TrackFormScreen(
          initialData: initialData,
          title: title ?? (initialData?.name.isNotEmpty == true ? 'Editar Trilha' : 'Nova Trilha'),
        ),
      ),
    );
  }

  @override
  State<TrackFormScreen> createState() => _TrackFormScreenState();
}

class _TrackFormScreenState extends State<TrackFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late Color _selectedColor;

  static const List<Color> _trackColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.info,
    AppColors.warning,
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _descController = TextEditingController(text: widget.initialData?.description ?? '');
    _selectedColor = widget.initialData?.color ?? AppColors.primary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nome da trilha é obrigatório'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    Navigator.of(context).pop(TrackFormData(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      color: _selectedColor,
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
                    // Color preview header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _selectedColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedColor.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.layers_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty ? 'Nome da Trilha' : _nameController.text,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                                if (_descController.text.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _descController.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppColors.mutedForegroundDark : AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 32),

                    // Name field
                    Text(
                      'Nome da Trilha',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ex: Inteligência Artificial',
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _selectedColor, width: 2),
                        ),
                        prefixIcon: Icon(Icons.title_rounded, color: _selectedColor),
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // Description field
                    Text(
                      'Descrição (opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      onChanged: (_) => setState(() {}),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Descreva a trilha...',
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _selectedColor, width: 2),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_rounded, color: _selectedColor),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    // Color selector
                    Text(
                      'Cor da Trilha',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _trackColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withAlpha(100),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                                : null,
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 300.ms),
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
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Salvar Trilha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
