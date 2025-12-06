import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/raffle_info_model.dart';
import '../../data/models/participant_model.dart';
import '../../data/services/registration_service.dart';

// State classes
class RegistrationState {
  final RaffleInfoModel? raffleInfo;
  final bool isLoading;
  final bool isRegistering;
  final bool isSuccess;
  final String? error;
  final ParticipantModel? registeredParticipant;

  const RegistrationState({
    this.raffleInfo,
    this.isLoading = false,
    this.isRegistering = false,
    this.isSuccess = false,
    this.error,
    this.registeredParticipant,
  });

  RegistrationState copyWith({
    RaffleInfoModel? raffleInfo,
    bool? isLoading,
    bool? isRegistering,
    bool? isSuccess,
    String? error,
    ParticipantModel? registeredParticipant,
  }) {
    return RegistrationState(
      raffleInfo: raffleInfo ?? this.raffleInfo,
      isLoading: isLoading ?? this.isLoading,
      isRegistering: isRegistering ?? this.isRegistering,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      registeredParticipant:
          registeredParticipant ?? this.registeredParticipant,
    );
  }
}

class ConfirmationState {
  final bool isLoading;
  final bool isConfirming;
  final bool isSuccess;
  final String? error;

  const ConfirmationState({
    this.isLoading = false,
    this.isConfirming = false,
    this.isSuccess = false,
    this.error,
  });

  ConfirmationState copyWith({
    bool? isLoading,
    bool? isConfirming,
    bool? isSuccess,
    String? error,
  }) {
    return ConfirmationState(
      isLoading: isLoading ?? this.isLoading,
      isConfirming: isConfirming ?? this.isConfirming,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

// Registration notifier
class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final RegistrationService _service;
  final String raffleId;

  RegistrationNotifier(this._service, this.raffleId)
      : super(const RegistrationState(isLoading: true)) {
    loadRaffleInfo();
  }

  Future<void> loadRaffleInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final raffleInfo = await _service.getRaffleInfo(raffleId);
      state = state.copyWith(
        raffleInfo: raffleInfo,
        isLoading: false,
      );
    } on NotFoundException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } on ServerException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar informações: $e',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    String? pin,
  }) async {
    state = state.copyWith(isRegistering: true, error: null);
    try {
      final participant = await _service.registerParticipant(
        raffleId: raffleId,
        name: name,
        email: email,
        pin: pin,
      );
      state = state.copyWith(
        isRegistering: false,
        isSuccess: true,
        registeredParticipant: participant,
      );
    } on ValidationException catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: e.message,
      );
    } on ConflictException catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: e.message,
      );
    } on ServerException catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: e.message,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: 'Erro ao registrar: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const RegistrationState(isLoading: true);
    loadRaffleInfo();
  }
}

// Confirmation notifier
class ConfirmationNotifier extends StateNotifier<ConfirmationState> {
  final RegistrationService _service;
  final String raffleId;

  ConfirmationNotifier(this._service, this.raffleId)
      : super(const ConfirmationState());

  Future<void> confirmPresence(String pin) async {
    state = state.copyWith(isConfirming: true, error: null);
    try {
      await _service.confirmPresence(
        raffleId: raffleId,
        pin: pin,
      );
      state = state.copyWith(
        isConfirming: false,
        isSuccess: true,
      );
    } on ValidationException catch (e) {
      state = state.copyWith(
        isConfirming: false,
        error: e.message,
      );
    } on NotFoundException catch (e) {
      state = state.copyWith(
        isConfirming: false,
        error: e.message,
      );
    } on ServerException catch (e) {
      state = state.copyWith(
        isConfirming: false,
        error: e.message,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        isConfirming: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isConfirming: false,
        error: 'Erro ao confirmar: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider family for registration by raffle ID
final registrationProvider = StateNotifierProvider.family<RegistrationNotifier,
    RegistrationState, String>(
  (ref, raffleId) {
    final service = ref.watch(registrationServiceProvider);
    return RegistrationNotifier(service, raffleId);
  },
);

// Provider family for confirmation by raffle ID
final confirmationProvider = StateNotifierProvider.family<ConfirmationNotifier,
    ConfirmationState, String>(
  (ref, raffleId) {
    final service = ref.watch(registrationServiceProvider);
    return ConfirmationNotifier(service, raffleId);
  },
);
