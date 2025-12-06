import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/entities/talk.dart';
import '../../providers/events_provider.dart';
import '../shared/confirmation_screen.dart';

class TrackDetailScreen extends ConsumerWidget {
  final String trackId;

  const TrackDetailScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackDetailProvider(trackId));

    ref.listen<TrackDetailState>(
      trackDetailProvider(trackId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(trackDetailProvider(trackId).notifier).clearActionError();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(state.track?.name ?? 'Trilha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(trackDetailProvider(trackId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildContent(context, ref, state),
      floatingActionButton: state.track != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/tracks/$trackId/talks/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nova Palestra'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TrackDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return _buildError(context, ref, state.error!);
    }

    if (state.track == null) {
      return const Center(
        child: Text('Trilha não encontrada'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(trackDetailProvider(trackId).notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrackHeader(context, state.track!),
            _buildStatsSection(context, state.track!),
            _buildTalksSection(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackHeader(BuildContext context, Track track) {
    final trackColor = _getTrackColor(track.color);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trackColor,
            trackColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.layers,
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
                  track.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (track.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    track.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStatsSection(BuildContext context, Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use Row for wide screens, Column for narrow
          if (constraints.maxWidth > 300) {
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.mic,
                    value: '${track.totalTalks}',
                    label: 'Palestras',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    value: '${track.totalAttendances}',
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
                  icon: Icons.mic,
                  value: '${track.totalTalks}',
                  label: 'Palestras',
                  color: AppColors.info,
                  horizontal: true,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.people,
                  value: '${track.totalAttendances}',
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

  Widget _buildTalksSection(BuildContext context, WidgetRef ref, TrackDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Palestras',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (state.talks.isEmpty)
          _buildEmptyTalks(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.talks.length,
            itemBuilder: (context, index) {
              final talk = state.talks[index];
              return _TalkCard(
                talk: talk,
                onTap: () => context.push('/admin/talks/${talk.id}'),
                onDelete: () => _showDeleteTalkDialog(context, ref, talk),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * index + 200),
                    duration: const Duration(milliseconds: 300),
                  );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTalks(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mic_off_outlined,
            size: 48,
            color: AppColors.textTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma palestra criada',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione palestras para esta trilha',
            style: TextStyle(
              color: AppColors.textTertiary(context),
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
              onPressed: () => ref.read(trackDetailProvider(trackId).notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrackColor(String? color) {
    if (color == null) return AppColors.primary;
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _showDeleteTalkDialog(BuildContext context, WidgetRef ref, Talk talk) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Excluir palestra?',
      message: 'Tem certeza que deseja excluir "${talk.title}"?',
      subtitle: 'Todas as presenças desta palestra serão excluídas. Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed) {
      ref.read(trackDetailProvider(trackId).notifier).deleteTalk(talk.id);
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

class _TalkCard extends StatelessWidget {
  final Talk talk;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TalkCard({
    required this.talk,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          talk.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (talk.speaker != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  talk.speaker!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
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
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (talk.startTime != null)
                    _buildChip(
                      Icons.schedule,
                      DateFormat('HH:mm').format(talk.startTime!.toLocal()),
                      AppColors.warning,
                    ),
                  if (talk.durationMinutes != null)
                    _buildChip(
                      Icons.timer_outlined,
                      talk.formattedDuration,
                      AppColors.secondary,
                    ),
                  if (talk.room != null)
                    _buildChip(
                      Icons.meeting_room_outlined,
                      talk.room!,
                      AppColors.info,
                    ),
                  _buildChip(
                    Icons.people_outline,
                    '${talk.totalAttendances}',
                    AppColors.success,
                  ),
                ],
              ),
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
