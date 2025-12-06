import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/talk.dart';
import '../../../domain/entities/attendance.dart';
import '../../providers/events_provider.dart';
import '../shared/confirmation_screen.dart';

class TalkDetailScreen extends ConsumerWidget {
  final String talkId;

  const TalkDetailScreen({super.key, required this.talkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(talkDetailProvider(talkId));

    ref.listen<TalkDetailState>(
      talkDetailProvider(talkId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(talkDetailProvider(talkId).notifier).clearActionError();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Palestra'),
        actions: [
          if (state.talk != null)
            IconButton(
              icon: const Icon(Icons.casino_outlined),
              onPressed: () => context.push('/admin/raffles/create?talkId=$talkId'),
              tooltip: 'Criar Sorteio',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(talkDetailProvider(talkId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
          if (state.talk != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Editar palestra'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  // TODO: Navigate to edit talk screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edição em breve!')),
                  );
                }
              },
            ),
        ],
      ),
      body: _buildContent(context, ref, state),
      floatingActionButton: state.talk != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/talks/$talkId/attendances/new'),
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar Presença'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TalkDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return _buildError(context, ref, state.error!);
    }

    if (state.talk == null) {
      return const Center(
        child: Text('Palestra não encontrada'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(talkDetailProvider(talkId).notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTalkHeader(context, state.talk!),
            _buildDetailsSection(context, state.talk!),
            _buildAttendancesSection(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTalkHeader(BuildContext context, Talk talk) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info,
            AppColors.info.withOpacity(0.8),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mic,
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
                      talk.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (talk.speaker != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              talk.speaker!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
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
          if (talk.description != null) ...[
            const SizedBox(height: 16),
            Text(
              talk.description!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildDetailsSection(BuildContext context, Talk talk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth <= 300;

              final scheduleCard = talk.startTime != null
                  ? _DetailCard(
                      icon: Icons.schedule,
                      label: 'Horário',
                      value: DateFormat('HH:mm').format(talk.startTime!.toLocal()),
                      color: AppColors.warning,
                      horizontal: isNarrow,
                    )
                  : null;

              final durationCard = talk.durationMinutes != null
                  ? _DetailCard(
                      icon: Icons.timer,
                      label: 'Duração',
                      value: talk.formattedDuration,
                      color: AppColors.secondary,
                      horizontal: isNarrow,
                    )
                  : null;

              final attendanceCard = _DetailCard(
                icon: Icons.people,
                label: 'Presenças',
                value: '${talk.totalAttendances}',
                color: AppColors.success,
                horizontal: isNarrow,
              );

              // Use Row for wide screens, Column for narrow
              if (!isNarrow) {
                return Row(
                  children: [
                    if (scheduleCard != null) ...[
                      Expanded(child: scheduleCard),
                      const SizedBox(width: 12),
                    ],
                    if (durationCard != null) ...[
                      Expanded(child: durationCard),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: attendanceCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    if (scheduleCard != null) ...[
                      scheduleCard,
                      const SizedBox(height: 8),
                    ],
                    if (durationCard != null) ...[
                      durationCard,
                      const SizedBox(height: 8),
                    ],
                    attendanceCard,
                  ],
                );
              }
            },
          ),
          if (talk.room != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, color: AppColors.info),
                  const SizedBox(width: 12),
                  Text(
                    'Sala: ${talk.room}',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (talk.speakerEmail != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      talk.speakerEmail!,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildAttendancesSection(BuildContext context, WidgetRef ref, TalkDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lista de Presenças',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${state.attendances.length} participantes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (state.attendances.isEmpty)
          _buildEmptyAttendances(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.attendances.length,
            itemBuilder: (context, index) {
              final attendance = state.attendances[index];
              return _AttendanceCard(
                attendance: attendance,
                onDelete: () => _showDeleteAttendanceDialog(context, ref, attendance),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 30 * index + 200),
                    duration: const Duration(milliseconds: 200),
                  );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyAttendances(BuildContext context) {
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
            Icons.people_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma presença registrada',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione presenças manualmente ou importe via CSV',
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
              onPressed: () => ref.read(talkDetailProvider(talkId).notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAttendanceDialog(BuildContext context, WidgetRef ref, Attendance attendance) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Remover presença?',
      message: 'Tem certeza que deseja remover a presença de "${attendance.displayName}"?',
      subtitle: 'Esta ação não pode ser desfeita.',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed) {
      ref.read(talkDetailProvider(talkId).notifier).deleteAttendance(attendance.id);
    }
  }

  Future<void> _showCreateRaffleDialog(BuildContext context, Talk talk) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Criar sorteio',
      message: 'Criar um sorteio para os participantes da palestra "${talk.title}"?',
      subtitle: '${talk.totalAttendances} participantes elegíveis.',
      confirmText: 'Criar Sorteio',
      cancelText: 'Cancelar',
      type: ConfirmationType.info,
    );

    if (confirmed && context.mounted) {
      context.push('/admin/raffles/new?talkId=$talkId');
    }
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool horizontal;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
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
            Icon(icon, color: color, size: 20),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback onDelete;

  const _AttendanceCard({
    required this.attendance,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            attendance.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          attendance.name ?? attendance.email.split('@').first,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attendance.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (attendance.durationMinutes != null)
              Text(
                'Duração: ${attendance.formattedDuration}',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
