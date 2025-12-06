import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/event.dart';
import '../../providers/events_provider.dart';
import '../shared/confirmation_screen.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventsListProvider);

    ref.listen<EventsListState>(
      eventsListProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventsListProvider.notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildContent(context, ref, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/events/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, EventsListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.events.isEmpty) {
      return _buildError(context, ref, state.error!);
    }

    if (state.events.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(eventsListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: state.events.length,
        itemBuilder: (context, index) {
          final event = state.events[index];
          return _EventCard(
            event: event,
            onTap: () => context.push('/admin/events/${event.id}'),
            onDelete: () => _showDeleteDialog(context, ref, event.id, event.name),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * index),
                duration: const Duration(milliseconds: 300),
              );
        },
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
              onPressed: () => ref.read(eventsListProvider.notifier).loadEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum evento encontrado.\nCrie seu primeiro evento!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Excluir evento?',
      message: 'Tem certeza que deseja excluir "$name"?',
      subtitle: 'Todas as trilhas e palestras serão excluídas. Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed) {
      ref.read(eventsListProvider.notifier).deleteEvent(id);
    }
  }

}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (event.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
              if (event.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  event.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.layers_outlined,
                    label: '${event.totalTracks} trilhas',
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.mic_outlined,
                    label: '${event.totalTalks} palestras',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.people_outline,
                    label: '${event.totalAttendances}',
                    color: AppColors.success,
                  ),
                ],
              ),
              if (event.startDate != null || event.endDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 16,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDateRangeText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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

  Color _getStatusColor() {
    if (event.hasEnded) return AppColors.statusClosed;
    if (event.isOngoing) return AppColors.statusActive;
    return AppColors.info;
  }

  IconData _getStatusIcon() {
    if (event.hasEnded) return Icons.check_circle_outline;
    if (event.isOngoing) return Icons.play_circle_outline;
    return Icons.schedule;
  }

  String _getDateRangeText() {
    final dateFormat = DateFormat('dd/MM');
    if (event.startDate != null && event.endDate != null) {
      return '${dateFormat.format(event.startDate!)} - ${dateFormat.format(event.endDate!)}';
    } else if (event.startDate != null) {
      return 'Início: ${dateFormat.format(event.startDate!)}';
    } else if (event.endDate != null) {
      return 'Término: ${dateFormat.format(event.endDate!)}';
    }
    return '';
  }
}
