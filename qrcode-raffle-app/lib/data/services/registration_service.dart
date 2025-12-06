import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/raffle_info_model.dart';
import '../models/participant_model.dart';

final registrationServiceProvider = Provider<RegistrationService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RegistrationService(dioClient);
});

class RegistrationService {
  final DioClient _dioClient;

  RegistrationService(this._dioClient);

  /// Get raffle info for registration page
  Future<RaffleInfoModel> getRaffleInfo(String raffleId) async {
    final response = await _dioClient.get(
      ApiEndpoints.registerParticipant(raffleId),
    );
    return RaffleInfoModel.fromJson(response.data);
  }

  /// Register a participant in a raffle
  Future<ParticipantModel> registerParticipant({
    required String raffleId,
    required String name,
    required String email,
    String? pin,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.registerParticipant(raffleId),
      data: RegisterParticipantRequest(
        name: name,
        email: email,
        pin: pin,
      ).toJson(),
    );
    return ParticipantModel.fromJson(response.data);
  }

  /// Confirm winner presence with PIN
  Future<bool> confirmPresence({
    required String raffleId,
    required String pin,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.raffleConfirmPin(raffleId),
      data: ConfirmPresenceRequest(pin: pin).toJson(),
    );
    return response.statusCode == 200;
  }
}
