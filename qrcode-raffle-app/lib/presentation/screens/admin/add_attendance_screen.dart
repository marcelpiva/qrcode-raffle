import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/attendance_model.dart';
import '../../providers/events_provider.dart';

class AddAttendanceScreen extends ConsumerStatefulWidget {
  final String talkId;

  const AddAttendanceScreen({
    super.key,
    required this.talkId,
  });

  @override
  ConsumerState<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends ConsumerState<AddAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Presença'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova Presença',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registre a presença de um participante',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                hintText: 'email@exemplo.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email é obrigatório';
                }
                if (!value.contains('@')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: João Silva',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Duração
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duração (minutos)',
                hintText: 'Ex: 60',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.timer_outlined),
                helperText: 'Tempo de permanência na palestra',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // Botão Adicionar
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check),
                          SizedBox(width: 8),
                          Text(
                            'Adicionar Presença',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateAttendanceRequest(
        email: _emailController.text.toLowerCase().trim(),
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        durationMinutes: int.tryParse(_durationController.text),
      );

      await ref.read(talkDetailProvider(widget.talkId).notifier).addAttendance(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presença de "${_emailController.text}" adicionada!')),
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
