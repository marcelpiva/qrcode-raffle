import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/raffle_model.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/talk.dart';
import '../../providers/raffle_provider.dart';
import '../../providers/events_provider.dart';

enum RaffleType { event, talk }

class CreateRaffleScreen extends ConsumerStatefulWidget {
  final String? initialEventId;
  final String? initialTalkId;

  const CreateRaffleScreen({
    super.key,
    this.initialEventId,
    this.initialTalkId,
  });

  @override
  ConsumerState<CreateRaffleScreen> createState() => _CreateRaffleScreenState();
}

class _CreateRaffleScreenState extends ConsumerState<CreateRaffleScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _initialized = false;

  // Step 0: Event Selection
  Event? _selectedEvent;

  // Step 1: Type Selection
  RaffleType? _raffleType;

  // Step 2: Configuration
  // For event type:
  int _minDurationMinutes = 0;
  int _minTalksCount = 1;
  bool _allowLinkRegistration = true;
  int? _eligibleCount;
  bool _isLoadingEligible = false;

  /// Returns the count of talks that have at least one attendance
  int get _talksWithAttendanceCount {
    if (_selectedEvent == null) return 1;
    int count = 0;
    for (final track in _selectedEvent!.tracks ?? []) {
      for (final talk in track.talks ?? []) {
        if ((talk.attendanceCount ?? 0) > 0) {
          count++;
        }
      }
    }
    return count > 0 ? count : 1;
  }

  // For talk type:
  Talk? _selectedTalk;
  String _talkSearchQuery = '';

  // Step 3: Prize Details
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prizeController = TextEditingController();
  final _allowedDomainController = TextEditingController();
  bool _useSchedule = false;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _autoDrawOnEnd = false;
  bool _requireConfirmation = false;
  int _confirmationTimeout = 60;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prizeController.dispose();
    _allowedDomainController.dispose();
    super.dispose();
  }

  void _initializeFromParams(List<Event> events) {
    _initialized = true;

    // If only talkId is provided (without eventId), search for the talk in all events
    if (widget.initialTalkId != null && widget.initialEventId == null) {
      for (final event in events) {
        for (final track in event.tracks ?? []) {
          for (final talk in track.talks ?? []) {
            if (talk.id == widget.initialTalkId) {
              setState(() {
                _selectedEvent = event;
                _raffleType = RaffleType.talk;
                _selectedTalk = talk;
                _currentStep = 2; // Skip to configuration step
              });
              Future.microtask(() => _loadEligibleCount());
              return;
            }
          }
        }
      }
      // Talk not found, stay on step 0
      return;
    }

    // If eventId is provided, pre-select the event
    if (widget.initialEventId != null) {
      final event = events.firstWhere(
        (e) => e.id == widget.initialEventId,
        orElse: () => events.first,
      );

      setState(() {
        _selectedEvent = event;

        // If talkId is also provided, pre-select the talk and skip to step 2
        if (widget.initialTalkId != null) {
          _raffleType = RaffleType.talk;
          // Find the talk in the event's tracks
          for (final track in event.tracks ?? []) {
            for (final talk in track.talks ?? []) {
              if (talk.id == widget.initialTalkId) {
                _selectedTalk = talk;
                _currentStep = 2; // Skip to configuration step
                return;
              }
            }
          }
          // Talk not found, still skip to step 1
          _currentStep = 1;
        } else {
          // Only eventId provided, skip to step 1 (type selection)
          _currentStep = 1;
        }
      });

      // Load eligible count after selecting event
      Future.microtask(() => _loadEligibleCount());
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createRaffleProvider);
    final eventsState = ref.watch(eventsListProvider);

    // Initialize from URL parameters once events are loaded
    if (!_initialized && !eventsState.isLoading && eventsState.events.isNotEmpty) {
      _initializeFromParams(eventsState.events);
    }

    ref.listen<CreateRaffleState>(
      createRaffleProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (next.createdRaffle != null && previous?.createdRaffle == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sorteio criado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/admin/raffles/${next.createdRaffle!.id}');
          ref.read(raffleListProvider.notifier).refresh();
          ref.read(createRaffleProvider.notifier).reset();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sorteio'),
        actions: [
          TextButton(
            onPressed: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
            child: Text(
              'Voltar',
              style: TextStyle(
                color: _currentStep > 0 ? null : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _StepIndicator(
              currentStep: _currentStep,
              totalSteps: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStep(eventsState),
              ),
            ),
            _buildBottomButton(createState),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(EventsListState eventsState) {
    switch (_currentStep) {
      case 0:
        return _buildStep0EventSelection(eventsState).animate().fadeIn(duration: 300.ms);
      case 1:
        return _buildStep1TypeSelection().animate().fadeIn(duration: 300.ms);
      case 2:
        return _buildStep2Configuration().animate().fadeIn(duration: 300.ms);
      case 3:
        return _buildStep3PrizeDetails().animate().fadeIn(duration: 300.ms);
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================================
  // Step 0: Event Selection
  // ============================================================================

  Widget _buildStep0EventSelection(EventsListState eventsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecionar Evento',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha o evento para criar o sorteio',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        if (eventsState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (eventsState.error != null)
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(eventsState.error!, style: TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(eventsListProvider.notifier).refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        else if (eventsState.events.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, color: Colors.grey[400], size: 64),
                const SizedBox(height: 16),
                Text(
                  'Nenhum evento encontrado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie um evento primeiro para poder criar sorteios',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...eventsState.events.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    final isSelected = _selectedEvent?.id == event.id;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final participantCount = event.totalAttendances;
    final talksCount = event.tracks?.fold<int>(
            0, (sum, track) => sum + (track.talks?.length ?? 0)) ??
        0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final inactiveBackground = isDark ? Colors.grey[800] : Colors.grey[100];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedEvent = event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : inactiveBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (event.startDate != null || event.endDate != null)
                          Text(
                            event.startDate != null && event.endDate != null
                                ? '${dateFormat.format(event.startDate!)} - ${dateFormat.format(event.endDate!)}'
                                : event.startDate != null
                                    ? 'Inicia: ${dateFormat.format(event.startDate!)}'
                                    : 'Termina: ${dateFormat.format(event.endDate!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadge(
                    icon: Icons.people,
                    text: '$participantCount participantes',
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    icon: Icons.mic,
                    text: '$talksCount palestras',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Step 1: Type Selection
  // ============================================================================

  Widget _buildStep1TypeSelection() {
    if (_selectedEvent == null) return const SizedBox.shrink();

    final participantCount = _selectedEvent!.totalAttendances;
    final talksCount = _selectedEvent!.tracks?.fold<int>(
            0, (sum, track) => sum + (track.talks?.length ?? 0)) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Sorteio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha como os participantes serão selecionados',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Event type card
        _buildTypeCard(
          type: RaffleType.event,
          icon: Icons.public,
          title: 'Sorteio por Evento',
          subtitle: 'Participantes de todas as palestras do evento',
          badgeText: '$participantCount participantes',
          badgeColor: AppColors.primary,
        ),
        const SizedBox(height: 12),

        // Talk type card
        _buildTypeCard(
          type: RaffleType.talk,
          icon: Icons.mic,
          title: 'Sorteio por Palestra',
          subtitle: 'Participantes de uma palestra específica',
          badgeText: '$talksCount palestras',
          badgeColor: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required RaffleType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    final isSelected = _raffleType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final inactiveBackground = isDark ? Colors.grey[800] : Colors.grey[100];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? badgeColor : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _raffleType = type;
          _selectedTalk = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? badgeColor.withOpacity(0.1)
                      : inactiveBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? badgeColor : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected ? badgeColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBadge(
                      icon: type == RaffleType.event ? Icons.people : Icons.mic,
                      text: badgeText,
                      color: badgeColor,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Step 2: Configuration
  // ============================================================================

  Widget _buildStep2Configuration() {
    if (_raffleType == RaffleType.event) {
      return _buildEventConfiguration();
    } else {
      return _buildTalkConfiguration();
    }
  }

  Widget _buildEventConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros de Elegibilidade',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure os critérios para participar do sorteio',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Min duration per talk - Slider
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.timer_outlined, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tempo mínimo por palestra',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _minDurationMinutes == 0 ? 'Qualquer' : '${_minDurationMinutes}min',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _minDurationMinutes.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 4,
                    label: _minDurationMinutes == 0 ? 'Qualquer' : '${_minDurationMinutes}min',
                    onChanged: (value) {
                      setState(() => _minDurationMinutes = value.toInt());
                    },
                    onChangeEnd: (value) => _loadEligibleCount(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    Text('15', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    Text('30', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    Text('45', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    Text('60', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Min talks count - Slider
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.format_list_numbered, size: 20, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mínimo de palestras',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_minTalksCount ${_minTalksCount == 1 ? 'palestra' : 'palestras'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final maxTalks = _talksWithAttendanceCount;
                    final divisions = maxTalks > 1 ? maxTalks - 1 : 1;
                    // Clamp current value to max
                    if (_minTalksCount > maxTalks) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _minTalksCount = maxTalks);
                      });
                    }
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.secondary,
                            inactiveTrackColor: AppColors.secondary.withOpacity(0.2),
                            thumbColor: AppColors.secondary,
                            overlayColor: AppColors.secondary.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _minTalksCount.toDouble().clamp(1, maxTalks.toDouble()),
                            min: 1,
                            max: maxTalks.toDouble(),
                            divisions: divisions,
                            label: '$_minTalksCount',
                            onChanged: maxTalks > 1
                              ? (value) {
                                  setState(() => _minTalksCount = value.toInt());
                                }
                              : null,
                            onChangeEnd: (value) => _loadEligibleCount(),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            maxTalks,
                            (i) => Text(
                              '${i + 1}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Domain filter
        _buildLabel('Filtro de E-mail', required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: _allowedDomainController,
          decoration: _inputDecoration(
            hintText: 'Ex: empresa.com.br',
            prefixIcon: Icons.email,
            helperText: 'Apenas e-mails deste domínio poderão participar',
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => _loadEligibleCount(),
        ),
        const SizedBox(height: 24),

        // Allow link registration
        Card(
          child: SwitchListTile(
            value: _allowLinkRegistration,
            onChanged: (value) => setState(() => _allowLinkRegistration = value),
            title: const Text('Permitir inscrições por link'),
            subtitle: const Text(
              'Participantes podem se inscrever via QR code do sorteio',
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: AppColors.info),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Eligible count card
        _buildEligibleCountCard(),
      ],
    );
  }

  Widget _buildEligibleCountCard() {
    final totalParticipants = _selectedEvent?.totalAttendances ?? 0;
    final theme = Theme.of(context);

    return Card(
      color: AppColors.success.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingEligible
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.people,
                      color: AppColors.success,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Participantes Elegíveis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eligibleCount != null
                        ? '$_eligibleCount de $totalParticipants'
                        : 'Carregando...',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadEligibleCount,
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar contagem',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadEligibleCount() async {
    if (_selectedEvent == null) return;

    setState(() => _isLoadingEligible = true);

    try {
      debugPrint('Loading eligible count with: minDuration=$_minDurationMinutes, minTalks=$_minTalksCount, domain=${_allowedDomainController.text.trim()}');

      final eventDetailNotifier =
          ref.read(eventDetailProvider(_selectedEvent!.id).notifier);
      await eventDetailNotifier.getEligibleCount(
        minDurationMinutes: _minDurationMinutes > 0 ? _minDurationMinutes : null,
        minTalksCount: _minTalksCount > 1 ? _minTalksCount : null,
        allowedDomain: _allowedDomainController.text.trim().isEmpty
            ? null
            : _allowedDomainController.text.trim(),
      );

      final state = ref.read(eventDetailProvider(_selectedEvent!.id));
      debugPrint('Got eligible count: ${state.eligibleCount}');

      setState(() {
        _eligibleCount = state.eligibleCount;
        _isLoadingEligible = false;
      });
    } catch (e) {
      debugPrint('Error loading eligible count: $e');
      setState(() => _isLoadingEligible = false);
    }
  }

  Widget _buildTalkConfiguration() {
    final tracks = _selectedEvent?.tracks ?? [];
    final allTalks = <Talk>[];
    for (final track in tracks) {
      allTalks.addAll(track.talks ?? []);
    }

    // Show all talks, filter by search query
    final filteredTalks = _talkSearchQuery.isEmpty
        ? allTalks
        : allTalks.where((talk) {
            final query = _talkSearchQuery.toLowerCase();
            return talk.title.toLowerCase().contains(query) ||
                (talk.speaker?.toLowerCase().contains(query) ?? false);
          }).toList();

    // Sort: talks with participants first
    filteredTalks.sort((a, b) {
      final countA = a.attendanceCount ?? a.attendances?.length ?? 0;
      final countB = b.attendanceCount ?? b.attendances?.length ?? 0;
      return countB.compareTo(countA);
    });

    final talksWithParticipants = allTalks.where((talk) {
      final count = talk.attendanceCount ?? talk.attendances?.length ?? 0;
      return count > 0;
    }).length;
    final talksWithoutParticipants = allTalks.length - talksWithParticipants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecionar Palestra',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha a palestra para o sorteio',
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (talksWithoutParticipants > 0) ...[
          const SizedBox(height: 8),
          Text(
            '$talksWithoutParticipants ${talksWithoutParticipants == 1 ? 'palestra' : 'palestras'} ainda sem participantes',
            style: TextStyle(color: Colors.orange[700], fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),

        // Search field
        TextFormField(
          decoration: _inputDecoration(
            hintText: 'Buscar palestra...',
            prefixIcon: Icons.search,
          ),
          onChanged: (value) => setState(() => _talkSearchQuery = value),
        ),
        const SizedBox(height: 16),

        // Domain filter
        _buildLabel('Filtro de E-mail', required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: _allowedDomainController,
          decoration: _inputDecoration(
            hintText: 'Ex: empresa.com.br',
            prefixIcon: Icons.email,
            helperText: 'Apenas e-mails deste domínio poderão participar',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 24),

        // Talks list
        if (filteredTalks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.mic_off, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _talkSearchQuery.isEmpty
                        ? 'Nenhuma palestra nesta trilha'
                        : 'Nenhuma palestra encontrada',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredTalks.map((talk) => _buildTalkCard(talk)),
      ],
    );
  }

  Widget _buildTalkCard(Talk talk) {
    final isSelected = _selectedTalk?.id == talk.id;
    final attendanceCount = talk.attendanceCount ?? talk.attendances?.length ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedTalk = talk),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: talk.id,
                groupValue: _selectedTalk?.id,
                onChanged: (_) => setState(() => _selectedTalk = talk),
                activeColor: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      talk.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.secondary : null,
                      ),
                    ),
                    if (talk.speaker != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        talk.speaker!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildBadge(
                icon: Icons.people,
                text: '$attendanceCount',
                color: AppColors.info,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Step 3: Prize Details
  // ============================================================================

  Widget _buildStep3PrizeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhes do Sorteio',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure o prêmio e opções do sorteio',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Name field
        _buildLabel('Nome do Sorteio', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration(
            hintText: 'Ex: Sorteio do iPhone 15',
            prefixIcon: Icons.title,
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nome é obrigatório';
            }
            if (value.length < 3) {
              return 'Nome deve ter pelo menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Prize field
        _buildLabel('Prêmio', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _prizeController,
          decoration: _inputDecoration(
            hintText: 'Ex: iPhone 15 Pro Max 256GB',
            prefixIcon: Icons.emoji_events,
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Prêmio é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Description field
        _buildLabel('Descrição', required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: _inputDecoration(
            hintText: 'Descreva o sorteio (opcional)',
            prefixIcon: Icons.description,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),

        // Schedule section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agendamento',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Defina quando o sorteio abre e fecha',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useSchedule,
                      onChanged: (value) => setState(() {
                        _useSchedule = value;
                        if (!value) {
                          _startsAt = null;
                          _endsAt = null;
                          _autoDrawOnEnd = false;
                        }
                      }),
                    ),
                  ],
                ),
                if (_useSchedule) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DateTimePicker(
                    label: 'Abre em',
                    value: _startsAt,
                    onChanged: (dt) => setState(() => _startsAt = dt),
                  ),
                  const SizedBox(height: 16),
                  _DateTimePicker(
                    label: 'Fecha em',
                    value: _endsAt,
                    onChanged: (dt) => setState(() => _endsAt = dt),
                    minDate: _startsAt ?? DateTime.now(),
                  ),
                  if (_endsAt != null) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _autoDrawOnEnd,
                      onChanged: (value) =>
                          setState(() => _autoDrawOnEnd = value),
                      title: const Text('Sortear automaticamente'),
                      subtitle: const Text(
                        'O sorteio será realizado quando o prazo acabar',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirmation section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirmação de Presença',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'O ganhador deve confirmar presença com PIN',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _requireConfirmation,
                      onChanged: (value) =>
                          setState(() => _requireConfirmation = value),
                    ),
                  ],
                ),
                if (_requireConfirmation) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildLabel('Tempo para confirmar (segundos)', required: false),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _confirmationTimeout.toDouble(),
                          min: 30,
                          max: 300,
                          divisions: 27,
                          label: '$_confirmationTimeout s',
                          onChanged: (value) =>
                              setState(() => _confirmationTimeout = value.toInt()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_confirmationTimeout s',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Summary card
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.summarize,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resumo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryItem(
              label: 'Evento',
              value: _selectedEvent?.name ?? '-',
            ),
            _SummaryItem(
              label: 'Tipo',
              value: _raffleType == RaffleType.event
                  ? 'Sorteio por Evento'
                  : 'Sorteio por Palestra',
            ),
            if (_raffleType == RaffleType.talk && _selectedTalk != null)
              _SummaryItem(
                label: 'Palestra',
                value: _selectedTalk!.title,
              ),
            if (_raffleType == RaffleType.event) ...[
              if (_minDurationMinutes > 0)
                _SummaryItem(
                  label: 'Tempo mínimo',
                  value: '${_minDurationMinutes}min por palestra',
                ),
              if (_minTalksCount > 1)
                _SummaryItem(
                  label: 'Palestras mínimas',
                  value: '$_minTalksCount palestras',
                ),
              if (_eligibleCount != null)
                _SummaryItem(
                  label: 'Elegíveis',
                  value: '$_eligibleCount participantes',
                  valueColor: AppColors.success,
                ),
            ],
            if (_allowedDomainController.text.isNotEmpty)
              _SummaryItem(
                label: 'Domínio',
                value: '@${_allowedDomainController.text}',
              ),
            if (_useSchedule && _startsAt != null)
              _SummaryItem(
                label: 'Abre às',
                value: timeFormat.format(_startsAt!),
              ),
            if (_useSchedule && _endsAt != null)
              _SummaryItem(
                label: 'Fecha às',
                value: timeFormat.format(_endsAt!),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Bottom Button
  // ============================================================================

  Widget _buildBottomButton(CreateRaffleState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: state.isCreating || !_canProceed() ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _currentStep == 3 ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isCreating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 3 ? 'Criar Sorteio' : 'Continuar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedEvent != null;
      case 1:
        return _raffleType != null;
      case 2:
        if (_raffleType == RaffleType.talk) {
          return _selectedTalk != null;
        }
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_selectedEvent != null) {
        setState(() => _currentStep++);
        _loadEligibleCount();
      }
    } else if (_currentStep == 1) {
      if (_raffleType != null) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 2) {
      if (_raffleType == RaffleType.talk && _selectedTalk == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione uma palestra'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      if (_formKey.currentState!.validate()) {
        // Validate schedule dates
        if (_useSchedule && _endsAt != null && _startsAt != null) {
          if (_endsAt!.isBefore(_startsAt!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data de fechamento deve ser após a abertura'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
        }
        _createRaffle();
      }
    }
  }

  void _createRaffle() {
    final request = CreateRaffleRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      prize: _prizeController.text.trim(),
      allowedDomain: _allowedDomainController.text.trim().isEmpty
          ? null
          : _allowedDomainController.text.trim(),
      startsAt: _useSchedule ? _startsAt : null,
      endsAt: _useSchedule ? _endsAt : null,
      autoDrawOnEnd: _useSchedule && _autoDrawOnEnd,
      requireConfirmation: _requireConfirmation,
      confirmationTimeoutMinutes:
          _requireConfirmation ? (_confirmationTimeout ~/ 60).clamp(1, 5) : null,
      // Event/Talk specific
      eventId: _raffleType == RaffleType.event ? _selectedEvent!.id : null,
      talkId: _raffleType == RaffleType.talk ? _selectedTalk!.id : null,
      minDurationMinutes: _raffleType == RaffleType.event && _minDurationMinutes > 0
          ? _minDurationMinutes
          : null,
      minTalksCount: _raffleType == RaffleType.event && _minTalksCount > 1
          ? _minTalksCount
          : null,
      allowLinkRegistration: _raffleType == RaffleType.event
          ? _allowLinkRegistration
          : true,
    );

    ref.read(createRaffleProvider.notifier).createRaffle(request);
  }

  // ============================================================================
  // Helper Widgets
  // ============================================================================

  Widget _buildLabel(String text, {required bool required}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      helperText: helperText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}

// ============================================================================
// Supporting Widgets
// ============================================================================

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final steps = ['Evento', 'Tipo', 'Filtros', 'Prêmio'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.grey[700] : Colors.grey[200];
    final inactiveTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          final isComplete = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : inactiveColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isComplete
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : inactiveTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: isComplete ? AppColors.primary : inactiveColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? minDate;

  const _DateTimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value != null
            ? TimeOfDay.fromDateTime(value!)
            : TimeOfDay.now(),
        );
        if (time != null) {
          // Use today's date with the selected time
          onChanged(DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          ));
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
            Icon(Icons.access_time, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? timeFormat.format(value!) : 'Selecionar hora',
                    style: TextStyle(
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null ? null : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onChanged(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
