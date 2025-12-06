import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/raffle_model.dart';
import '../../data/models/participant_model.dart';
import '../../data/services/raffle_service.dart';
import '../../domain/entities/raffle.dart';

// ============================================================================
// Raffle List State & Provider
// ============================================================================

class RaffleListState {
  final List<Raffle> raffles;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final RaffleStatusFilter filter;

  const RaffleListState({
    this.raffles = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.filter = RaffleStatusFilter.all,
  });

  RaffleListState copyWith({
    List<Raffle>? raffles,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    RaffleStatusFilter? filter,
  }) {
    return RaffleListState(
      raffles: raffles ?? this.raffles,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  List<Raffle> get filteredRaffles {
    switch (filter) {
      case RaffleStatusFilter.all:
        return raffles;
      case RaffleStatusFilter.active:
        return raffles.where((r) => r.isActive).toList();
      case RaffleStatusFilter.closed:
        return raffles.where((r) => r.isClosed).toList();
      case RaffleStatusFilter.drawn:
        return raffles.where((r) => r.isDrawn).toList();
    }
  }
}

enum RaffleStatusFilter { all, active, closed, drawn }

class RaffleListNotifier extends StateNotifier<RaffleListState> {
  final RaffleService _service;

  RaffleListNotifier(this._service) : super(const RaffleListState(isLoading: true)) {
    loadRaffles();
  }

  Future<void> loadRaffles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final models = await _service.getRaffles();
      final raffles = models.map((m) => m.toEntity()).toList();
      // Sort by createdAt descending
      raffles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        raffles: raffles,
        isLoading: false,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar sorteios: $e');
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final models = await _service.getRaffles();
      final raffles = models.map((m) => m.toEntity()).toList();
      raffles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        raffles: raffles,
        isRefreshing: false,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isRefreshing: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isRefreshing: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: 'Erro ao atualizar: $e');
    }
  }

  void setFilter(RaffleStatusFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> deleteRaffle(String id) async {
    try {
      await _service.deleteRaffle(id);
      state = state.copyWith(
        raffles: state.raffles.where((r) => r.id != id).toList(),
      );
    } on ServerException catch (e) {
      state = state.copyWith(error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao deletar: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final raffleListProvider =
    StateNotifierProvider<RaffleListNotifier, RaffleListState>((ref) {
  final service = ref.watch(raffleServiceProvider);
  return RaffleListNotifier(service);
});

// ============================================================================
// Raffle Detail State & Provider
// ============================================================================

class RaffleDetailState {
  final Raffle? raffle;
  final List<ParticipantModel> participants;
  final bool isLoading;
  final bool isActionLoading;
  final String? error;
  final String? actionError;
  final DrawResultModel? lastDrawResult;

  const RaffleDetailState({
    this.raffle,
    this.participants = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.actionError,
    this.lastDrawResult,
  });

  RaffleDetailState copyWith({
    Raffle? raffle,
    List<ParticipantModel>? participants,
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    String? actionError,
    DrawResultModel? lastDrawResult,
  }) {
    return RaffleDetailState(
      raffle: raffle ?? this.raffle,
      participants: participants ?? this.participants,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error,
      actionError: actionError,
      lastDrawResult: lastDrawResult ?? this.lastDrawResult,
    );
  }
}

class RaffleDetailNotifier extends StateNotifier<RaffleDetailState> {
  final RaffleService _service;
  final String raffleId;

  RaffleDetailNotifier(this._service, this.raffleId)
      : super(const RaffleDetailState(isLoading: true)) {
    loadRaffle();
  }

  Future<void> loadRaffle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final model = await _service.getRaffle(raffleId);
      final participants = await _service.getParticipants(raffleId);
      state = state.copyWith(
        raffle: model.toEntity(),
        participants: participants,
        isLoading: false,
      );
    } on NotFoundException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar: $e');
    }
  }

  Future<void> refresh() async {
    await loadRaffle();
  }

  Future<void> closeRegistrations() async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.closeRegistrations(raffleId);
      state = state.copyWith(
        raffle: model.toEntity(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao fechar inscrições: $e',
      );
    }
  }

  Future<void> reopenRegistrations() async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.reopenRegistrations(raffleId);
      state = state.copyWith(
        raffle: model.toEntity(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao reabrir inscrições: $e',
      );
    }
  }

  Future<DrawResultModel?> drawWinner() async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final result = await _service.drawWinner(raffleId);
      state = state.copyWith(
        raffle: result.raffle.toEntity(),
        isActionLoading: false,
        lastDrawResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao sortear: $e',
      );
      return null;
    }
  }

  Future<void> confirmWinner() async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.confirmWinner(raffleId);
      state = state.copyWith(
        raffle: model.toEntity(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao confirmar ganhador: $e',
      );
    }
  }

  Future<void> reopenRaffle() async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.reopenRaffle(raffleId);
      state = state.copyWith(
        raffle: model.toEntity(),
        isActionLoading: false,
        lastDrawResult: null,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao reabrir sorteio: $e',
      );
    }
  }

  Future<void> updateRaffle(UpdateRaffleRequest request) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.updateRaffle(raffleId, request);
      state = state.copyWith(
        raffle: model.toEntity(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao atualizar sorteio: $e',
      );
    }
  }

  Future<void> toggleLinkRegistration(bool enabled) async {
    await updateRaffle(UpdateRaffleRequest(allowLinkRegistration: enabled));
  }

  Future<void> toggleAutoDrawOnEnd(bool enabled) async {
    await updateRaffle(UpdateRaffleRequest(autoDrawOnEnd: enabled));
  }

  void clearActionError() {
    state = state.copyWith(actionError: null);
  }
}

final raffleDetailProvider = StateNotifierProvider.family<RaffleDetailNotifier,
    RaffleDetailState, String>(
  (ref, raffleId) {
    final service = ref.watch(raffleServiceProvider);
    return RaffleDetailNotifier(service, raffleId);
  },
);

// ============================================================================
// Create Raffle State & Provider
// ============================================================================

class CreateRaffleState {
  final bool isCreating;
  final String? error;
  final Raffle? createdRaffle;

  const CreateRaffleState({
    this.isCreating = false,
    this.error,
    this.createdRaffle,
  });

  CreateRaffleState copyWith({
    bool? isCreating,
    String? error,
    Raffle? createdRaffle,
  }) {
    return CreateRaffleState(
      isCreating: isCreating ?? this.isCreating,
      error: error,
      createdRaffle: createdRaffle ?? this.createdRaffle,
    );
  }
}

class CreateRaffleNotifier extends StateNotifier<CreateRaffleState> {
  final RaffleService _service;

  CreateRaffleNotifier(this._service) : super(const CreateRaffleState());

  Future<Raffle?> createRaffle(CreateRaffleRequest request) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final model = await _service.createRaffle(request);
      final raffle = model.toEntity();
      state = state.copyWith(
        isCreating: false,
        createdRaffle: raffle,
      );
      return raffle;
    } on ValidationException catch (e) {
      state = state.copyWith(isCreating: false, error: e.message);
      return null;
    } on ServerException catch (e) {
      state = state.copyWith(isCreating: false, error: e.message);
      return null;
    } on NetworkException catch (e) {
      state = state.copyWith(isCreating: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: 'Erro ao criar: $e');
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const CreateRaffleState();
  }
}

final createRaffleProvider =
    StateNotifierProvider<CreateRaffleNotifier, CreateRaffleState>((ref) {
  final service = ref.watch(raffleServiceProvider);
  return CreateRaffleNotifier(service);
});
