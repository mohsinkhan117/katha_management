// lib/ui/customers/customers_view.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/party_balance_summary.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/core/widgets/glass_card.dart';
import 'package:katha_management/ui/customers/customers_view_model.dart';
import 'package:katha_management/ui/features/add_party/add_party_view.dart';
import 'package:katha_management/ui/party_history/party_history_view.dart';
import 'package:provider/provider.dart';

class CustomersView extends StatelessWidget {
  static const String routeName = '/customers-view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const CustomersView(),
      settings: const RouteSettings(name: routeName),
    );
  }

  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomersViewModel(),
      child: const _CustomersViewBody(),
    );
  }
}

class _CustomersViewBody extends StatelessWidget {
  const _CustomersViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.customersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: AppStrings.addPartyTitle,
            onPressed: () async {
              await Navigator.pushNamed(context, AddPartyView.routeName);
              if (context.mounted) {
                context.read<CustomersViewModel>().refresh();
              }
            },
          ),
        ],
      ),
      body: AmbientScaffoldBackground(
        child: SafeArea(
          bottom: false,
          child: Consumer<CustomersViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.parties.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Compute aggregate stats for bento summary widgets
              final totalParties = vm.parties.length;
              final totalDue = vm.parties.fold<double>(
                0.0,
                (sum, p) => sum + (p.balanceDue > 0 ? p.balanceDue : 0),
              );

              return RefreshIndicator(
                onRefresh: vm.refresh,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  children: [
                    // Bento Metrics Row (Dual Square iOS Widgets)
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.people_outline_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      AppStrings.all,
                                      style: TextStyle(
                                        fontSize: AppSizes.fontSizeSm,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  '$totalParties',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.customersTitle,
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSizeSm,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spaceBtwItems),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.tetraColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 18,
                                        color: AppColors.tetraColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  'Rs ${totalDue.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        color: AppColors.tetraColor,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.receivables,
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSizeSm,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 22),
                        hintText: AppStrings.searchCustomersHint,
                      ),
                      onChanged: (value) => context
                          .read<CustomersViewModel>()
                          .setSearchQuery(value),
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    // Error Message
                    if (vm.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm + 2),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceBtwItems),
                    ],

                    // Customer List or Empty State
                    if (vm.parties.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_outline,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                AppStrings.noCustomersYet,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: AppSizes.fontSizeMd,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...vm.parties.map(
                        (summary) => _CustomerTile(summary: summary),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.summary});
  final PartyBalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasBalance = summary.balanceDue > 0;
    final avatarColor = isDark ? AppColors.accent : AppColors.primary;

    return GlassCard(
      borderRadius: 18,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      onTap: () async {
        await Navigator.pushNamed(
          context,
          PartyHistoryView.routeName,
          arguments: summary.partyId,
        );
        if (context.mounted) {
          context.read<CustomersViewModel>().refresh();
        }
      },
      child: Row(
        children: [
          // Squircle Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: avatarColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                summary.partyName.isNotEmpty
                    ? summary.partyName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Name and Phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.partyName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        summary.partyPhone ?? AppStrings.noPhoneOnFile,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Balance Badge & Action Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasBalance
                      ? AppColors.tetraColor.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasBalance
                        ? AppColors.tetraColor.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  hasBalance
                      ? 'Rs ${summary.balanceDue.toStringAsFixed(0)}'
                      : AppStrings.settled,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasBalance
                        ? AppColors.tetraColor
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppColors.textSecondary,
            ),
            padding: EdgeInsets.zero,
            onSelected: (action) async {
              final vm = context.read<CustomersViewModel>();
              if (action == 'edit') {
                final party = await vm.getParty(summary.partyId);
                if (party != null && context.mounted) {
                  final updated = await Navigator.push(
                    context,
                    AddPartyView.route(partyToEdit: party),
                  );
                  if (updated == true && context.mounted) {
                    vm.refresh();
                  }
                }
              } else if (action == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppStrings.deletePartyTitle),
                    content: Text(AppStrings.deletePartyMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppStrings.no),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: Text(AppStrings.deletePartyButton),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final deleted = await vm.deleteParty(summary.partyId);
                  if (deleted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.partyDeletedSuccess)),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: avatarColor),
                    const SizedBox(width: 8),
                    Text(AppStrings.editPartyTitle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(AppStrings.deletePartyButton),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
