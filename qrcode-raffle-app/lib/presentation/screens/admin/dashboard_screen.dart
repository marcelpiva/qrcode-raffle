import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/raffle.dart';
import '../../providers/raffle_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/raffle_card_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raffleState = ref.watch(raffleListProvider);
    final authStateAsync = ref.watch(authStateProvider);
    final authState = authStateAsync.valueOrNull;
    final isDark = ref.watch(isDarkModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            tooltip: isDark ? 'Modo claro' : 'Modo escuro',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(raffleListProvider.notifier).refresh(),
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              radius: 16,
              child: Text(
                (authState?.user?.name ?? 'A')[0].toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authStateProvider.notifier).logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState?.user?.name ?? 'Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      authState?.user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Sair', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(raffleListProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _WelcomeSection(userName: authState?.user?.name ?? 'Admin')
                  .animate()
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 24),

              // Stats cards
              _StatsSection(raffles: raffleState.raffles)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 24),

              // Quick actions
              _QuickActionsSection()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 24),

              // Recent raffles
              _RecentRafflesSection(
                raffles: raffleState.raffles,
                isLoading: raffleState.isLoading,
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/raffles/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Sorteio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String userName;

  const _WelcomeSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Bom dia';
    } else if (hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        Text(
          userName.split(' ').first,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<Raffle> raffles;

  const _StatsSection({required this.raffles});

  @override
  Widget build(BuildContext context) {
    final active = raffles.where((r) => r.isActive).length;
    final closed = raffles.where((r) => r.isClosed).length;
    final drawn = raffles.where((r) => r.isDrawn).length;
    final totalParticipants =
        raffles.fold<int>(0, (sum, r) => sum + r.totalParticipants);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Resumo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Total',
              value: '${raffles.length}',
              subtitle: 'sorteios',
              icon: Icons.casino,
              color: AppColors.primary,
            ),
            _StatCard(
              title: 'Ativos',
              value: '$active',
              subtitle: 'abertos',
              icon: Icons.play_circle,
              color: AppColors.statusActive,
            ),
            _StatCard(
              title: 'Finalizados',
              value: '$drawn',
              subtitle: 'sorteados',
              icon: Icons.emoji_events,
              color: AppColors.statusDrawn,
            ),
            _StatCard(
              title: 'Participações',
              value: '$totalParticipants',
              subtitle: 'nos sorteios',
              icon: Icons.how_to_reg,
              color: AppColors.info,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, size: 20, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle,
                label: 'Novo Sorteio',
                color: AppColors.primary,
                onTap: () => context.push('/admin/raffles/new'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.list_alt,
                label: 'Sorteios',
                color: AppColors.secondary,
                onTap: () => context.push('/admin/raffles'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.event,
                label: 'Eventos',
                color: AppColors.info,
                onTap: () => context.push('/admin/events'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.leaderboard,
                label: 'Ranking',
                color: AppColors.success,
                onTap: () => context.push('/admin/ranking'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRafflesSection extends StatelessWidget {
  final List<Raffle> raffles;
  final bool isLoading;

  const _RecentRafflesSection({
    required this.raffles,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final recentRaffles = raffles.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Sorteios Recentes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/admin/raffles'),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recentRaffles.isEmpty)
          _buildEmptyState(context)
        else
          Column(
            children: recentRaffles.map((raffle) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RaffleCardWidget(
                  raffle: raffle,
                  onTap: () => context.push('/admin/raffles/${raffle.id}'),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.casino,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum sorteio ainda',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crie seu primeiro sorteio!',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/admin/raffles/new'),
              icon: const Icon(Icons.add),
              label: const Text('Criar Sorteio'),
            ),
          ],
        ),
      ),
    );
  }
}
