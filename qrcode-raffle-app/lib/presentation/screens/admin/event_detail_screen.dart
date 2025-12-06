import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/entities/raffle.dart';
import '../../providers/events_provider.dart';
import '../../providers/raffle_provider.dart';
import '../shared/confirmation_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventDetailProvider(eventId));

    ref.listen<EventDetailState>(
      eventDetailProvider(eventId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(eventDetailProvider(eventId).notifier).clearActionError();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(state.event?.name ?? 'Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventDetailProvider(eventId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Excluir Evento', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete' && state.event != null) {
                _showDeleteEventDialog(context, ref, state.event!, state.tracks.length);
              }
            },
          ),
        ],
      ),
      body: _buildContent(context, ref, state),
      floatingActionButton: state.event != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/events/$eventId/tracks/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nova Trilha'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, EventDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return _buildError(context, ref, state.error!);
    }

    if (state.event == null) {
      return const Center(
        child: Text('Evento não encontrado'),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventHeader(context, state.event!),
            _buildStatsSection(context, state.event!),
            _buildTracksSection(context, ref, state),
            _buildRafflesSection(context, ref, eventRaffles),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader(BuildContext context, Event event) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
            ],
          ),
          if (event.description != null) ...[
            const SizedBox(height: 16),
            Text(
              event.description!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (event.startDate != null || event.endDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
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
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStatsSection(BuildContext context, Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use Row for wide screens, Column for narrow
          if (constraints.maxWidth > 400) {
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.layers,
                    value: '${event.totalTracks}',
                    label: 'Trilhas',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.mic,
                    value: '${event.totalTalks}',
                    label: 'Palestras',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    value: '${event.totalAttendances}',
                    label: 'Presenças',
                    color: AppColors.success,
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _StatCard(
                  icon: Icons.layers,
                  value: '${event.totalTracks}',
                  label: 'Trilhas',
                  color: AppColors.info,
                  horizontal: true,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.mic,
                  value: '${event.totalTalks}',
                  label: 'Palestras',
                  color: AppColors.secondary,
                  horizontal: true,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.people,
                  value: '${event.totalAttendances}',
                  label: 'Presenças',
                  color: AppColors.success,
                  horizontal: true,
                ),
              ],
            );
          }
        },
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildTracksSection(BuildContext context, WidgetRef ref, EventDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Trilhas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (state.tracks.isEmpty)
          _buildEmptyTracks(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.tracks.length,
            itemBuilder: (context, index) {
              final track = state.tracks[index];
              return _TrackCard(
                track: track,
                onTap: () => context.push('/admin/tracks/${track.id}'),
                onDelete: () => _showDeleteTrackDialog(context, ref, track),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * index + 200),
                    duration: const Duration(milliseconds: 300),
                  );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTracks(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma trilha criada',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione trilhas para organizar suas palestras',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRafflesSection(BuildContext context, WidgetRef ref, List<Raffle> raffles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sorteios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/admin/raffles/create?eventId=$eventId'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Criar Sorteio'),
              ),
            ],
          ),
        ),
        if (raffles.isEmpty)
          _buildEmptyRaffles(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: raffles.length,
            itemBuilder: (context, index) {
              final raffle = raffles[index];
              return _RaffleCard(
                raffle: raffle,
                onTap: () => context.push('/admin/raffles/${raffle.id}'),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * index + 400),
                    duration: const Duration(milliseconds: 300),
                  );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyRaffles(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum sorteio',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sorteios para premiar os participantes do evento',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              error,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(eventDetailProvider(eventId).notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
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
        const SnackBar(
          content: Row(
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
          duration: Duration(seconds: 10),
        ),
      );

      try {
        await ref.read(eventsListProvider.notifier).deleteEvent(event.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento excluído com sucesso'),
              backgroundColor: AppColors.success,
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
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool horizontal;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
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
    if (track.color == null) return AppColors.primary;
    try {
      return Color(int.parse(track.color!.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (track.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        track.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                          AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          Icons.people_outline,
                          '${track.totalAttendances}',
                          AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: AppColors.error)),
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 11,
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

  Color get statusColor {
    switch (raffle.status) {
      case RaffleStatus.active:
        return AppColors.success;
      case RaffleStatus.closed:
        return AppColors.warning;
      case RaffleStatus.drawn:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raffle.prize,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            raffle.status.displayName,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${raffle.totalParticipants}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (raffle.winner != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              raffle.winner!.name,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
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
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
