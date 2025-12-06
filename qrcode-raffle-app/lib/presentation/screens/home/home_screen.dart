import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 1: Eventos (principal)
          _buildEventsTab(),

          // Tab 2: Scanner
          _buildScannerTab(context),

          // Tab 3: Menu/Mais
          _buildMenuTab(context, isAdmin),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final eventsState = ref.watch(eventsListProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(eventsListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(eventsListProvider.notifier).refresh();
        },
        child: eventsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : eventsState.error != null
                ? _buildErrorState(context, eventsState.error!)
                : eventsState.events.isEmpty
                    ? _buildEmptyState(context)
                    : _buildEventsList(eventsState.events, user?.name ?? 'Usuário'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/events/new'),
        icon: const Icon(Icons.add),
        label: const Text('Criar Evento'),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events, String userName) {
    return CustomScrollView(
      slivers: [
        // Welcome header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $userName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gerencie seus eventos e sorteios',
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
          ),
        ),

        // Events section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seus Eventos (${events.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Events list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = events[index];
                return _buildEventCard(event, index);
              },
              childCount: events.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr = event.startDate != null ? dateFormat.format(event.startDate!) : '-';
    final endStr = event.endDate != null ? dateFormat.format(event.endDate!) : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(200),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$startStr - $endStr',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEventStatusChip(event),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          context,
                          Icons.layers,
                          '${event.totalTracks} trilhas',
                        ),
                        _buildStatChip(
                          context,
                          Icons.mic,
                          '${event.totalTalks} palestras',
                        ),
                        _buildStatChip(
                          context,
                          Icons.people,
                          '${event.totalAttendances} presenças',
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textTertiary(context)),
                ],
              ),
            ),

            // Quick actions
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/admin/raffles/new?eventId=${event.id}'),
                    icon: const Icon(Icons.casino, size: 18),
                    label: const Text('Criar Sorteio'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildEventStatusChip(Event event) {
    String label;
    Color color;

    if (event.hasEnded) {
      label = 'Encerrado';
      color = Colors.grey;
    } else if (event.isOngoing) {
      label = 'Em andamento';
      color = Colors.green;
    } else {
      label = 'Futuro';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorAdaptive(context)),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar eventos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(eventsListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textTertiary(context)),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie seu primeiro evento para começar\na gerenciar trilhas, palestras e sorteios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/admin/events/new'),
              icon: const Icon(Icons.add),
              label: const Text('Criar Evento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryAdaptive(context).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: AppColors.primaryAdaptive(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanner de QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escaneie o QR Code de um sorteio\npara participar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/qr-scanner'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Abrir Scanner'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context, bool isAdmin) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAdmin) ...[
            _buildMenuSection(context, 'Sorteios'),
            _buildMenuTile(
              context: context,
              icon: Icons.casino,
              title: 'Todos os Sorteios',
              subtitle: 'Ver e gerenciar sorteios',
              onTap: () => context.push('/admin/raffles'),
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.add_circle,
              title: 'Criar Sorteio',
              subtitle: 'Novo sorteio independente',
              onTap: () => context.push('/admin/raffles/new'),
            ),
            const SizedBox(height: 16),
            _buildMenuSection(context, 'Relatórios'),
            _buildMenuTile(
              context: context,
              icon: Icons.leaderboard,
              title: 'Ranking',
              subtitle: 'Ranking de participantes',
              onTap: () => context.push('/admin/ranking'),
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              subtitle: 'Visão geral',
              onTap: () => context.push('/admin'),
            ),
          ] else ...[
            _buildMenuSection(context, 'Participação'),
            _buildMenuTile(
              context: context,
              icon: Icons.leaderboard,
              title: 'Ranking',
              subtitle: 'Ver sua posição',
              onTap: () => context.push('/admin/ranking'),
            ),
          ],
          const SizedBox(height: 16),
          _buildMenuSection(context, 'Conta'),
          _buildMenuTile(
            context: context,
            icon: Icons.logout,
            title: 'Sair',
            subtitle: 'Encerrar sessão',
            onTap: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary(context),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.errorAdaptive(context) : AppColors.primaryAdaptive(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

}
