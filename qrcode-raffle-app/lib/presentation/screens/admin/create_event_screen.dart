import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../providers/events_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Evento'),
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novo Evento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Crie um evento para organizar trilhas e palestras',
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

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome do evento *',
                hintText: 'Ex: NAVA Summit 2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
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
                hintText: 'Uma breve descrição do evento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Local
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Local',
                hintText: 'Ex: Online ou presencial',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 24),

            // Datas
            Text(
              'Período do Evento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Data de Início',
                    value: _startDate,
                    onChanged: (date) {
                      setState(() {
                        _startDate = date;
                        // Ajusta endDate se necessário
                        if (_endDate != null && date != null && _endDate!.isBefore(date)) {
                          _endDate = date;
                        }
                      });
                    },
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'Data de Término',
                    value: _endDate,
                    onChanged: (date) => setState(() => _endDate = date),
                    firstDate: _startDate ?? DateTime.now(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botão Criar
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                            'Criar Evento',
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

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateEventRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );

      final event = await ref.read(eventsListProvider.notifier).createEvent(request);

      if (event != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evento "${event.name}" criado!')),
        );
        context.pop();
        context.push('/admin/events/${event.id}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final effectiveFirstDate = firstDate ?? DateTime.now();

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? effectiveFirstDate,
          firstDate: effectiveFirstDate.subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? dateFormat.format(value!) : 'Selecionar',
                    style: TextStyle(
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? null : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
}
