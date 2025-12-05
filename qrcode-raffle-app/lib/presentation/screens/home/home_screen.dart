import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Raffle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home tab
          _buildHomeTab(user?.name ?? 'Usuário', isAdmin),

          // QR Scanner tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Scanner de QR Code'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/qr-scanner'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Abrir Scanner'),
                ),
              ],
            ),
          ),

          // Admin tab (only for admins)
          if (isAdmin)
            _buildAdminTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(String userName, bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Container(
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
                        isAdmin
                            ? 'Gerencie seus sorteios'
                            : 'Participe de sorteios',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          const Text(
            'Ações Rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Action cards
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Escanear',
                  subtitle: 'Participar de sorteio',
                  onTap: () => context.push('/qr-scanner'),
                ),
              ),
              const SizedBox(width: 16),
              if (isAdmin)
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Criar',
                    subtitle: 'Novo sorteio',
                    onTap: () => context.push('/admin/raffles/new'),
                  ),
                )
              else
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.leaderboard_outlined,
                    title: 'Ranking',
                    subtitle: 'Ver posição',
                    onTap: () => context.push('/admin/ranking'),
                  ),
                ),
            ],
          ),

          if (isAdmin) ...[
            const SizedBox(height: 24),

            // Admin section
            const Text(
              'Administração',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildListTile(
              icon: Icons.list_alt,
              title: 'Meus Sorteios',
              subtitle: 'Gerenciar sorteios criados',
              onTap: () => context.push('/admin/raffles'),
            ),

            _buildListTile(
              icon: Icons.analytics_outlined,
              title: 'Ranking',
              subtitle: 'Ver ranking de participantes',
              onTap: () => context.push('/admin/ranking'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Painel Administrativo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _buildListTile(
            icon: Icons.dashboard,
            title: 'Dashboard',
            subtitle: 'Visão geral',
            onTap: () => context.push('/admin'),
          ),

          _buildListTile(
            icon: Icons.list_alt,
            title: 'Sorteios',
            subtitle: 'Gerenciar todos os sorteios',
            onTap: () => context.push('/admin/raffles'),
          ),

          _buildListTile(
            icon: Icons.add_circle,
            title: 'Criar Sorteio',
            subtitle: 'Novo sorteio',
            onTap: () => context.push('/admin/raffles/new'),
          ),

          _buildListTile(
            icon: Icons.leaderboard,
            title: 'Ranking',
            subtitle: 'Ranking de participantes',
            onTap: () => context.push('/admin/ranking'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
