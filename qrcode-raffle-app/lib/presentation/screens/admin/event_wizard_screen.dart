import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/track_model.dart';
import '../../../data/models/talk_model.dart';
import '../../../domain/entities/event.dart';
import '../../providers/events_provider.dart';
import '../../../data/services/event_service.dart';
import '../shared/track_form_screen.dart';
import '../shared/talk_form_screen.dart';

class EventWizardScreen extends ConsumerStatefulWidget {
  const EventWizardScreen({super.key});

  @override
  ConsumerState<EventWizardScreen> createState() => _EventWizardScreenState();
}

class _EventWizardScreenState extends ConsumerState<EventWizardScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 0: Event
  final _eventFormKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  Event? _createdEvent;

  // Step 1: Tracks
  final List<_TrackFormData> _tracks = [];

  // Step 2: Talks
  final Map<String, List<_TalkFormData>> _talksByTrack = {};

  // Colors for tracks
  final List<Color> _trackColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.info,
    AppColors.warning,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.orange,
  ];

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Criar Evento';
      case 1:
        return 'Adicionar Trilhas';
      case 2:
        return 'Adicionar Palestras';
      case 3:
        return 'Criar Sorteios';
      default:
        return 'Wizard';
    }
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.grey[50],
        border: Border(bottom: BorderSide(color: isDark ? theme.dividerColor : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Evento', Icons.event),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Trilhas', Icons.layers),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Palestras', Icons.mic),
          _buildStepConnector(2),
          _buildStepIndicator(3, 'Sorteios', Icons.casino),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    final color = isActive ? AppColors.primary : Colors.grey[400]!;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? color : color.withAlpha(isCurrent ? 255 : 50),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isCurrent ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppColors.primary : Colors.grey[300],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEventStep();
      case 1:
        return _buildTracksStep();
      case 2:
        return _buildTalksStep();
      case 3:
        return _buildRafflesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================== STEP 0: EVENT ====================
  Widget _buildEventStep() {
    return Form(
      key: _eventFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações do Evento',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Preencha os dados básicos do seu evento',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name
          TextFormField(
            controller: _eventNameController,
            decoration: InputDecoration(
              labelText: 'Nome do evento *',
              hintText: 'Ex: NAVA Summit 2025',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

          // Description
          TextFormField(
            controller: _eventDescriptionController,
            decoration: InputDecoration(
              labelText: 'Descrição',
              hintText: 'Uma breve descrição do evento',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Location
          TextFormField(
            controller: _eventLocationController,
            decoration: InputDecoration(
              labelText: 'Local',
              hintText: 'Ex: Online ou presencial',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 24),

          // Dates
          Text(
            'Período do Evento',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Data de Início',
                  value: _eventStartDate,
                  onChanged: (date) {
                    setState(() {
                      _eventStartDate = date;
                      if (_eventEndDate != null && date != null && _eventEndDate!.isBefore(date)) {
                        _eventEndDate = date;
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
                  value: _eventEndDate,
                  onChanged: (date) => setState(() => _eventEndDate = date),
                  firstDate: _eventStartDate ?? DateTime.now(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STEP 1: TRACKS ====================
  Widget _buildTracksStep() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _createdEvent?.name ?? 'Evento',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_tracks.length} trilha(s) adicionada(s)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addTrack,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Trilha'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Tracks list
        Expanded(
          child: _tracks.isEmpty
              ? _buildEmptyTracksState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) => _buildTrackCard(_tracks[index], index),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyTracksState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.layers_outlined, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma trilha ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione trilhas para organizar suas palestras\nou pule esta etapa',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: _addTrack,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Trilha'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(_TrackFormData track, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: track.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name.isEmpty ? 'Trilha ${index + 1}' : track.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (track.description.isNotEmpty)
                        Text(
                          track.description,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editTrack(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                  onPressed: () => _removeTrack(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addTrack() {
    final track = _TrackFormData(
      color: _trackColors[_tracks.length % _trackColors.length],
    );
    _showTrackDialog(track, (updatedTrack) {
      setState(() => _tracks.add(updatedTrack));
    });
  }

  void _editTrack(int index) {
    _showTrackDialog(_tracks[index], (updatedTrack) {
      setState(() => _tracks[index] = updatedTrack);
    });
  }

  void _removeTrack(int index) {
    setState(() => _tracks.removeAt(index));
  }

  Future<void> _showTrackDialog(_TrackFormData initial, Function(_TrackFormData) onSave) async {
    final result = await TrackFormScreen.show(
      context: context,
      initialData: TrackFormData(
        name: initial.name,
        description: initial.description,
        color: initial.color,
      ),
      title: initial.name.isEmpty ? 'Nova Trilha' : 'Editar Trilha',
    );

    if (result != null) {
      onSave(_TrackFormData(
        name: result.name,
        description: result.description,
        color: result.color,
        tempId: initial.tempId,
      ));
    }
  }

  // ==================== STEP 2: TALKS ====================
  Widget _buildTalksStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_tracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.mic_off, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma trilha criada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Volte e adicione trilhas primeiro\nou pule para criar sorteios',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tracks.length,
      itemBuilder: (context, index) => _buildTrackWithTalks(_tracks[index], index),
    );
  }

  Widget _buildTrackWithTalks(_TrackFormData track, int trackIndex) {
    final talks = _talksByTrack[track.tempId] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: track.color.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: track.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${talks.length} palestra(s)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addTalk(track),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Palestra'),
                ),
              ],
            ),
          ),

          // Talks list
          if (talks.isNotEmpty)
            ...talks.asMap().entries.map((entry) => _buildTalkItem(track, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildTalkItem(_TrackFormData track, int talkIndex, _TalkFormData talk) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: track.color.withAlpha(50),
        child: Icon(Icons.mic, color: track.color, size: 20),
      ),
      title: Text(talk.title.isEmpty ? 'Palestra ${talkIndex + 1}' : talk.title),
      subtitle: talk.speaker.isNotEmpty ? Text(talk.speaker) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editTalk(track, talkIndex),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
            onPressed: () => _removeTalk(track, talkIndex),
          ),
        ],
      ),
    );
  }

  void _addTalk(_TrackFormData track) {
    _showTalkDialog(_TalkFormData(), (talk) {
      setState(() {
        _talksByTrack[track.tempId] ??= [];
        _talksByTrack[track.tempId]!.add(talk);
      });
    }, accentColor: track.color);
  }

  void _editTalk(_TrackFormData track, int index) {
    final talks = _talksByTrack[track.tempId] ?? [];
    if (index < talks.length) {
      _showTalkDialog(talks[index], (updatedTalk) {
        setState(() => _talksByTrack[track.tempId]![index] = updatedTalk);
      }, accentColor: track.color);
    }
  }

  void _removeTalk(_TrackFormData track, int index) {
    setState(() {
      _talksByTrack[track.tempId]?.removeAt(index);
    });
  }

  Future<void> _showTalkDialog(_TalkFormData initial, Function(_TalkFormData) onSave, {Color accentColor = AppColors.primary}) async {
    final result = await TalkFormScreen.show(
      context: context,
      initialData: TalkFormData(
        title: initial.title,
        speaker: initial.speaker,
        description: initial.description,
        startTime: initial.startTime,
        endTime: initial.endTime,
      ),
      title: initial.title.isEmpty ? 'Nova Palestra' : 'Editar Palestra',
      accentColor: accentColor,
    );

    if (result != null) {
      onSave(_TalkFormData(
        title: result.title,
        speaker: result.speaker,
        description: result.description,
        startTime: result.startTime,
        endTime: result.endTime,
      ));
    }
  }

  // ==================== STEP 3: RAFFLES ====================
  Widget _buildRafflesStep() {
    final totalTalks = _talksByTrack.values.fold<int>(0, (sum, talks) => sum + talks.length);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text(
              'Evento Configurado!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Resumo:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(Icons.event, _createdEvent?.name ?? _eventNameController.text),
            _buildSummaryItem(Icons.layers, '${_tracks.length} trilha(s)'),
            _buildSummaryItem(Icons.mic, '$totalTalks palestra(s)'),
            const SizedBox(height: 32),
            Text(
              'Sorteios podem ser criados depois\nna página do evento',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  Widget _buildBottomBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  child: const Text('Voltar'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            if (_currentStep > 0 && _currentStep < 3)
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : _skipStep,
                  child: const Text('Pular'),
                ),
              ),
            if (_currentStep > 0 && _currentStep < 3) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 3 ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_getNextButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Criar Evento';
      case 1:
        return 'Continuar';
      case 2:
        return 'Continuar';
      case 3:
        return 'Concluir';
      default:
        return 'Próximo';
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
  }

  void _skipStep() {
    setState(() => _currentStep++);
  }

  Future<void> _nextStep() async {
    switch (_currentStep) {
      case 0:
        await _createEvent();
        break;
      case 1:
        await _createTracks();
        break;
      case 2:
        await _createTalks();
        break;
      case 3:
        _finish();
        break;
    }
  }

  Future<void> _createEvent() async {
    if (!_eventFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreateEventRequest(
        name: _eventNameController.text.trim(),
        description: _eventDescriptionController.text.trim().isEmpty
            ? null
            : _eventDescriptionController.text.trim(),
        location: _eventLocationController.text.trim().isEmpty
            ? null
            : _eventLocationController.text.trim(),
        startDate: _eventStartDate,
        endDate: _eventEndDate,
      );

      final event = await ref.read(eventsListProvider.notifier).createEvent(request);

      if (event != null && mounted) {
        setState(() {
          _createdEvent = event;
          _currentStep = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evento "${event.name}" criado!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createTracks() async {
    if (_createdEvent == null || _tracks.isEmpty) {
      setState(() => _currentStep = 2);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use event dates for tracks, or fallback to today
      final eventStartDate = _eventStartDate ?? DateTime.now();
      final eventEndDate = _eventEndDate ?? DateTime.now();

      for (final track in _tracks) {
        final request = CreateTrackRequest(
          title: track.name,
          description: track.description.isEmpty ? null : track.description,
          color: '#${track.color.value.toRadixString(16).substring(2)}',
          eventId: _createdEvent!.id,
          startDate: eventStartDate,
          endDate: eventEndDate,
        );

        final createdTrack = await ref
            .read(eventDetailProvider(_createdEvent!.id).notifier)
            .createTrack(request);

        if (createdTrack != null) {
          track.createdId = createdTrack.id;
        }
      }

      if (mounted) {
        setState(() => _currentStep = 2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_tracks.length} trilha(s) criada(s)!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createTalks() async {
    if (_createdEvent == null) {
      setState(() => _currentStep = 3);
      return;
    }

    final hasTalks = _talksByTrack.values.any((talks) => talks.isNotEmpty);
    if (!hasTalks) {
      setState(() => _currentStep = 3);
      return;
    }

    setState(() => _isLoading = true);

    try {
      int talkCount = 0;
      final eventService = ref.read(eventServiceProvider);

      for (final track in _tracks) {
        final talks = _talksByTrack[track.tempId] ?? [];
        if (track.createdId == null || talks.isEmpty) continue;

        for (final talk in talks) {
          final request = CreateTalkRequest(
            title: talk.title,
            description: talk.description.isEmpty ? null : talk.description,
            speaker: talk.speaker.isEmpty ? null : talk.speaker,
            startTime: talk.startTime,
            endTime: talk.endTime,
            trackId: track.createdId!,
          );

          await eventService.createTalk(request);
          talkCount++;
        }
      }

      if (mounted) {
        setState(() => _currentStep = 3);
        if (talkCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$talkCount palestra(s) criada(s)!')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _finish() {
    if (_createdEvent != null) {
      context.go('/admin/events/${_createdEvent!.id}');
    } else {
      context.pop();
    }
  }

  void _showExitConfirmation() {
    if (_currentStep == 0 && _eventNameController.text.isEmpty) {
      context.pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Wizard?'),
        content: Text(
          _createdEvent != null
              ? 'O evento já foi criado. Deseja sair?'
              : 'Você perderá os dados preenchidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_createdEvent != null) {
                context.go('/admin/events/${_createdEvent!.id}');
              } else {
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER CLASSES ====================

class _TrackFormData {
  String name;
  String description;
  Color color;
  String? createdId;
  final String tempId;

  _TrackFormData({
    this.name = '',
    this.description = '',
    required this.color,
    this.createdId,
    String? tempId,
  }) : tempId = tempId ?? DateTime.now().millisecondsSinceEpoch.toString();
}

class _TalkFormData {
  String title;
  String speaker;
  String description;
  DateTime? startTime;
  DateTime? endTime;

  _TalkFormData({
    this.title = '',
    this.speaker = '',
    this.description = '',
    this.startTime,
    this.endTime,
  });
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? dateFormat.format(value!) : 'Selecionar',
                    style: TextStyle(
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? null : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.clear, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
}
