import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/event_model.dart';
import '../../data/models/track_model.dart';
import '../../data/models/talk_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/services/event_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/talk.dart';
import '../../domain/entities/attendance.dart';

// ============================================================================
// Events List State & Provider
// ============================================================================

class EventsListState {
  final List<Event> events;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const EventsListState({
    this.events = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  EventsListState copyWith({
    List<Event>? events,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
  }) {
    return EventsListState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

class EventsListNotifier extends StateNotifier<EventsListState> {
  final EventService _service;

  EventsListNotifier(this._service)
      : super(const EventsListState(isLoading: true)) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final models = await _service.getEvents();
      final events = models.map((m) => m.toEntity()).toList();
      // Sort by startDate descending, then createdAt
      events.sort((a, b) {
        if (a.startDate != null && b.startDate != null) {
          return b.startDate!.compareTo(a.startDate!);
        }
        final aCreated = a.createdAt ?? DateTime(1970);
        final bCreated = b.createdAt ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });
      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar eventos: $e');
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final models = await _service.getEvents();
      final events = models.map((m) => m.toEntity()).toList();
      events.sort((a, b) {
        if (a.startDate != null && b.startDate != null) {
          return b.startDate!.compareTo(a.startDate!);
        }
        final aCreated = a.createdAt ?? DateTime(1970);
        final bCreated = b.createdAt ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });
      state = state.copyWith(
        events: events,
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

  Future<Event?> createEvent(CreateEventRequest request) async {
    try {
      final model = await _service.createEvent(request);
      final event = model.toEntity();
      state = state.copyWith(
        events: [event, ...state.events],
      );
      return event;
    } on ValidationException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } on ServerException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao criar evento: $e');
      return null;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _service.deleteEvent(id);
      state = state.copyWith(
        events: state.events.where((e) => e.id != id).toList(),
      );
    } on ServerException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao deletar evento: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final eventsListProvider =
    StateNotifierProvider<EventsListNotifier, EventsListState>((ref) {
  final service = ref.watch(eventServiceProvider);
  return EventsListNotifier(service);
});

// ============================================================================
// Event Detail State & Provider
// ============================================================================

class EventDetailState {
  final Event? event;
  final List<Track> tracks;
  final bool isLoading;
  final bool isActionLoading;
  final String? error;
  final String? actionError;
  final int? eligibleCount;

  const EventDetailState({
    this.event,
    this.tracks = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.actionError,
    this.eligibleCount,
  });

  EventDetailState copyWith({
    Event? event,
    List<Track>? tracks,
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    String? actionError,
    int? eligibleCount,
  }) {
    return EventDetailState(
      event: event ?? this.event,
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error,
      actionError: actionError,
      eligibleCount: eligibleCount ?? this.eligibleCount,
    );
  }
}

class EventDetailNotifier extends StateNotifier<EventDetailState> {
  final EventService _service;
  final String eventId;

  EventDetailNotifier(this._service, this.eventId)
      : super(const EventDetailState(isLoading: true)) {
    loadEvent();
  }

  Future<void> loadEvent() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final model = await _service.getEvent(eventId);
      final event = model.toEntity();
      final tracks = event.tracks ?? [];
      state = state.copyWith(
        event: event,
        tracks: tracks,
        isLoading: false,
      );
    } on NotFoundException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar evento: $e');
    }
  }

  Future<void> refresh() async {
    await loadEvent();
  }

  Future<Track?> createTrack(CreateTrackRequest request) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.createTrack(request);
      final track = model.toEntity();
      state = state.copyWith(
        tracks: [...state.tracks, track],
        isActionLoading: false,
      );
      return track;
    } on ValidationException catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao criar trilha: $e',
      );
      return null;
    }
  }

  Future<void> deleteTrack(String trackId) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _service.deleteTrack(trackId);
      state = state.copyWith(
        tracks: state.tracks.where((t) => t.id != trackId).toList(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao deletar trilha: $e',
      );
    }
  }

  Future<void> getEligibleCount({
    int? minDurationMinutes,
    int? minTalksCount,
    String? allowedDomain,
  }) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final response = await _service.getEligibleCount(
        eventId,
        minDurationMinutes: minDurationMinutes,
        minTalksCount: minTalksCount,
        allowedDomain: allowedDomain,
      );
      state = state.copyWith(
        eligibleCount: response.count,
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao calcular elegíveis: $e',
      );
    }
  }

  void clearActionError() {
    state = state.copyWith(actionError: null);
  }
}

final eventDetailProvider =
    StateNotifierProvider.family<EventDetailNotifier, EventDetailState, String>(
  (ref, eventId) {
    final service = ref.watch(eventServiceProvider);
    return EventDetailNotifier(service, eventId);
  },
);

// ============================================================================
// Track Detail State & Provider
// ============================================================================

class TrackDetailState {
  final Track? track;
  final List<Talk> talks;
  final bool isLoading;
  final bool isActionLoading;
  final String? error;
  final String? actionError;

  const TrackDetailState({
    this.track,
    this.talks = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.actionError,
  });

  TrackDetailState copyWith({
    Track? track,
    List<Talk>? talks,
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    String? actionError,
  }) {
    return TrackDetailState(
      track: track ?? this.track,
      talks: talks ?? this.talks,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error,
      actionError: actionError,
    );
  }
}

class TrackDetailNotifier extends StateNotifier<TrackDetailState> {
  final EventService _service;
  final String trackId;

  TrackDetailNotifier(this._service, this.trackId)
      : super(const TrackDetailState(isLoading: true)) {
    loadTrack();
  }

  Future<void> loadTrack() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final model = await _service.getTrack(trackId);
      final track = model.toEntity();
      final talks = track.talks ?? [];
      // Sort by startTime
      talks.sort((a, b) {
        if (a.startTime != null && b.startTime != null) {
          return a.startTime!.compareTo(b.startTime!);
        }
        return a.title.compareTo(b.title);
      });
      state = state.copyWith(
        track: track,
        talks: talks,
        isLoading: false,
      );
    } on NotFoundException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar trilha: $e');
    }
  }

  Future<void> refresh() async {
    await loadTrack();
  }

  Future<Talk?> createTalk(CreateTalkRequest request) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.createTalk(request);
      final talk = model.toEntity();
      final talks = [...state.talks, talk];
      talks.sort((a, b) {
        if (a.startTime != null && b.startTime != null) {
          return a.startTime!.compareTo(b.startTime!);
        }
        return a.title.compareTo(b.title);
      });
      state = state.copyWith(
        talks: talks,
        isActionLoading: false,
      );
      return talk;
    } on ValidationException catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao criar palestra: $e',
      );
      return null;
    }
  }

  Future<void> deleteTalk(String talkId) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _service.deleteTalk(talkId);
      state = state.copyWith(
        talks: state.talks.where((t) => t.id != talkId).toList(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao deletar palestra: $e',
      );
    }
  }

  void clearActionError() {
    state = state.copyWith(actionError: null);
  }
}

final trackDetailProvider =
    StateNotifierProvider.family<TrackDetailNotifier, TrackDetailState, String>(
  (ref, trackId) {
    final service = ref.watch(eventServiceProvider);
    return TrackDetailNotifier(service, trackId);
  },
);

// ============================================================================
// Talk Detail State & Provider
// ============================================================================

class TalkDetailState {
  final Talk? talk;
  final List<Attendance> attendances;
  final bool isLoading;
  final bool isActionLoading;
  final String? error;
  final String? actionError;

  const TalkDetailState({
    this.talk,
    this.attendances = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.actionError,
  });

  TalkDetailState copyWith({
    Talk? talk,
    List<Attendance>? attendances,
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    String? actionError,
  }) {
    return TalkDetailState(
      talk: talk ?? this.talk,
      attendances: attendances ?? this.attendances,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error,
      actionError: actionError,
    );
  }
}

class TalkDetailNotifier extends StateNotifier<TalkDetailState> {
  final EventService _service;
  final String talkId;

  TalkDetailNotifier(this._service, this.talkId)
      : super(const TalkDetailState(isLoading: true)) {
    loadTalk();
  }

  Future<void> loadTalk() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final model = await _service.getTalk(talkId);
      final talk = model.toEntity();
      final attendances = talk.attendances ?? [];
      // Sort by name
      attendances.sort((a, b) => a.displayName.compareTo(b.displayName));
      state = state.copyWith(
        talk: talk,
        attendances: attendances,
        isLoading: false,
      );
    } on NotFoundException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar palestra: $e');
    }
  }

  Future<void> refresh() async {
    await loadTalk();
  }

  Future<Attendance?> addAttendance(CreateAttendanceRequest request) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final model = await _service.addAttendance(talkId, request);
      final attendance = model.toEntity();
      final attendances = [...state.attendances, attendance];
      attendances.sort((a, b) => a.displayName.compareTo(b.displayName));
      state = state.copyWith(
        attendances: attendances,
        isActionLoading: false,
      );
      return attendance;
    } on ValidationException catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao adicionar presença: $e',
      );
      return null;
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _service.deleteAttendance(talkId, attendanceId);
      state = state.copyWith(
        attendances: state.attendances.where((a) => a.id != attendanceId).toList(),
        isActionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionError: 'Erro ao remover presença: $e',
      );
    }
  }

  void clearActionError() {
    state = state.copyWith(actionError: null);
  }
}

final talkDetailProvider =
    StateNotifierProvider.family<TalkDetailNotifier, TalkDetailState, String>(
  (ref, talkId) {
    final service = ref.watch(eventServiceProvider);
    return TalkDetailNotifier(service, talkId);
  },
);
