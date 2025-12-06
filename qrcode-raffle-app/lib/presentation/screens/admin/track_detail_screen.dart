import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/entities/talk.dart';
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

class TrackDetailScreen extends ConsumerStatefulWidget {
  final String trackId;

  const TrackDetailScreen({super.key, required this.trackId});

  @override
  ConsumerState<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends ConsumerState<TrackDetailScreen>
    with WidgetsBindingObserver {
  String get trackId => widget.trackId;

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
      ref.read(trackDetailProvider(trackId).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackDetailProvider(trackId));

    ref.listen<TrackDetailState>(
      trackDetailProvider(trackId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: _errorRed,
            ),
          );
          ref.read(trackDetailProvider(trackId).notifier).clearActionError();
        }
      },
    );

    return Scaffold(
      backgroundColor: _darkBg,
      body: _buildContent(context, ref, state),
      floatingActionButton: state.track != null ? _buildGradientFAB(context) : null,
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
          final result = await context.push('/admin/tracks/$trackId/talks/new');
          // Force refresh after creating a talk
          if (result == true) {
            await ref.read(trackDetailProvider(trackId).notifier).refresh();
          }
        },
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nova Palestra',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TrackDetailState state) {
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

    if (state.track == null) {
      return _buildNotFound(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(trackDetailProvider(trackId).notifier).refresh(),
      color: _primaryPurple,
      backgroundColor: _cardBg,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, ref, state.track!),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(context, state.track!),
                _buildTalksSection(context, ref, state),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, WidgetRef ref, Track track) {
    final trackColor = _getTrackColor(track.color);

    return SliverAppBar(
      expandedHeight: 200,
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
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(trackDetailProvider(trackId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [trackColor, trackColor.withOpacity(0.7)],
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.layers_rounded,
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
                                  'TRILHA',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  track.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
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
                      if (track.description != null) ...[
                        const SizedBox(height: 12),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Track track) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _GlassStatCard(
              icon: Icons.mic_rounded,
              value: '${track.totalTalks}',
              label: 'Palestras',
              color: _infoBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GlassStatCard(
              icon: Icons.people_rounded,
              value: '${track.totalAttendances}',
              label: 'Presenças',
              color: _successGreen,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildTalksSection(BuildContext context, WidgetRef ref, TrackDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryPurple.withOpacity(0.2), _primaryPink.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_primaryPurple, _primaryPink],
                  ).createShader(bounds),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Palestras',
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
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBorder),
                ),
                child: Text(
                  '${state.talks.length}',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.talks.isEmpty)
          _buildEmptyTalks(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                Icons.mic_off_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhuma palestra criada',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione palestras para esta trilha\nusando o botão abaixo',
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
            'Trilha não encontrada',
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
                onPressed: () => ref.read(trackDetailProvider(trackId).notifier).refresh(),
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

  Color _getTrackColor(String? color) {
    if (color == null) return _primaryPurple;
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (_) {
      return _primaryPurple;
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
      // Get the track to find the eventId before deleting
      final trackState = ref.read(trackDetailProvider(trackId));
      final eventId = trackState.track?.eventId;

      await ref.read(trackDetailProvider(trackId).notifier).deleteTalk(talk.id);

      // Invalidate eventDetailProvider so timeline in EventsCarouselScreen updates
      if (eventId != null) {
        ref.invalidate(eventDetailProvider(eventId));
      }

      // Invalidate events list to force full reload
      ref.invalidate(eventsListProvider);
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ).createShader(bounds),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryPurple.withOpacity(0.2),
                            _primaryPink.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_primaryPurple, _primaryPink],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            talk.title,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (talk.speaker != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    talk.speaker!,
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
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
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: _textTertiary,
                      ),
                      color: _cardBg,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: _errorRed),
                              const SizedBox(width: 8),
                              const Text(
                                'Excluir',
                                style: TextStyle(color: _errorRed),
                              ),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (talk.startTime != null)
                      _buildChip(
                        Icons.schedule_rounded,
                        DateFormat('HH:mm').format(talk.startTime!.toLocal()),
                        _warningOrange,
                      ),
                    if (talk.durationMinutes != null)
                      _buildChip(
                        Icons.timer_outlined,
                        talk.formattedDuration,
                        _infoBlue,
                      ),
                    if (talk.room != null)
                      _buildChip(
                        Icons.meeting_room_outlined,
                        talk.room!,
                        _primaryPurple,
                      ),
                    _buildChip(
                      Icons.people_outline_rounded,
                      '${talk.totalAttendances}',
                      _successGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
