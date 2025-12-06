import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/raffle.dart';
import 'raffle_status_badge.dart';

class RaffleCardWidget extends StatelessWidget {
  final Raffle raffle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const RaffleCardWidget({
    super.key,
    required this.raffle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      raffle.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RaffleStatusBadge(status: raffle.status, compact: true),
                ],
              ),

              const SizedBox(height: 12),

              // Prize row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prêmio',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          raffle.prize,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Info row
              Row(
                children: [
                  // Participants
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: '${raffle.totalParticipants}',
                    tooltip: 'Participantes',
                  ),
                  const SizedBox(width: 12),
                  // Created date
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: dateFormat.format(raffle.createdAt),
                    tooltip: 'Criado em',
                  ),
                  const Spacer(),
                  // Delete button
                  if (onDelete != null && raffle.isActive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: Colors.grey[600],
                      onPressed: onDelete,
                      tooltip: 'Excluir',
                    ),
                ],
              ),

              // Winner info (if drawn)
              if (raffle.isDrawn && raffle.winner != null) ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ganhador',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              raffle.winner!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Schedule info
              if (raffle.hasSchedule) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: AppColors.info,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getScheduleText(),
                        style: const TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Event raffle badge
              if (raffle.isEventRaffle || raffle.isTalkRaffle) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        raffle.isEventRaffle ? Icons.event : Icons.mic,
                        color: AppColors.secondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        raffle.isEventRaffle ? 'Sorteio de Evento' : 'Sorteio de Palestra',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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

  String _getScheduleText() {
    final dateFormat = DateFormat('dd/MM HH:mm');
    if (raffle.hasNotStarted && raffle.startsAt != null) {
      return 'Abre em ${dateFormat.format(raffle.startsAt!)}';
    } else if (raffle.endsAt != null && !raffle.isExpired) {
      return 'Fecha em ${dateFormat.format(raffle.endsAt!)}';
    } else if (raffle.isExpired && raffle.endsAt != null) {
      return 'Encerrado em ${dateFormat.format(raffle.endsAt!)}';
    }
    return '';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
