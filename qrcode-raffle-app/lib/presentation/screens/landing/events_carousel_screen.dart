import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/entities/talk.dart';
import '../../providers/events_provider.dart';

/// Landing screen with event carousel - similar to web version
class EventsCarouselScreen extends ConsumerStatefulWidget {
  const EventsCarouselScreen({super.key});

  @override
  ConsumerState<EventsCarouselScreen> createState() => _EventsCarouselScreenState();
}

class _EventsCarouselScreenState extends ConsumerState<EventsCarouselScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  late AnimationController _meshController;
  int _currentIndex = 0;
  bool _showTimeline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(viewportFraction: 0.9);
    _meshController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _meshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      ref.read(eventsListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // Animated gradient mesh background
          _buildAnimatedBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Carousel area
                Expanded(
                  child: eventsState.isLoading
                      ? _buildLoadingState()
                      : eventsState.events.isEmpty
                          ? _buildEmptyState()
                          : _buildCarousel(eventsState.events),
                ),

                // Footer
                _buildFooter(),
              ],
            ),
          ),

          // Timeline overlay
          if (_showTimeline && eventsState.events.isNotEmpty)
            _buildTimelineOverlay(eventsState.events[_currentIndex]),

          // Menu FAB - hide when timeline is open
          if (!_showTimeline)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _buildMenuButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _meshController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF09090B),
          ),
          child: Stack(
            children: [
              // Purple orb - top left
              Positioned(
                top: -100 + (30 * math.sin(_meshController.value * 2 * math.pi)),
                left: -50 + (20 * math.cos(_meshController.value * 2 * math.pi)),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C3AED).withOpacity(0.3),
                        const Color(0xFF7C3AED).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Pink orb - bottom right
              Positioned(
                bottom: -100 + (40 * math.cos(_meshController.value * 2 * math.pi)),
                right: -80 + (50 * math.sin(_meshController.value * 2 * math.pi)),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFDB2777).withOpacity(0.2),
                        const Color(0xFFDB2777).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Grid overlay
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _GridPainter(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 60, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo with glow
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/nava-icon.jpg',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.celebration, color: Colors.white, size: 24),
                ),
              ),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 12),
          // Brand text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'NAVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFF472B6)],
                    ).createShader(bounds),
                    child: const Text(
                      'SUMMIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'EVENTOS & SORTEIOS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/dashboard'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.dashboard_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 22,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF9333EA).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF9333EA),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando eventos...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9333EA).withOpacity(0.15),
                  const Color(0xFFDB2777).withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF9333EA).withOpacity(0.2),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFFF472B6)],
              ).createShader(bounds),
              child: const Icon(
                Icons.calendar_month,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Em Breve',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Novos eventos em preparação',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }

  Widget _buildCarousel(List<Event> events) {
    return Column(
      children: [
        // Carousel
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showTimeline = false;
              });
            },
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event, index);
            },
          ),
        ),

        // Pagination dots
        if (events.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(events.length, (index) {
                final isActive = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                            )
                          : null,
                      color: isActive ? null : Colors.white.withOpacity(0.2),
                    ),
                  ),
                );
              }),
            ),
          ).animate().fadeIn(delay: 400.ms),

        // Swipe hint
        Text(
          '← Arraste para navegar →',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 12,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildEventCard(Event event, int index) {
    final status = _getEventStatus(event);
    final config = _statusConfig[status]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181B).withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: config['borderColor'] as Color,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (config['glowColor'] as Color).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStatusBadge(status, config),
            ),

            // Event content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateRange(event.startDate, event.endDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 12),

                    // Event name
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),

                    const Spacer(),

                    // Stats grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.layers_outlined,
                            value: event.totalTracks.toString(),
                            label: event.totalTracks == 1 ? 'Trilha' : 'Trilhas',
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people_outline,
                            value: event.totalAttendances.toString(),
                            label: event.totalAttendances == 1 ? 'Presença' : 'Presenças',
                            color: const Color(0xFFF472B6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.emoji_events_outlined,
                            value: '${event.totalTracks}',
                            label: 'Sorteios',
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Ver Programação button
            if (event.totalTracks > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9333EA).withOpacity(0.15),
                        const Color(0xFFDB2777).withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF9333EA).withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _showTimeline = true),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.mic_none,
                              size: 18,
                              color: Color(0xFFC084FC),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ver Programação',
                              style: TextStyle(
                                color: Color(0xFFC084FC),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: const Color(0xFFC084FC).withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)),
    );
  }

  Widget _buildStatusBadge(String status, Map<String, dynamic> config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['bgColor'] as Color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (config['glowColor'] as Color).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'happening')
            Container(
              margin: const EdgeInsets.only(right: 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: config['dotColor'] as Color,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(begin: 1, end: 1.5, duration: 1.seconds)
                      .fadeOut(duration: 1.seconds),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: config['dotColor'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          Icon(
            config['icon'] as IconData,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            config['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineOverlay(Event event) {
    final eventDetail = ref.watch(eventDetailProvider(event.id));

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _showTimeline ? 1 : 0,
      child: Container(
        color: const Color(0xFF09090B).withOpacity(0.98),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFA855F7), Color(0xFFF472B6)],
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Programação',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _showTimeline = false),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.6),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),

              // Timeline content
              Expanded(
                child: eventDetail.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF9333EA),
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Carregando programação...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : eventDetail.tracks.isEmpty
                        ? _buildEmptyTimeline()
                        : _buildTimelineContent(eventDetail.tracks),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9333EA).withOpacity(0.15),
                  const Color(0xFFDB2777).withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF9333EA).withOpacity(0.2),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFFF472B6)],
              ).createShader(bounds),
              child: const Icon(
                Icons.schedule,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Em Breve',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A programação será disponibilizada em breve',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }

  Widget _buildTimelineContent(List<Track> tracks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _buildTrackSection(track, index);
      },
    );
  }

  Widget _buildTrackSection(Track track, int index) {
    final trackColor = _parseColor(track.color) ?? _trackColors[index % _trackColors.length];
    final talks = track.talks ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: trackColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: trackColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: trackColor,
                    boxShadow: [
                      BoxShadow(
                        color: trackColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    track.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${track.totalTalks} ${track.totalTalks == 1 ? 'palestra' : 'palestras'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: -0.05, end: 0),

          // Talks timeline
          if (talks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...talks.asMap().entries.map((entry) {
              final talkIndex = entry.key;
              final talk = entry.value;
              final isLast = talkIndex == talks.length - 1;
              return _buildTalkItem(talk, trackColor, isLast, index, talkIndex);
            }),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTalkItem(Talk talk, Color trackColor, bool isLast, int trackIndex, int talkIndex) {
    final status = _getTalkStatus(talk);
    final statusConfig = _talkStatusConfig[status]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == 'ongoing'
                        ? statusConfig['color'] as Color
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: status == 'ongoing'
                          ? (statusConfig['color'] as Color)
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: status == 'ongoing'
                        ? [
                            BoxShadow(
                              color: (statusConfig['color'] as Color).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),

          // Talk content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: status == 'ongoing'
                    ? (statusConfig['color'] as Color).withOpacity(0.1)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: status == 'ongoing'
                      ? (statusConfig['color'] as Color).withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge and time
                  Row(
                    children: [
                      if (talk.startTime != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(talk.startTime!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (talk.endTime != null) ...[
                          Text(
                            ' - ${_formatTime(talk.endTime!)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                      if (status != 'upcoming')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (statusConfig['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusConfig['label'] as String,
                            style: TextStyle(
                              color: statusConfig['color'] as Color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Talk title
                  Text(
                    talk.title,
                    style: TextStyle(
                      color: status == 'finished'
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  // Description
                  if (talk.description != null && talk.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      talk.description!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Speaker
                  if (talk.speaker != null && talk.speaker!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: trackColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            talk.speaker!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Room
                  if (talk.room != null && talk.room!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          talk.room!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * (trackIndex + talkIndex))).slideX(begin: 0.05, end: 0),
          ),
        ],
      ),
    );
  }

  String _getTalkStatus(Talk talk) {
    if (talk.hasEnded) return 'finished';
    if (talk.isOngoing) return 'ongoing';
    return 'upcoming';
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }

  static const List<Color> _trackColors = [
    Color(0xFFA855F7), // Purple
    Color(0xFFF472B6), // Pink
    Color(0xFF38BDF8), // Sky
    Color(0xFF4ADE80), // Green
    Color(0xFFFBBF24), // Amber
    Color(0xFFF97316), // Orange
  ];

  static final Map<String, Map<String, dynamic>> _talkStatusConfig = {
    'ongoing': {
      'label': 'AO VIVO',
      'color': const Color(0xFF10B981),
    },
    'finished': {
      'label': 'ENCERRADO',
      'color': const Color(0xFF71717A),
    },
    'upcoming': {
      'label': 'EM BREVE',
      'color': const Color(0xFF0EA5E9),
    },
  };

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF9333EA),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'NAVA Summit ${DateTime.now().year}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDB2777),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  String _getEventStatus(Event event) {
    if (event.hasEnded) return 'finished';
    if (event.isOngoing) return 'happening';
    return 'upcoming';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '-';

    final months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    final day = start.day.toString().padLeft(2, '0');
    final month = months[start.month - 1];

    if (end == null || (start.day == end.day && start.month == end.month)) {
      return '$day $month';
    }

    final endDay = end.day.toString().padLeft(2, '0');
    return '$day-$endDay $month';
  }

  static final Map<String, Map<String, dynamic>> _statusConfig = {
    'happening': {
      'label': 'AO VIVO',
      'bgColor': const Color(0xFF10B981),
      'glowColor': const Color(0xFF10B981),
      'dotColor': const Color(0xFF6EE7B7),
      'borderColor': const Color(0xFF10B981).withOpacity(0.3),
      'icon': Icons.auto_awesome,
    },
    'upcoming': {
      'label': 'EM BREVE',
      'bgColor': const Color(0xFF0EA5E9),
      'glowColor': const Color(0xFF0EA5E9),
      'dotColor': const Color(0xFF7DD3FC),
      'borderColor': const Color(0xFF0EA5E9).withOpacity(0.3),
      'icon': Icons.schedule,
    },
    'finished': {
      'label': 'ENCERRADO',
      'bgColor': const Color(0xFF71717A),
      'glowColor': const Color(0xFF71717A),
      'dotColor': const Color(0xFFA1A1AA),
      'borderColor': const Color(0xFF71717A).withOpacity(0.3),
      'icon': Icons.emoji_events,
    },
  };
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    const spacing = 50.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
