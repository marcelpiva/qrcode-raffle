import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/entities/raffle.dart';
import '../../providers/events_provider.dart';
import '../../providers/raffle_provider.dart';
import '../shared/confirmation_screen.dart';

// NAVA SUMMIT colors (top-level for access by helper widgets)
const Color _primaryPurple = Color(0xFF9333EA);
const Color _primaryPink = Color(0xFFDB2777);
const Color _darkBg = Color(0xFF09090B);
const Color _cardBg = Color(0xFF18181B);
const Color _successGreen = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _infoBlue = Color(0xFF3B82F6);
const Color _errorRed = Color(0xFFEF4444);

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with WidgetsBindingObserver {
  String get eventId => widget.eventId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      ref.read(eventDetailProvider(eventId).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventDetailProvider(eventId));

    ref.listen<EventDetailState>(
      eventDetailProvider(eventId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: _errorRed,
            ),
          );
          ref.read(eventDetailProvider(eventId).notifier).clearActionError();
        }
      },
    );

    return Scaffold(
      backgroundColor: _darkBg,
      body: _buildContent(context, ref, state),
      floatingActionButton: state.event != null
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [_primaryPurple, _primaryPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPurple.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await context.push('/admin/events/$eventId/tracks/new');
                  // Refresh when returning from create screen
                  ref.read(eventDetailProvider(eventId).notifier).refresh();
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nova Trilha',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, EventDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryPurple),
      );
    }

    if (state.error != null) {
      return _buildError(context, ref, state.error!);
    }

    if (state.event == null) {
      return Center(
        child: Text(
          'Evento não encontrado',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      );
    }

    // Get raffles for this event
    final raffleState = ref.watch(raffleListProvider);
    final eventRaffles = raffleState.raffles
        .where((r) => r.eventId == eventId ||
            (r.talkId != null && state.tracks.any((t) =>
                t.talks?.any((talk) => talk.id == r.talkId) ?? false)))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(eventDetailProvider(eventId).notifier).refresh();
        await ref.read(raffleListProvider.notifier).refresh();
      },
      color: _primaryPurple,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: _buildHeader(context, ref, state.event!),
          ),
          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _buildStatsSection(context, state.event!)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),
            ),
          ),
          // Tracks
          SliverToBoxAdapter(
            child: _buildTracksSection(context, ref, state)
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),
          ),
          // Raffles
          SliverToBoxAdapter(
            child: _buildRafflesSection(context, ref, eventRaffles)
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms),
          ),
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Event event) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPurple, _primaryPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(eventDetailProvider(eventId).notifier).refresh(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        color: _cardBg,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: _errorRed),
                                const SizedBox(width: 8),
                                Text('Excluir Evento', style: TextStyle(color: _errorRed)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            final state = ref.read(eventDetailProvider(eventId));
                            if (state.event != null) {
                              _showDeleteEventDialog(context, ref, state.event!, state.tracks.length);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Event icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(event),
                ],
              ).animate()
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: -0.1, end: 0, duration: 300.ms),
              const SizedBox(height: 16),
              // Event name
              Text(
                event.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ).animate()
                  .fadeIn(delay: 100.ms, duration: 300.ms)
                  .slideX(begin: -0.1, end: 0, delay: 100.ms, duration: 300.ms),
              // Location
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 150.ms, duration: 300.ms),
              ],
              // Description
              if (event.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  event.description!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),
              ],
              // Date range
              if (event.startDate != null || event.endDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getDateRangeText(event),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(delay: 250.ms, duration: 300.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 250.ms, duration: 300.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Event event) {
    String label;
    IconData icon;
    List<Color> colors;

    if (event.hasEnded) {
      label = 'Encerrado';
      icon = Icons.check_circle;
      colors = [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    } else if (event.isOngoing) {
      label = 'Ativo';
      icon = Icons.play_circle;
      colors = [_successGreen, const Color(0xFF059669)];
    } else {
      label = 'Em breve';
      icon = Icons.schedule;
      colors = [_infoBlue, const Color(0xFF2563EB)];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: _primaryPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Estatísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _GlassStatCard(
                title: 'Trilhas',
                value: '${event.totalTracks}',
                icon: Icons.layers_outlined,
                gradient: [_primaryPurple, const Color(0xFF7C3AED)],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassStatCard(
                title: 'Palestras',
                value: '${event.totalTalks}',
                icon: Icons.mic_outlined,
                gradient: [_infoBlue, const Color(0xFF2563EB)],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassStatCard(
                title: 'Presenças',
                value: '${event.totalAttendances}',
                icon: Icons.people_outline,
                gradient: [_successGreen, const Color(0xFF059669)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTracksSection(BuildContext context, WidgetRef ref, EventDetailState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: _warningOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Trilhas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${state.tracks.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.tracks.isEmpty)
            _buildEmptyTracks(context)
          else
            Column(
              children: state.tracks.asMap().entries.map((entry) {
                final index = entry.key;
                final track = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TrackCard(
                    track: track,
                    onTap: () => context.push('/admin/tracks/${track.id}'),
                    onDelete: () => _showDeleteTrackDialog(context, ref, track),
                  ).animate()
                      .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                      .slideX(begin: 0.05, end: 0, delay: (50 * index).ms, duration: 300.ms),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTracks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_warningOrange.withOpacity(0.2), _warningOrange.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _warningOrange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.layers_outlined,
              size: 36,
              color: _warningOrange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma trilha criada',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adicione trilhas para organizar suas palestras',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRafflesSection(BuildContext context, WidgetRef ref, List<Raffle> raffles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_outlined,
                  color: _primaryPink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Sorteios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/admin/raffles/create?eventId=$eventId'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: _primaryPink, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Criar',
                        style: TextStyle(
                          color: _primaryPink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (raffles.isEmpty)
            _buildEmptyRaffles(context)
          else
            Column(
              children: raffles.asMap().entries.map((entry) {
                final index = entry.key;
                final raffle = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RaffleCard(
                    raffle: raffle,
                    onTap: () => context.push('/admin/raffles/${raffle.id}'),
                  ).animate()
                      .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                      .slideX(begin: 0.05, end: 0, delay: (50 * index).ms, duration: 300.ms),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRaffles(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryPink.withOpacity(0.2), _primaryPink.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primaryPink.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.card_giftcard_outlined,
              size: 36,
              color: _primaryPink,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum sorteio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie sorteios para premiar os participantes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Container(
      color: _darkBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _errorRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: _errorRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => ref.read(eventDetailProvider(eventId).notifier).refresh(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPurple, _primaryPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tentar novamente',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeText(Event event) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    if (event.startDate != null && event.endDate != null) {
      return '${dateFormat.format(event.startDate!)} - ${dateFormat.format(event.endDate!)}';
    } else if (event.startDate != null) {
      return 'Início: ${dateFormat.format(event.startDate!)}';
    } else if (event.endDate != null) {
      return 'Término: ${dateFormat.format(event.endDate!)}';
    }
    return '';
  }

  Future<void> _showDeleteTrackDialog(BuildContext context, WidgetRef ref, Track track) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Excluir trilha?',
      message: 'Tem certeza que deseja excluir "${track.name}"?',
      subtitle: 'Todas as palestras desta trilha serão excluídas. Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed) {
      ref.read(eventDetailProvider(eventId).notifier).deleteTrack(track.id);
    }
  }

  Future<void> _showDeleteEventDialog(BuildContext context, WidgetRef ref, Event event, int tracksCount) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Excluir evento?',
      message: 'Tem certeza que deseja excluir "${event.name}"?',
      subtitle: 'Serão excluídos: $tracksCount trilhas, ${event.totalTalks} palestras e ${event.totalAttendances} presenças. Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Excluindo evento...'),
            ],
          ),
          backgroundColor: _cardBg,
          duration: const Duration(seconds: 10),
        ),
      );

      try {
        await ref.read(eventsListProvider.notifier).deleteEvent(event.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento excluído com sucesso'),
              backgroundColor: _successGreen,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir evento: $e'),
              backgroundColor: _errorRed,
            ),
          );
        }
      }
    }
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _GlassStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TrackCard({
    required this.track,
    required this.onTap,
    required this.onDelete,
  });

  Color get trackColor {
    if (track.color == null) return _primaryPurple;
    try {
      return Color(int.parse(track.color!.replaceAll('#', '0xFF')));
    } catch (_) {
      return _primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [trackColor, trackColor.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      track.description!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        Icons.mic_outlined,
                        '${track.totalTalks} palestras',
                        _infoBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        Icons.people_outline,
                        '${track.totalAttendances}',
                        _successGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              color: _cardBg,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: _errorRed, size: 18),
                      const SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: _errorRed)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RaffleCard extends StatelessWidget {
  final Raffle raffle;
  final VoidCallback onTap;

  const _RaffleCard({
    required this.raffle,
    required this.onTap,
  });

  (Color, IconData, String) get statusInfo {
    switch (raffle.status) {
      case RaffleStatus.active:
        return (_successGreen, Icons.play_circle, 'Aberto');
      case RaffleStatus.closed:
        return (_warningOrange, Icons.lock_clock, 'Fechado');
      case RaffleStatus.drawn:
        return (_infoBlue, Icons.emoji_events, 'Sorteado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon, statusLabel) = statusInfo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Raffle icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.2),
                    statusColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.card_giftcard,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Raffle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffle.prize,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Participants
                      Icon(
                        Icons.people_outline,
                        size: 13,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${raffle.totalParticipants}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  // Winner
                  if (raffle.winner != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 13,
                          color: _warningOrange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            raffle.winner!.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
