import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../data/services/raffle_service.dart';
import '../../domain/entities/raffle.dart';
import '../../domain/entities/participant.dart';

// ============================================================================
// Draw State
// ============================================================================

enum DrawPhase {
  loading,      // Loading raffle data
  ready,        // Ready to draw
  spinning,     // Animation playing
  winner,       // Winner revealed
  confirming,   // Waiting for winner confirmation (if requireConfirmation)
  confirmed,    // Winner confirmed
  timeout,      // Confirmation timeout
  error,        // Error state
}

class DrawState {
  final Raffle? raffle;
  final List<Participant> participants;
  final DrawPhase phase;
  final Participant? winner;
  final int drawNumber;
  final String? error;
  final DateTime? drawnAt;

  const DrawState({
    this.raffle,
    this.participants = const [],
    this.phase = DrawPhase.loading,
    this.winner,
    this.drawNumber = 0,
    this.error,
    this.drawnAt,
  });

  DrawState copyWith({
    Raffle? raffle,
    List<Participant>? participants,
    DrawPhase? phase,
    Participant? winner,
    int? drawNumber,
    String? error,
    DateTime? drawnAt,
  }) {
    return DrawState(
      raffle: raffle ?? this.raffle,
      participants: participants ?? this.participants,
      phase: phase ?? this.phase,
      winner: winner ?? this.winner,
      drawNumber: drawNumber ?? this.drawNumber,
      error: error,
      drawnAt: drawnAt ?? this.drawnAt,
    );
  }

  bool get isLoading => phase == DrawPhase.loading;
  bool get isReady => phase == DrawPhase.ready;
  bool get isSpinning => phase == DrawPhase.spinning;
  bool get hasWinner => phase == DrawPhase.winner || phase == DrawPhase.confirming || phase == DrawPhase.confirmed;
  bool get isConfirming => phase == DrawPhase.confirming;
  bool get isConfirmed => phase == DrawPhase.confirmed;
  bool get isTimeout => phase == DrawPhase.timeout;
  bool get hasError => phase == DrawPhase.error;

  List<String> get participantNames => participants.map((p) => p.name).toList();
}

// ============================================================================
// Draw Notifier
// ============================================================================

class DrawNotifier extends StateNotifier<DrawState> {
  final RaffleService _service;
  final String raffleId;

  DrawNotifier(this._service, this.raffleId) : super(const DrawState()) {
    loadRaffle();
  }

  Future<void> loadRaffle() async {
    state = state.copyWith(phase: DrawPhase.loading, error: null);
    try {
      final model = await _service.getRaffle(raffleId);
      final participantModels = await _service.getParticipants(raffleId);

      final raffle = model.toEntity();
      final participants = participantModels.map((p) => p.toEntity()).toList();

      // Check if already drawn
      if (raffle.isDrawn && raffle.winner != null) {
        state = state.copyWith(
          raffle: raffle,
          participants: participants,
          phase: DrawPhase.confirmed,
          winner: raffle.winner,
        );
      } else {
        state = state.copyWith(
          raffle: raffle,
          participants: participants,
          phase: DrawPhase.ready,
        );
      }
    } on NotFoundException catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: e.message);
    } on ServerException catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: e.message);
    } catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: 'Erro ao carregar: $e');
    }
  }

  void startSpinning() {
    if (state.phase != DrawPhase.ready) return;
    state = state.copyWith(phase: DrawPhase.spinning);
  }

  Future<void> performDraw() async {
    try {
      final result = await _service.drawWinner(raffleId);

      final winner = result.winner.toEntity();
      final raffle = result.raffle.toEntity();

      // Determine next phase based on confirmation requirement
      final nextPhase = raffle.requireConfirmation
          ? DrawPhase.confirming
          : DrawPhase.winner;

      state = state.copyWith(
        raffle: raffle,
        winner: winner,
        drawNumber: result.drawNumber,
        phase: nextPhase,
        drawnAt: DateTime.now(),
      );
    } on ServerException catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: e.message);
    } catch (e) {
      state = state.copyWith(phase: DrawPhase.error, error: 'Erro ao sortear: $e');
    }
  }

  Future<void> confirmWinner() async {
    try {
      final model = await _service.confirmWinner(raffleId);
      state = state.copyWith(
        raffle: model.toEntity(),
        phase: DrawPhase.confirmed,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DrawPhase.error,
        error: 'Erro ao confirmar: $e',
      );
    }
  }

  void onConfirmationTimeout() {
    state = state.copyWith(phase: DrawPhase.timeout);
  }

  Future<void> redraw() async {
    try {
      // Reopen raffle to allow redraw
      await _service.reopenRaffle(raffleId);
      state = state.copyWith(
        phase: DrawPhase.ready,
        winner: null,
        drawNumber: 0,
        drawnAt: null,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DrawPhase.error,
        error: 'Erro ao reabrir: $e',
      );
    }
  }

  void setPhase(DrawPhase phase) {
    state = state.copyWith(phase: phase);
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(phase: DrawPhase.ready, error: null);
    }
  }
}

// ============================================================================
// Provider
// ============================================================================

final drawProvider = StateNotifierProvider.family<DrawNotifier, DrawState, String>(
  (ref, raffleId) {
    final service = ref.watch(raffleServiceProvider);
    return DrawNotifier(service, raffleId);
  },
);

// ============================================================================
// Display Provider (for projection mode)
// ============================================================================

class DisplayState {
  final Raffle? raffle;
  final int participantCount;
  final bool isLoading;
  final String? error;
  final Duration? pollInterval;

  const DisplayState({
    this.raffle,
    this.participantCount = 0,
    this.isLoading = false,
    this.error,
    this.pollInterval = const Duration(seconds: 5),
  });

  DisplayState copyWith({
    Raffle? raffle,
    int? participantCount,
    bool? isLoading,
    String? error,
    Duration? pollInterval,
  }) {
    return DisplayState(
      raffle: raffle ?? this.raffle,
      participantCount: participantCount ?? this.participantCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pollInterval: pollInterval ?? this.pollInterval,
    );
  }
}

class DisplayNotifier extends StateNotifier<DisplayState> {
  final RaffleService _service;
  final String raffleId;

  DisplayNotifier(this._service, this.raffleId) : super(const DisplayState(isLoading: true)) {
    loadRaffle();
  }

  Future<void> loadRaffle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final model = await _service.getRaffle(raffleId);
      final participants = await _service.getParticipants(raffleId);

      state = state.copyWith(
        raffle: model.toEntity(),
        participantCount: participants.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadRaffle();
  }
}

final displayProvider = StateNotifierProvider.family<DisplayNotifier, DisplayState, String>(
  (ref, raffleId) {
    final service = ref.watch(raffleServiceProvider);
    return DisplayNotifier(service, raffleId);
  },
);
