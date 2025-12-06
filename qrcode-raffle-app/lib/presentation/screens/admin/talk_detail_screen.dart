import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/talk.dart';
import '../../../domain/entities/attendance.dart';
import '../../providers/events_provider.dart';
import '../shared/confirmation_screen.dart';

// NAVA SUMMIT Colors (top-level for access by helper widgets)
const Color _primaryPurple = Color(0xFF9333EA);
const Color _primaryPink = Color(0xFFDB2777);
const Color _darkBg = Color(0xFF09090B);
const Color _cardBg = Color(0xFF18181B);
const Color _cardBorder = Color(0xFF27272A);
const Color _textPrimary = Color(0xFFFAFAFA);
const Color _textSecondary = Color(0xFFA1A1AA);
const Color _textTertiary = Color(0xFF71717A);
const Color _successGreen = Color(0xFF22C55E);
const Color _warningOrange = Color(0xFFF97316);
const Color _infoBlue = Color(0xFF3B82F6);
const Color _errorRed = Color(0xFFEF4444);

class TalkDetailScreen extends ConsumerStatefulWidget {
  final String talkId;

  const TalkDetailScreen({super.key, required this.talkId});

  @override
  ConsumerState<TalkDetailScreen> createState() => _TalkDetailScreenState();
}

class _TalkDetailScreenState extends ConsumerState<TalkDetailScreen>
    with WidgetsBindingObserver {
  String get talkId => widget.talkId;

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
      ref.read(talkDetailProvider(talkId).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(talkDetailProvider(talkId));

    ref.listen<TalkDetailState>(
      talkDetailProvider(talkId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: _errorRed,
            ),
          );
          ref.read(talkDetailProvider(talkId).notifier).clearActionError();
        }
      },
    );

    return Scaffold(
      backgroundColor: _darkBg,
      body: _buildContent(context, ref, state),
      floatingActionButton: state.talk != null ? _buildGradientFAB(context) : null,
    );
  }

  Widget _buildGradientFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryPurple, _primaryPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
          await context.push('/admin/talks/$talkId/attendances/new');
          // Refresh when returning from create screen
          ref.read(talkDetailProvider(talkId).notifier).refresh();
        },
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add Presenca',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TalkDetailState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryPurple),
        ),
      );
    }

    if (state.error != null) {
      return _buildError(context, ref, state.error!);
    }

    if (state.talk == null) {
      return _buildNotFound(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(talkDetailProvider(talkId).notifier).refresh(),
      color: _primaryPurple,
      backgroundColor: _cardBg,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, ref, state.talk!),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(context, state.talk!),
                _buildDetailsSection(context, state.talk!),
                _buildAttendancesSection(context, ref, state),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, WidgetRef ref, Talk talk) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _darkBg,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.casino_rounded, color: Colors.white),
            onPressed: () => context.push('/admin/raffles/create?talkId=$talkId'),
            tooltip: 'Criar Sorteio',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(talkDetailProvider(talkId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryPurple, _primaryPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PALESTRA',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  talk.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (talk.speaker != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                talk.speaker!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Talk talk) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (talk.startTime != null)
            Expanded(
              child: _GlassStatCard(
                icon: Icons.schedule_rounded,
                value: DateFormat('HH:mm').format(talk.startTime!.toLocal()),
                label: 'Horario',
                color: _warningOrange,
              ),
            ),
          if (talk.startTime != null && talk.durationMinutes != null)
            const SizedBox(width: 12),
          if (talk.durationMinutes != null)
            Expanded(
              child: _GlassStatCard(
                icon: Icons.timer_rounded,
                value: talk.formattedDuration,
                label: 'Duracao',
                color: _infoBlue,
              ),
            ),
          if (talk.durationMinutes != null || talk.startTime != null)
            const SizedBox(width: 12),
          Expanded(
            child: _GlassStatCard(
              icon: Icons.people_rounded,
              value: '${talk.totalAttendances}',
              label: 'Presencas',
              color: _successGreen,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildDetailsSection(BuildContext context, Talk talk) {
    if (talk.room == null && talk.speakerEmail == null && talk.description == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (talk.description != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryPurple.withOpacity(0.2), _primaryPink.withOpacity(0.2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_primaryPurple, _primaryPink],
                          ).createShader(bounds),
                          child: const Icon(Icons.description_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Descricao',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    talk.description!,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (talk.room != null)
                Expanded(
                  child: _InfoCard(
                    icon: Icons.meeting_room_rounded,
                    label: 'Sala',
                    value: talk.room!,
                    color: _primaryPurple,
                  ),
                ),
              if (talk.room != null && talk.speakerEmail != null)
                const SizedBox(width: 12),
              if (talk.speakerEmail != null)
                Expanded(
                  child: _InfoCard(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: talk.speakerEmail!,
                    color: _infoBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }

  Widget _buildAttendancesSection(BuildContext context, WidgetRef ref, TalkDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_successGreen.withOpacity(0.2), _successGreen.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_rounded, color: _successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lista de Presencas',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _successGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.attendances.length}',
                  style: TextStyle(
                    color: _successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.attendances.length,
            itemBuilder: (context, index) {
              final attendance = state.attendances[index];
              return _AttendanceCard(
                attendance: attendance,
                index: index,
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
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryPurple.withOpacity(0.1), _primaryPink.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_primaryPurple, _primaryPink],
              ).createShader(bounds),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhuma presenca registrada',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione presencas manualmente\nou importe via CSV',
            style: TextStyle(
              color: _textTertiary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: _textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Palestra nao encontrada',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
            style: TextButton.styleFrom(
              foregroundColor: _primaryPurple,
            ),
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
                color: _errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: _errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              error,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPurple, _primaryPink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () => ref.read(talkDetailProvider(talkId).notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAttendanceDialog(BuildContext context, WidgetRef ref, Attendance attendance) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Remover presenca?',
      message: 'Tem certeza que deseja remover a presenca de "${attendance.displayName}"?',
      subtitle: 'Esta acao nao pode ser desfeita.',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed) {
      ref.read(talkDetailProvider(talkId).notifier).deleteAttendance(attendance.id);
    }
  }
}

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _GlassStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ).createShader(bounds),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Attendance attendance;
  final int index;
  final VoidCallback onDelete;

  const _AttendanceCard({
    required this.attendance,
    required this.index,
    required this.onDelete,
  });

  Color get _avatarColor {
    final colors = [
      _primaryPurple,
      _primaryPink,
      _infoBlue,
      _successGreen,
      _warningOrange,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_avatarColor, _avatarColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  attendance.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendance.name ?? attendance.email.split('@').first,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attendance.email,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attendance.durationMinutes != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: _successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendance.formattedDuration,
                          style: TextStyle(
                            color: _successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: _errorRed,
                size: 20,
              ),
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: _errorRed.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
