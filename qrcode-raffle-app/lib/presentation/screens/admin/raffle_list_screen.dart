import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/raffle_card_widget.dart';
import '../shared/confirmation_screen.dart';

class RaffleListScreen extends ConsumerWidget {
  const RaffleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(raffleListProvider);

    ref.listen<RaffleListState>(
      raffleListProvider,
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorteios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(raffleListProvider.notifier).refresh(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _FilterChips(
            currentFilter: state.filter,
            onFilterChanged: (filter) {
              ref.read(raffleListProvider.notifier).setFilter(filter);
            },
          ),

          // Content
          Expanded(
            child: _buildContent(context, ref, state),
          ),
        ],
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

  Widget _buildContent(BuildContext context, WidgetRef ref, RaffleListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.raffles.isEmpty) {
      return _buildError(context, ref, state.error!);
    }

    if (state.filteredRaffles.isEmpty) {
      return _buildEmpty(context, state.filter);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(raffleListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: state.filteredRaffles.length,
        itemBuilder: (context, index) {
          final raffle = state.filteredRaffles[index];
          return RaffleCardWidget(
            raffle: raffle,
            onTap: () => context.push('/admin/raffles/${raffle.id}'),
            onDelete: raffle.isActive
                ? () => _showDeleteDialog(context, ref, raffle.id, raffle.name)
                : null,
          ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * index),
                duration: const Duration(milliseconds: 300),
              );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              error,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(raffleListProvider.notifier).loadRaffles(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, RaffleStatusFilter filter) {
    String message;
    IconData icon;

    switch (filter) {
      case RaffleStatusFilter.all:
        message = 'Nenhum sorteio encontrado.\nCrie seu primeiro sorteio!';
        icon = Icons.add_circle_outline;
        break;
      case RaffleStatusFilter.active:
        message = 'Nenhum sorteio ativo no momento.';
        icon = Icons.play_circle_outline;
        break;
      case RaffleStatusFilter.closed:
        message = 'Nenhum sorteio fechado.';
        icon = Icons.pause_circle_outline;
        break;
      case RaffleStatusFilter.drawn:
        message = 'Nenhum sorteio realizado ainda.';
        icon = Icons.emoji_events_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await ConfirmationScreen.show(
      context: context,
      title: 'Excluir sorteio?',
      message: 'Tem certeza que deseja excluir "$name"?',
      subtitle: 'Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      type: ConfirmationType.delete,
    );

    if (confirmed) {
      ref.read(raffleListProvider.notifier).deleteRaffle(id);
    }
  }
}

class _FilterChips extends StatelessWidget {
  final RaffleStatusFilter currentFilter;
  final ValueChanged<RaffleStatusFilter> onFilterChanged;

  const _FilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Todos',
              isSelected: currentFilter == RaffleStatusFilter.all,
              onTap: () => onFilterChanged(RaffleStatusFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Ativos',
              isSelected: currentFilter == RaffleStatusFilter.active,
              onTap: () => onFilterChanged(RaffleStatusFilter.active),
              color: AppColors.statusActive,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Fechados',
              isSelected: currentFilter == RaffleStatusFilter.closed,
              onTap: () => onFilterChanged(RaffleStatusFilter.closed),
              color: AppColors.statusClosed,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Sorteados',
              isSelected: currentFilter == RaffleStatusFilter.drawn,
              onTap: () => onFilterChanged(RaffleStatusFilter.drawn),
              color: AppColors.statusDrawn,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : effectiveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveColor.withOpacity(isSelected ? 1 : 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : effectiveColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
