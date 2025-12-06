import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/raffle_model.dart';
import '../models/participant_model.dart';

final raffleServiceProvider = Provider<RaffleService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RaffleService(dioClient);
});

class RaffleService {
  final DioClient _dioClient;

  RaffleService(this._dioClient);

  /// Get all raffles
  Future<List<RaffleModel>> getRaffles() async {
    final response = await _dioClient.get(ApiEndpoints.raffles);
    final List<dynamic> data = response.data;
    return data.map((json) => RaffleModel.fromJson(json)).toList();
  }

  /// Get a single raffle by ID
  Future<RaffleModel> getRaffle(String id) async {
    final response = await _dioClient.get(ApiEndpoints.raffleById(id));
    return RaffleModel.fromJson(response.data);
  }

  /// Create a new raffle
  Future<RaffleModel> createRaffle(CreateRaffleRequest request) async {
    final response = await _dioClient.post(
      ApiEndpoints.raffles,
      data: request.toJson(),
    );
    return RaffleModel.fromJson(response.data);
  }

  /// Update an existing raffle
  Future<RaffleModel> updateRaffle(String id, UpdateRaffleRequest request) async {
    final response = await _dioClient.patch(
      ApiEndpoints.raffleById(id),
      data: request.toJson(),
    );
    return RaffleModel.fromJson(response.data);
  }

  /// Delete a raffle
  Future<void> deleteRaffle(String id) async {
    await _dioClient.delete(ApiEndpoints.raffleById(id));
  }

  /// Get participants of a raffle
  Future<List<ParticipantModel>> getParticipants(String raffleId) async {
    final response = await _dioClient.get(
      ApiEndpoints.raffleParticipants(raffleId),
    );
    final List<dynamic> data = response.data;
    return data.map((json) => ParticipantModel.fromJson(json)).toList();
  }

  /// Draw a winner
  Future<DrawResultModel> drawWinner(String raffleId) async {
    final response = await _dioClient.post(
      ApiEndpoints.raffleDraw(raffleId),
    );
    return DrawResultModel.fromJson(response.data);
  }

  /// Confirm winner presence (admin action)
  Future<RaffleModel> confirmWinner(String raffleId) async {
    final response = await _dioClient.post(
      ApiEndpoints.raffleConfirmWinner(raffleId),
    );
    // API returns { success: true, raffle: {...}, confirmedWinner: {...} }
    final data = response.data;
    if (data is Map && data.containsKey('raffle')) {
      return RaffleModel.fromJson(data['raffle']);
    }
    return RaffleModel.fromJson(data);
  }

  /// Reopen a raffle (clear winner and draw history)
  Future<RaffleModel> reopenRaffle(String raffleId) async {
    final response = await _dioClient.post(
      ApiEndpoints.raffleReopen(raffleId),
    );
    // API returns { success: true, raffle: {...} }
    final data = response.data;
    if (data is Map && data.containsKey('raffle')) {
      return RaffleModel.fromJson(data['raffle']);
    }
    return RaffleModel.fromJson(data);
  }

  /// Close registrations
  Future<RaffleModel> closeRegistrations(String raffleId) async {
    return updateRaffle(raffleId, const UpdateRaffleRequest(status: 'closed'));
  }

  /// Reopen registrations
  Future<RaffleModel> reopenRegistrations(String raffleId) async {
    return updateRaffle(raffleId, const UpdateRaffleRequest(status: 'active'));
  }

  /// Export participants as CSV
  Future<String> exportParticipants(String raffleId) async {
    final response = await _dioClient.get(
      ApiEndpoints.raffleExport(raffleId),
    );
    return response.data as String;
  }
}
