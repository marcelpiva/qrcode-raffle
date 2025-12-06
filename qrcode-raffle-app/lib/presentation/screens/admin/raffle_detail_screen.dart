import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/models/participant_model.dart';
import '../../providers/raffle_provider.dart';
import '../../providers/draw_provider.dart';
import '../../widgets/raffle_status_badge.dart';
import '../../widgets/countdown_timer_widget.dart';
import '../shared/confirmation_screen.dart';

class RaffleDetailScreen extends ConsumerStatefulWidget {
  final String raffleId;

  // NAVA SUMMIT Colors
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color primaryPink = Color(0xFFDB2777);
  static const Color darkBg = Color(0xFF09090B);
  static const Color cardBg = Color(0xFF18181B);
  static const Color cardBorder = Color(0xFF27272A);
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color errorRed = Color(0xFFEF4444);

  const RaffleDetailScreen({
    super.key,
    required this.raffleId,
  });

  @override
  ConsumerState<RaffleDetailScreen> createState() => _RaffleDetailScreenState();
}

class _RaffleDetailScreenState extends ConsumerState<RaffleDetailScreen> {
  bool _showAllParticipants = false;
  String _searchQuery = '';
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh();
      }
    });
  }

  String get _registrationUrl {
    final baseUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
    return '$baseUrl/register/${widget.raffleId}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(raffleDetailProvider(widget.raffleId));

    ref.listen<RaffleDetailState>(
      raffleDetailProvider(widget.raffleId),
      (previous, next) {
        if (next.actionError != null && next.actionError != previous?.actionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.actionError!),
              backgroundColor: RaffleDetailScreen.errorRed,
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: RaffleDetailScreen.darkBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, state),
                SliverToBoxAdapter(
                  child: _buildContent(context, state),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: state.raffle != null
          ? _buildFAB(context, ref, state)
          : null,
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A0A2E),
                RaffleDetailScreen.darkBg,
                Color(0xFF0A0A0A),
              ],
            ),
          ),
        ),
        Positioned(
          right: -100,
          top: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  RaffleDetailScreen.primaryPurple.withOpacity(0.3),
                  RaffleDetailScreen.primaryPurple.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 200,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  RaffleDetailScreen.primaryPink.withOpacity(0.2),
                  RaffleDetailScreen.primaryPink.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, RaffleDetailState state) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        if (state.raffle != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareRaffle(context),
              tooltip: 'Compartilhar',
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RaffleDetailScreen.primaryPurple.withOpacity(0.8),
                RaffleDetailScreen.primaryPink.withOpacity(0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    state.raffle?.name ?? 'Detalhes do Sorteio',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (state.raffle != null)
                    Row(
                      children: [
                        RaffleStatusBadge(status: state.raffle!.status),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${state.raffle!.totalParticipants}',
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
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RaffleDetailState state) {
    if (state.isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(RaffleDetailScreen.primaryPurple),
          ),
        ),
      );
    }

    if (state.error != null) {
      return _buildError(context, state.error!);
    }

    if (state.raffle == null) {
      return _buildNotFound(context);
    }

    final raffle = state.raffle!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      color: RaffleDetailScreen.primaryPurple,
      backgroundColor: RaffleDetailScreen.cardBg,
      onRefresh: () =>
          ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Card or No QR Code Card
            if (!raffle.isEventRaffle && !raffle.isTalkRaffle || raffle.allowLinkRegistration) ...[
              _buildQRCodeCard(context, raffle).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
            ] else ...[
              _buildNoQRCodeCard(context, raffle).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
            ],

            // Prize Card
            _buildPrizeCard(raffle)
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Winner Card (if drawn)
            if (raffle.isDrawn && raffle.winner != null) ...[
              _buildWinnerCard(raffle)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 300.ms),
              const SizedBox(height: 16),
            ],

            // Countdown Card (if scheduled)
            if (raffle.hasSchedule && !raffle.isDrawn) ...[
              _buildCountdownCard(raffle)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 300.ms),
              const SizedBox(height: 16),
            ],

            // Info Card
            _buildInfoCard(context, raffle, dateFormat)
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Event/Talk Badge
            if (raffle.isEventRaffle || raffle.isTalkRaffle) ...[
              _buildEventBadge(raffle)
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 300.ms),
              const SizedBox(height: 16),
            ],

            // Settings toggles
            if (raffle.isEventRaffle || raffle.hasSchedule) ...[
              _buildSettingsCard(raffle, state)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: 16),
            ],

            // Participants Section
            _buildParticipantsSection(context, state)
                .animate()
                .fadeIn(delay: 350.ms, duration: 300.ms),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard(BuildContext context, dynamic raffle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Column(
            children: [
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: RaffleDetailScreen.primaryPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _registrationUrl,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF9333EA),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF9333EA),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Escaneie para participar',
                style: TextStyle(
                  color: RaffleDetailScreen.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              // Copy URL Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [RaffleDetailScreen.primaryPurple, RaffleDetailScreen.primaryPink],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _copyUrl(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.copy, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Copiar link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoQRCodeCard(BuildContext context, dynamic raffle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: RaffleDetailScreen.infoBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.link_off_rounded,
                  size: 48,
                  color: RaffleDetailScreen.infoBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Inscricao via QR Code desabilitada',
                style: TextStyle(
                  color: RaffleDetailScreen.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                raffle.isEventRaffle
                    ? 'Apenas participantes com presenca no evento podem participar.'
                    : 'Apenas participantes com presenca na palestra podem participar.',
                style: TextStyle(
                  color: RaffleDetailScreen.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeCard(dynamic raffle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RaffleDetailScreen.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events_rounded, color: RaffleDetailScreen.warningOrange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premio',
                      style: TextStyle(
                        color: RaffleDetailScreen.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      raffle.prize,
                      style: const TextStyle(
                        color: RaffleDetailScreen.textPrimary,
                        fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, dynamic raffle, DateFormat dateFormat) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                Icons.calendar_today_rounded,
                'Criado em',
                dateFormat.format(raffle.createdAt),
                RaffleDetailScreen.textSecondary,
              ),
              if (raffle.description != null && raffle.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.description_rounded,
                  'Descricao',
                  raffle.description!,
                  RaffleDetailScreen.infoBlue,
                ),
              ],
              if (raffle.allowedDomain != null) ...[
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.email_rounded,
                  'Dominio permitido',
                  '@${raffle.allowedDomain}',
                  RaffleDetailScreen.primaryPink,
                ),
              ],
              if (raffle.requireConfirmation) ...[
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.lock_rounded,
                  'Confirmacao',
                  'Requer PIN de ${raffle.confirmationTimeoutMinutes ?? 5}min',
                  RaffleDetailScreen.warningOrange,
                ),
              ],
              if (raffle.hasSchedule) ...[
                if (raffle.startsAt != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.schedule_rounded,
                    'Abre em',
                    dateFormat.format(raffle.startsAt!),
                    RaffleDetailScreen.infoBlue,
                  ),
                ],
                if (raffle.endsAt != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.timer_off_rounded,
                    'Fecha em',
                    dateFormat.format(raffle.endsAt!),
                    RaffleDetailScreen.warningOrange,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: RaffleDetailScreen.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: RaffleDetailScreen.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerCard(dynamic raffle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RaffleDetailScreen.successGreen.withOpacity(0.2),
                RaffleDetailScreen.successGreen.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.successGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      RaffleDetailScreen.successGreen,
                      RaffleDetailScreen.successGreen.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: RaffleDetailScreen.successGreen.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [RaffleDetailScreen.successGreen, Color(0xFF4ADE80)],
                ).createShader(bounds),
                child: const Text(
                  'GANHADOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                raffle.winner!.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: RaffleDetailScreen.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                raffle.winner!.email,
                style: const TextStyle(
                  color: RaffleDetailScreen.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (raffle.closedAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: RaffleDetailScreen.cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sorteado em ${DateFormat('dd/MM/yyyy HH:mm').format(raffle.closedAt!.toLocal())}',
                    style: const TextStyle(
                      color: RaffleDetailScreen.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownCard(dynamic raffle) {
    final CountdownMode mode;
    final DateTime targetTime;

    if (raffle.hasNotStarted && raffle.startsAt != null) {
      mode = CountdownMode.opensIn;
      targetTime = raffle.startsAt!;
    } else if (raffle.endsAt != null && !raffle.isExpired) {
      mode = CountdownMode.closesIn;
      targetTime = raffle.endsAt!;
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: CountdownTimerWidget(
            targetTime: targetTime,
            mode: mode,
            onExpired: () {
              ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventBadge(dynamic raffle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      RaffleDetailScreen.primaryPurple.withOpacity(0.2),
                      RaffleDetailScreen.primaryPink.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  raffle.isEventRaffle ? Icons.event_rounded : Icons.mic_rounded,
                  color: RaffleDetailScreen.primaryPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raffle.isEventRaffle ? 'Sorteio de Evento' : 'Sorteio de Palestra',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: RaffleDetailScreen.textPrimary,
                      ),
                    ),
                    if (raffle.minDurationMinutes != null || raffle.minTalksCount != null)
                      Text(
                        _getEligibilityText(raffle),
                        style: const TextStyle(
                          color: RaffleDetailScreen.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEligibilityText(dynamic raffle) {
    final parts = <String>[];
    if (raffle.minDurationMinutes != null) {
      parts.add('Min. ${raffle.minDurationMinutes} min');
    }
    if (raffle.minTalksCount != null) {
      parts.add('Min. ${raffle.minTalksCount} palestras');
    }
    return parts.join(' • ');
  }

  Widget _buildSettingsCard(dynamic raffle, RaffleDetailState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RaffleDetailScreen.textTertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_rounded, color: RaffleDetailScreen.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Configuracoes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: RaffleDetailScreen.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Allow link registration toggle (for event raffles)
              if (raffle.isEventRaffle) ...[
                _buildToggleRow(
                  icon: raffle.allowLinkRegistration ? Icons.link_rounded : Icons.link_off_rounded,
                  title: 'Permitir inscricoes por link',
                  subtitle: raffle.allowLinkRegistration
                      ? 'Participantes podem se inscrever via QR code'
                      : 'Apenas participantes do evento podem participar',
                  value: raffle.allowLinkRegistration,
                  color: raffle.allowLinkRegistration ? RaffleDetailScreen.successGreen : RaffleDetailScreen.textTertiary,
                  onChanged: state.isActionLoading
                      ? null
                      : (value) {
                          ref
                              .read(raffleDetailProvider(widget.raffleId).notifier)
                              .toggleLinkRegistration(value);
                        },
                ),
                if (raffle.hasSchedule) ...[
                  const SizedBox(height: 16),
                  Container(height: 1, color: RaffleDetailScreen.cardBorder),
                  const SizedBox(height: 16),
                ],
              ],
              // Auto-draw toggle (for scheduled raffles)
              if (raffle.hasSchedule && raffle.endsAt != null)
                _buildToggleRow(
                  icon: raffle.autoDrawOnEnd ? Icons.casino_rounded : Icons.casino_outlined,
                  title: 'Sortear automaticamente',
                  subtitle: raffle.autoDrawOnEnd
                      ? 'O sorteio sera realizado quando o prazo acabar'
                      : 'Voce precisara iniciar o sorteio manualmente',
                  value: raffle.autoDrawOnEnd,
                  color: raffle.autoDrawOnEnd ? RaffleDetailScreen.primaryPurple : RaffleDetailScreen.textTertiary,
                  onChanged: state.isActionLoading
                      ? null
                      : (value) {
                          ref
                              .read(raffleDetailProvider(widget.raffleId).notifier)
                              .toggleAutoDrawOnEnd(value);
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: RaffleDetailScreen.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: RaffleDetailScreen.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: RaffleDetailScreen.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(BuildContext context, RaffleDetailState state) {
    final participants = state.participants;
    final filteredParticipants = _searchQuery.isEmpty
        ? participants
        : participants.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.email.toLowerCase().contains(query);
          }).toList();

    final displayedParticipants = _showAllParticipants
        ? filteredParticipants
        : filteredParticipants.take(5).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: RaffleDetailScreen.cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RaffleDetailScreen.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RaffleDetailScreen.primaryPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_rounded, color: RaffleDetailScreen.primaryPurple, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Participantes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: RaffleDetailScreen.textPrimary,
                          ),
                        ),
                        Text(
                          '${participants.length} inscrito${participants.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: RaffleDetailScreen.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (participants.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: RaffleDetailScreen.cardBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _exportParticipants(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.download, size: 16, color: RaffleDetailScreen.textSecondary),
                                SizedBox(width: 6),
                                Text(
                                  'Exportar',
                                  style: TextStyle(
                                    color: RaffleDetailScreen.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Search bar (if more than 5 participants)
              if (participants.length > 5) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: RaffleDetailScreen.darkBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: RaffleDetailScreen.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar participante...',
                      hintStyle: const TextStyle(color: RaffleDetailScreen.textTertiary, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: RaffleDetailScreen.textTertiary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Participants list
              if (participants.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 40,
                          color: RaffleDetailScreen.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nenhum participante ainda',
                          style: TextStyle(
                            color: RaffleDetailScreen.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredParticipants.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Nenhum resultado para "$_searchQuery"',
                      style: const TextStyle(
                        color: RaffleDetailScreen.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else ...[
                ...displayedParticipants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;
                  final isWinner = state.raffle?.winner?.id == participant.id;
                  return _ParticipantTile(
                    participant: participant,
                    isWinner: isWinner,
                    index: index,
                  );
                }),

                // Show more/less button
                if (filteredParticipants.length > 5) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showAllParticipants = !_showAllParticipants),
                      icon: Icon(
                        _showAllParticipants ? Icons.expand_less : Icons.expand_more,
                        color: RaffleDetailScreen.primaryPurple,
                      ),
                      label: Text(
                        _showAllParticipants
                            ? 'Mostrar menos'
                            : 'Ver todos (${filteredParticipants.length})',
                        style: const TextStyle(
                          color: RaffleDetailScreen.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: RaffleDetailScreen.cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: RaffleDetailScreen.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sorteio nao encontrado',
              style: TextStyle(
                color: RaffleDetailScreen.textPrimary,
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
                foregroundColor: RaffleDetailScreen.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: RaffleDetailScreen.errorRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: RaffleDetailScreen.errorRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                error,
                style: const TextStyle(
                  color: RaffleDetailScreen.textPrimary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [RaffleDetailScreen.primaryPurple, RaffleDetailScreen.primaryPink],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(raffleDetailProvider(widget.raffleId).notifier).loadRaffle(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, WidgetRef ref, RaffleDetailState state) {
    final raffle = state.raffle!;

    if (state.isActionLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: RaffleDetailScreen.cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: RaffleDetailScreen.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: RaffleDetailScreen.textSecondary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Processando...',
              style: TextStyle(color: RaffleDetailScreen.textSecondary),
            ),
          ],
        ),
      );
    }

    // Active raffle - can close registrations
    if (raffle.isActive) {
      return _buildGradientFAB(
        onPressed: () => _showCloseDialog(context, ref),
        icon: Icons.lock_rounded,
        label: 'Fechar Inscricoes',
        colors: [RaffleDetailScreen.warningOrange, const Color(0xFFEA580C)],
      );
    }

    // Closed raffle with winner (inconsistent state) - show reopen option
    if (raffle.isClosed && raffle.winner != null) {
      return _buildGradientFAB(
        onPressed: () => _showReopenDialog(context, ref),
        icon: Icons.refresh_rounded,
        label: 'Resortear',
        colors: [RaffleDetailScreen.primaryPurple, RaffleDetailScreen.primaryPink],
      );
    }

    // Closed raffle (no winner) - can draw or reopen registrations
    if (raffle.isClosed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reopen registrations button (secondary)
          Container(
            decoration: BoxDecoration(
              color: RaffleDetailScreen.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: RaffleDetailScreen.infoBlue.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed: () => _showReopenRegistrationsDialog(context, ref),
              icon: const Icon(Icons.lock_open_rounded),
              color: RaffleDetailScreen.infoBlue,
              tooltip: 'Reabrir inscricoes',
            ),
          ),
          const SizedBox(height: 12),
          // Draw button (primary)
          _buildGradientFAB(
            onPressed: raffle.totalParticipants > 0
                ? () {
                    ref.invalidate(drawProvider(widget.raffleId));
                    context.push('/admin/raffles/${widget.raffleId}/draw');
                  }
                : null,
            icon: Icons.casino_rounded,
            label: 'Sortear',
            colors: raffle.totalParticipants > 0
                ? [RaffleDetailScreen.primaryPurple, RaffleDetailScreen.primaryPink]
                : [RaffleDetailScreen.cardBg, RaffleDetailScreen.cardBg],
            disabled: raffle.totalParticipants == 0,
          ),
        ],
      );
    }

    // Drawn raffle - show reopen option
    if (raffle.isDrawn) {
      return _buildGradientFAB(
        onPressed: () => _showReopenDialog(context, ref),
        icon: Icons.refresh_rounded,
        label: 'Reabrir Sorteio',
        colors: [RaffleDetailScreen.primaryPurple, RaffleDetailScreen.primaryPink],
      );
    }

    return null;
  }

  Widget _buildGradientFAB({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required List<Color> colors,
    bool disabled = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(28),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: colors.first.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: disabled ? RaffleDetailScreen.textTertiary : Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: disabled ? RaffleDetailScreen.textTertiary : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCloseDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Fechar Inscricoes?',
      message: 'Ao fechar as inscricoes, novos participantes nao poderao se inscrever.',
      subtitle: 'Voce podera reabrir as inscricoes depois, se necessario.',
      confirmText: 'Fechar Inscricoes',
      cancelText: 'Cancelar',
      type: ConfirmationType.close,
    );

    if (confirmed) {
      ref.read(raffleDetailProvider(widget.raffleId).notifier).closeRegistrations();
    }
  }

  Future<void> _showReopenDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Reabrir Sorteio?',
      message: 'Ao reabrir o sorteio, o ganhador atual sera removido e voce podera sortear novamente.',
      subtitle: 'As inscricoes permanecerao fechadas.',
      confirmText: 'Reabrir Sorteio',
      cancelText: 'Cancelar',
      type: ConfirmationType.warning,
    );

    if (confirmed) {
      ref.read(raffleDetailProvider(widget.raffleId).notifier).reopenRaffle();
    }
  }

  Future<void> _showReopenRegistrationsDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Reabrir Inscricoes?',
      message: 'Ao reabrir as inscricoes, novos participantes poderao se inscrever no sorteio novamente.',
      confirmText: 'Reabrir Inscricoes',
      cancelText: 'Cancelar',
      type: ConfirmationType.info,
    );

    if (confirmed) {
      ref.read(raffleDetailProvider(widget.raffleId).notifier).reopenRegistrations();
    }
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _registrationUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copiado!'),
        backgroundColor: RaffleDetailScreen.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareRaffle(BuildContext context) {
    final state = ref.read(raffleDetailProvider(widget.raffleId));
    final raffle = state.raffle;
    if (raffle == null) return;

    Share.share(
      'Participe do sorteio "${raffle.name}"!\n'
      'Premio: ${raffle.prize}\n\n'
      'Acesse: $_registrationUrl',
      subject: 'Sorteio: ${raffle.name}',
    );
  }

  void _exportParticipants(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exportacao sera implementada em breve'),
        backgroundColor: RaffleDetailScreen.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final bool isWinner;
  final int index;

  const _ParticipantTile({
    required this.participant,
    required this.isWinner,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');

    final avatarColors = [
      RaffleDetailScreen.primaryPurple,
      RaffleDetailScreen.primaryPink,
      RaffleDetailScreen.infoBlue,
      RaffleDetailScreen.successGreen,
      RaffleDetailScreen.warningOrange,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? RaffleDetailScreen.successGreen.withOpacity(0.1)
            : RaffleDetailScreen.darkBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner
              ? RaffleDetailScreen.successGreen.withOpacity(0.3)
              : RaffleDetailScreen.cardBorder.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isWinner
                ? const LinearGradient(
                    colors: [RaffleDetailScreen.successGreen, Color(0xFF4ADE80)],
                  )
                : LinearGradient(
                    colors: [
                      avatarColors[index % avatarColors.length],
                      avatarColors[index % avatarColors.length].withOpacity(0.7),
                    ],
                  ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: isWinner
                ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20)
                : Text(
                    participant.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                participant.name,
                style: TextStyle(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                  color: isWinner ? RaffleDetailScreen.successGreen : RaffleDetailScreen.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWinner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [RaffleDetailScreen.successGreen, Color(0xFF4ADE80)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ganhador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          participant.email,
          style: const TextStyle(
            color: RaffleDetailScreen.textSecondary,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          dateFormat.format(participant.createdAt),
          style: const TextStyle(
            color: RaffleDetailScreen.textTertiary,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
