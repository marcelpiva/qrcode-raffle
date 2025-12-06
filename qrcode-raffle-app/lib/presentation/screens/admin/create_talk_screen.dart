import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/talk_model.dart';
import '../../providers/events_provider.dart';

class CreateTalkScreen extends ConsumerStatefulWidget {
  final String trackId;

  const CreateTalkScreen({
    super.key,
    required this.trackId,
  });

  @override
  ConsumerState<CreateTalkScreen> createState() => _CreateTalkScreenState();
}

class _CreateTalkScreenState extends ConsumerState<CreateTalkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _speakerController = TextEditingController();
  final _speakerEmailController = TextEditingController();
  final _roomController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  DateTime? _startTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _speakerController.dispose();
    _speakerEmailController.dispose();
    _roomController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Palestra'),
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
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppColors.info,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova Palestra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Adicione uma palestra à trilha',
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

            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título da palestra *',
                hintText: 'Ex: Introdução à IA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Título é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                hintText: 'Uma breve descrição da palestra',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Seção Palestrante
            Text(
              'Palestrante',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // Nome do Palestrante
            TextFormField(
              controller: _speakerController,
              decoration: InputDecoration(
                labelText: 'Nome do palestrante',
                hintText: 'Ex: João Silva',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Email do Palestrante
            TextFormField(
              controller: _speakerEmailController,
              decoration: InputDecoration(
                labelText: 'Email do palestrante',
                hintText: 'email@exemplo.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Seção Horário
            Text(
              'Horário e Local',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // Sala e Duração
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _roomController,
                    decoration: InputDecoration(
                      labelText: 'Sala',
                      hintText: 'Ex: Auditório',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.meeting_room),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Duração (min)',
                      hintText: '60',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horário de Início
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horário de início',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startTime != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(_startTime!)
                                : 'Selecionar data e hora',
                            style: TextStyle(
                              fontWeight: _startTime != null ? FontWeight.w500 : FontWeight.normal,
                              color: _startTime != null
                                  ? null
                                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_startTime != null)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _startTime = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botão Criar
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTalk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
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
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text(
                            'Criar Palestra',
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _startTime != null
            ? TimeOfDay.fromDateTime(_startTime!)
            : TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createTalk() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final duration = int.tryParse(_durationController.text);
      DateTime? endTime;
      if (_startTime != null && duration != null) {
        endTime = _startTime!.add(Duration(minutes: duration));
      }

      final request = CreateTalkRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        speaker: _speakerController.text.trim().isEmpty
            ? null
            : _speakerController.text.trim(),
        speakerEmail: _speakerEmailController.text.trim().isEmpty
            ? null
            : _speakerEmailController.text.trim(),
        room: _roomController.text.trim().isEmpty
            ? null
            : _roomController.text.trim(),
        durationMinutes: duration,
        startTime: _startTime,
        endTime: endTime,
        trackId: widget.trackId,
      );

      await ref.read(trackDetailProvider(widget.trackId).notifier).createTalk(request);

      // Force refresh the provider to reload data from API
      await ref.read(trackDetailProvider(widget.trackId).notifier).refresh();

      // Get the track to find the eventId
      final trackState = ref.read(trackDetailProvider(widget.trackId));
      final eventId = trackState.track?.eventId;

      // Refresh eventDetailProvider so timeline in EventsCarouselScreen updates
      if (eventId != null) {
        ref.invalidate(eventDetailProvider(eventId));
      }

      // Also refresh events list
      await ref.read(eventsListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Palestra "${_titleController.text}" criada!')),
        );
        context.pop(true); // Return true to indicate creation success
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
