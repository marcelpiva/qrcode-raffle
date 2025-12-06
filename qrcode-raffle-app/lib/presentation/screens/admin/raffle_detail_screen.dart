import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/models/participant_model.dart';
import '../../providers/raffle_provider.dart';
import '../../providers/draw_provider.dart';
import '../../widgets/raffle_status_badge.dart';
import '../../widgets/countdown_timer_widget.dart';
import '../shared/confirmation_screen.dart';

class RaffleDetailScreen extends ConsumerStatefulWidget {
  final String raffleId;

  const RaffleDetailScreen({
    super.key,
    required this.raffleId,
  });

  @override
  ConsumerState<RaffleDetailScreen> createState() => _RaffleDetailScreenState();
}

class _RaffleDetailScreenState extends ConsumerState<RaffleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(state.raffle?.name ?? 'Detalhes do Sorteio'),
        actions: [
          if (state.raffle != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareRaffle(context),
              tooltip: 'Compartilhar',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.info_outline),
              text: 'Detalhes',
            ),
            Tab(
              icon: const Icon(Icons.people_outline),
              text: 'Participantes (${state.participants.length})',
            ),
          ],
        ),
      ),
      body: _buildBody(context, state),
      floatingActionButton: state.raffle != null
          ? _buildFAB(context, ref, state)
          : null,
    );
  }

  Widget _buildBody(BuildContext context, RaffleDetailState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildError(context, state.error!);
    }

    if (state.raffle == null) {
      return const Center(child: Text('Sorteio não encontrado'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDetailsTab(context, state),
        _buildParticipantsTab(context, state),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context, RaffleDetailState state) {
    final raffle = state.raffle!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(raffleDetailProvider(widget.raffleId).notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and QR Code Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RaffleStatusBadge(status: raffle.status),
                        if (raffle.hasSchedule)
                          _buildScheduleInfo(raffle, dateFormat),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: _registrationUrl,
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Escaneie para participar',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Copy URL Button
                    OutlinedButton.icon(
                      onPressed: () => _copyUrl(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar link'),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.emoji_events,
                      'Prêmio',
                      raffle.prize,
                      AppColors.primary,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.people,
                      'Participantes',
                      '${raffle.totalParticipants}',
                      AppColors.info,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Criado em',
                      dateFormat.format(raffle.createdAt),
                      AppColors.textSecondary(context),
                    ),
                    if (raffle.description != null &&
                        raffle.description!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.description,
                        'Descrição',
                        raffle.description!,
                        AppColors.textSecondary(context),
                      ),
                    ],
                    if (raffle.allowedDomain != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.email,
                        'Domínio permitido',
                        '@${raffle.allowedDomain}',
                        AppColors.secondary,
                      ),
                    ],
                    if (raffle.requireConfirmation) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.lock,
                        'Confirmação',
                        'Requer PIN de ${raffle.confirmationTimeoutMinutes ?? 5}min',
                        AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Winner Card (if drawn)
            if (raffle.isDrawn && raffle.winner != null)
              _buildWinnerCard(raffle)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms),

            // Countdown Card (if scheduled)
            if (raffle.hasSchedule && !raffle.isDrawn)
              _buildCountdownCard(raffle)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms),

            // Event/Talk Badge
            if (raffle.isEventRaffle || raffle.isTalkRaffle)
              _buildEventBadge(raffle)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms),

            // Settings toggles (for event raffles or scheduled raffles)
            if (raffle.isEventRaffle || raffle.hasSchedule)
              _buildSettingsCard(raffle, state)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleInfo(dynamic raffle, DateFormat dateFormat) {
    if (raffle.hasNotStarted && raffle.startsAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, color: AppColors.info, size: 14),
            const SizedBox(width: 4),
            Text(
              'Abre: ${dateFormat.format(raffle.startsAt!)}',
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (raffle.endsAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, color: AppColors.warning, size: 14),
            const SizedBox(width: 4),
            Text(
              'Fecha: ${dateFormat.format(raffle.endsAt!)}',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerCard(dynamic raffle) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: AppColors.success.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ganhador',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raffle.winner!.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raffle.winner!.email,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
            if (raffle.closedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Sorteado em ${DateFormat('dd/MM/yyyy HH:mm').format(raffle.closedAt!.toLocal())}',
                style: TextStyle(
                  color: AppColors.textTertiary(context),
                  fontSize: 12,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CountdownTimerWidget(
          targetTime: targetTime,
          mode: mode,
          onExpired: () {
            ref
                .read(raffleDetailProvider(widget.raffleId).notifier)
                .refresh();
          },
        ),
      ),
    );
  }

  Widget _buildEventBadge(dynamic raffle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                raffle.isEventRaffle ? Icons.event : Icons.mic,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffle.isEventRaffle ? 'Sorteio de Evento' : 'Sorteio de Palestra',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (raffle.minDurationMinutes != null ||
                      raffle.minTalksCount != null)
                    Text(
                      _getEligibilityText(raffle),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEligibilityText(dynamic raffle) {
    final parts = <String>[];
    if (raffle.minDurationMinutes != null) {
      parts.add('Mín. ${raffle.minDurationMinutes} min');
    }
    if (raffle.minTalksCount != null) {
      parts.add('Mín. ${raffle.minTalksCount} palestras');
    }
    return parts.join(' • ');
  }

  Widget _buildSettingsCard(dynamic raffle, RaffleDetailState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings, color: AppColors.textSecondary(context), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Allow link registration toggle (for event raffles)
            if (raffle.isEventRaffle) ...[
              SwitchListTile(
                value: raffle.allowLinkRegistration,
                onChanged: state.isActionLoading
                    ? null
                    : (value) {
                        ref
                            .read(raffleDetailProvider(widget.raffleId).notifier)
                            .toggleLinkRegistration(value);
                      },
                title: const Text('Permitir inscrições por link'),
                subtitle: Text(
                  raffle.allowLinkRegistration
                      ? 'Participantes podem se inscrever via QR code'
                      : 'Apenas participantes do evento podem participar',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: raffle.allowLinkRegistration
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    raffle.allowLinkRegistration ? Icons.link : Icons.link_off,
                    color: raffle.allowLinkRegistration
                        ? AppColors.success
                        : AppColors.textTertiary(context),
                    size: 20,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              if (raffle.hasSchedule) const Divider(height: 24),
            ],
            // Auto-draw toggle (for scheduled raffles)
            if (raffle.hasSchedule && raffle.endsAt != null)
              SwitchListTile(
                value: raffle.autoDrawOnEnd,
                onChanged: state.isActionLoading
                    ? null
                    : (value) {
                        ref
                            .read(raffleDetailProvider(widget.raffleId).notifier)
                            .toggleAutoDrawOnEnd(value);
                      },
                title: const Text('Sortear automaticamente'),
                subtitle: Text(
                  raffle.autoDrawOnEnd
                      ? 'O sorteio será realizado quando o prazo acabar'
                      : 'Você precisará iniciar o sorteio manualmente',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: raffle.autoDrawOnEnd
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    raffle.autoDrawOnEnd ? Icons.casino : Icons.casino_outlined,
                    color: raffle.autoDrawOnEnd
                        ? AppColors.primary
                        : AppColors.textTertiary(context),
                    size: 20,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsTab(BuildContext context, RaffleDetailState state) {
    final filteredParticipants = state.participants.where((p) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.email.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar participante...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        // Participants count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredParticipants.length} participante${filteredParticipants.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () => _exportParticipants(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar'),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: filteredParticipants.isEmpty
              ? _buildEmptyParticipants()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: filteredParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = filteredParticipants[index];
                    final isWinner = state.raffle?.winner?.id == participant.id;
                    return _ParticipantTile(
                      participant: participant,
                      isWinner: isWinner,
                      index: index,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyParticipants() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textTertiary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhum participante ainda'
                : 'Nenhum resultado encontrado',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
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
              onPressed: () =>
                  ref.read(raffleDetailProvider(widget.raffleId).notifier).loadRaffle(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, WidgetRef ref, RaffleDetailState state) {
    final raffle = state.raffle!;

    if (state.isActionLoading) {
      return FloatingActionButton.extended(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        label: const Text('Processando...'),
        backgroundColor: Colors.grey,
      );
    }

    // Active raffle - can close registrations
    if (raffle.isActive) {
      return FloatingActionButton.extended(
        onPressed: () => _showCloseDialog(context, ref),
        icon: const Icon(Icons.lock),
        label: const Text('Fechar Inscrições'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      );
    }

    // Closed raffle with winner (inconsistent state) - show reopen option
    if (raffle.isClosed && raffle.winner != null) {
      return FloatingActionButton.extended(
        heroTag: 'reopen_with_winner',
        onPressed: () => _showReopenDialog(context, ref),
        icon: const Icon(Icons.refresh),
        label: const Text('Resortear'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      );
    }

    // Closed raffle (no winner) - can draw or reopen registrations
    if (raffle.isClosed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reopen registrations button (secondary)
          FloatingActionButton.small(
            heroTag: 'reopen_registrations',
            onPressed: () => _showReopenRegistrationsDialog(context, ref),
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            child: const Icon(Icons.lock_open),
          ),
          const SizedBox(height: 12),
          // Draw button (primary)
          FloatingActionButton.extended(
            heroTag: 'draw',
            onPressed: raffle.totalParticipants > 0
                ? () {
                    // Invalidate draw provider to force fresh data load
                    ref.invalidate(drawProvider(widget.raffleId));
                    context.push('/admin/raffles/${widget.raffleId}/draw');
                  }
                : null,
            icon: const Icon(Icons.casino),
            label: const Text('Sortear'),
            backgroundColor:
                raffle.totalParticipants > 0 ? AppColors.primary : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ],
      );
    }

    // Drawn raffle - show reopen option
    if (raffle.isDrawn) {
      return FloatingActionButton.extended(
        onPressed: () => _showReopenDialog(context, ref),
        icon: const Icon(Icons.refresh),
        label: const Text('Reabrir Sorteio'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      );
    }

    return null;
  }

  Future<void> _showCloseDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Fechar Inscrições?',
      message: 'Ao fechar as inscrições, novos participantes não poderão se inscrever.',
      subtitle: 'Você poderá reabrir as inscrições depois, se necessário.',
      confirmText: 'Fechar Inscrições',
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
      message: 'Ao reabrir o sorteio, o ganhador atual será removido e você poderá sortear novamente.',
      subtitle: 'As inscrições permanecerão fechadas.',
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
      title: 'Reabrir Inscrições?',
      message: 'Ao reabrir as inscrições, novos participantes poderão se inscrever no sorteio novamente.',
      confirmText: 'Reabrir Inscrições',
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
      const SnackBar(
        content: Text('Link copiado!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareRaffle(BuildContext context) {
    final state = ref.read(raffleDetailProvider(widget.raffleId));
    final raffle = state.raffle;
    if (raffle == null) return;

    Share.share(
      'Participe do sorteio "${raffle.name}"!\n'
      'Prêmio: ${raffle.prize}\n\n'
      'Acesse: $_registrationUrl',
      subject: 'Sorteio: ${raffle.name}',
    );
  }

  void _exportParticipants(BuildContext context) {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação será implementada em breve'),
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isWinner
            ? AppColors.success.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        child: isWinner
            ? const Icon(Icons.emoji_events, color: AppColors.success)
            : Text(
                participant.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
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
                color: isWinner ? AppColors.success : AppColors.textPrimary(context),
              ),
            ),
          ),
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ganhador',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        participant.email,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateFormat.format(participant.createdAt),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 11,
            ),
          ),
          if (participant.hasPin == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.textTertiary(context),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 30 * index),
          duration: const Duration(milliseconds: 200),
        );
  }
}
