import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/raffle_info_model.dart';
import 'countdown_timer_widget.dart';

class RaffleInfoCard extends StatelessWidget {
  final RaffleInfoModel raffle;
  final bool showCountdown;
  final VoidCallback? onCountdownExpired;

  const RaffleInfoCard({
    super.key,
    required this.raffle,
    this.showCountdown = true,
    this.onCountdownExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  raffle.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _StatusBadge(status: raffle.status),
            ],
          ),

          // Description
          if (raffle.description != null &&
              raffle.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              raffle.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],

          const SizedBox(height: 16),

          // Prize section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.primary,
                    size: 24,
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
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        raffle.prize,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info row: participants and domain
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.people_outline,
                  label: 'Participantes',
                  value: raffle.participantCount.toString(),
                ),
              ),
              if (raffle.allowedDomain != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.domain,
                    label: 'Domínio',
                    value: '@${raffle.allowedDomain}',
                  ),
                ),
              ],
            ],
          ),

          // Countdown
          if (showCountdown && raffle.isActive) ...[
            const SizedBox(height: 16),
            if (raffle.hasNotStarted && raffle.startsAt != null)
              CountdownTimerWidget(
                targetTime: raffle.startsAt!,
                mode: CountdownMode.opensIn,
                onExpired: onCountdownExpired,
              )
            else if (!raffle.isExpired && raffle.endsAt != null)
              CountdownTimerWidget(
                targetTime: raffle.endsAt!,
                mode: CountdownMode.closesIn,
                onExpired: onCountdownExpired,
              ),
          ],

          // Event raffle notice
          if (raffle.isEventRaffle && !raffle.allowLinkRegistration) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Participantes selecionados automaticamente com base na presença.',
                      style: TextStyle(
                        color: AppColors.info.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // PIN requirement notice
          if (raffle.requireConfirmation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pin_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Será necessário criar um código de 5 dígitos para confirmar presença caso seja sorteado.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.statusActive;
      case 'CLOSED':
        return AppColors.statusClosed;
      case 'DRAWN':
        return AppColors.statusDrawn;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Ativo';
      case 'CLOSED':
        return 'Fechado';
      case 'DRAWN':
        return 'Sorteado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withOpacity(0.3),
        ),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
