import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/event_model.dart';
import '../models/track_model.dart';
import '../models/talk_model.dart';
import '../models/attendance_model.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return EventService(dioClient);
});

class EventService {
  final DioClient _dioClient;

  EventService(this._dioClient);

  // ==================== Events ====================

  /// Get all events
  Future<List<EventModel>> getEvents() async {
    final response = await _dioClient.get(ApiEndpoints.events);
    final List<dynamic> data = response.data;
    return data.map((json) => EventModel.fromJson(json)).toList();
  }

  /// Get a single event by ID (with tracks)
  Future<EventModel> getEvent(String id) async {
    final response = await _dioClient.get(ApiEndpoints.eventById(id));
    return EventModel.fromJson(response.data);
  }

  /// Create a new event
  Future<EventModel> createEvent(CreateEventRequest request) async {
    final response = await _dioClient.post(
      ApiEndpoints.events,
      data: request.toJson(),
    );
    return EventModel.fromJson(response.data);
  }

  /// Update an existing event
  Future<EventModel> updateEvent(String id, UpdateEventRequest request) async {
    final response = await _dioClient.patch(
      ApiEndpoints.eventById(id),
      data: request.toJson(),
    );
    return EventModel.fromJson(response.data);
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    await _dioClient.delete(ApiEndpoints.eventById(id));
  }

  /// Get eligible count for event-based raffle
  Future<EligibleCountResponse> getEligibleCount(
    String eventId, {
    int? minDurationMinutes,
    int? minTalksCount,
    String? allowedDomain,
  }) async {
    final queryParams = <String, dynamic>{};
    if (minDurationMinutes != null) {
      queryParams['minDuration'] = minDurationMinutes;
    }
    if (minTalksCount != null) {
      queryParams['minTalks'] = minTalksCount;
    }
    if (allowedDomain != null) {
      queryParams['domain'] = allowedDomain;
    }

    final response = await _dioClient.get(
      ApiEndpoints.eventEligibleCount(eventId),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return EligibleCountResponse.fromJson(response.data);
  }

  // ==================== Tracks ====================

  /// Get all tracks for an event
  Future<List<TrackModel>> getTracksForEvent(String eventId) async {
    final response = await _dioClient.get(
      ApiEndpoints.tracks,
      queryParameters: {'eventId': eventId},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => TrackModel.fromJson(json)).toList();
  }

  /// Get a single track by ID (with talks)
  Future<TrackModel> getTrack(String id) async {
    final response = await _dioClient.get(ApiEndpoints.trackById(id));
    return TrackModel.fromJson(response.data);
  }

  /// Create a new track
  Future<TrackModel> createTrack(CreateTrackRequest request) async {
    final response = await _dioClient.post(
      ApiEndpoints.tracks,
      data: request.toJson(),
    );
    return TrackModel.fromJson(response.data);
  }

  /// Update an existing track
  Future<TrackModel> updateTrack(String id, UpdateTrackRequest request) async {
    final response = await _dioClient.patch(
      ApiEndpoints.trackById(id),
      data: request.toJson(),
    );
    return TrackModel.fromJson(response.data);
  }

  /// Delete a track
  Future<void> deleteTrack(String id) async {
    await _dioClient.delete(ApiEndpoints.trackById(id));
  }

  // ==================== Talks ====================

  /// Get all talks for a track
  Future<List<TalkModel>> getTalksForTrack(String trackId) async {
    final response = await _dioClient.get(
      ApiEndpoints.talks,
      queryParameters: {'trackId': trackId},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => TalkModel.fromJson(json)).toList();
  }

  /// Get a single talk by ID (with attendances)
  Future<TalkModel> getTalk(String id) async {
    final response = await _dioClient.get(ApiEndpoints.talkById(id));
    return TalkModel.fromJson(response.data);
  }

  /// Create a new talk
  Future<TalkModel> createTalk(CreateTalkRequest request) async {
    final response = await _dioClient.post(
      ApiEndpoints.talks,
      data: request.toJson(),
    );
    return TalkModel.fromJson(response.data);
  }

  /// Update an existing talk
  Future<TalkModel> updateTalk(String id, UpdateTalkRequest request) async {
    final response = await _dioClient.patch(
      ApiEndpoints.talkById(id),
      data: request.toJson(),
    );
    return TalkModel.fromJson(response.data);
  }

  /// Delete a talk
  Future<void> deleteTalk(String id) async {
    await _dioClient.delete(ApiEndpoints.talkById(id));
  }

  // ==================== Attendances ====================

  /// Get attendances for a talk
  Future<List<AttendanceModel>> getAttendances(String talkId) async {
    final response = await _dioClient.get(ApiEndpoints.talkAttendance(talkId));
    final List<dynamic> data = response.data;
    return data.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  /// Add an attendance to a talk
  Future<AttendanceModel> addAttendance(
    String talkId,
    CreateAttendanceRequest request,
  ) async {
    final response = await _dioClient.post(
      ApiEndpoints.talkAttendance(talkId),
      data: request.toJson(),
    );
    return AttendanceModel.fromJson(response.data);
  }

  /// Add multiple attendances at once
  Future<List<AttendanceModel>> addBulkAttendances(
    String talkId,
    List<CreateAttendanceRequest> attendances,
  ) async {
    final response = await _dioClient.post(
      '${ApiEndpoints.talkAttendance(talkId)}/bulk',
      data: {'attendances': attendances.map((a) => a.toJson()).toList()},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  /// Delete an attendance
  Future<void> deleteAttendance(String talkId, String attendanceId) async {
    await _dioClient.delete(
      ApiEndpoints.talkAttendanceById(talkId, attendanceId),
    );
  }
}
