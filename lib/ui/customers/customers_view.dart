import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/ui/features/add_party/add_party_view.dart';
import 'package:provider/provider.dart';

import '../../core/constants/sizes/sizes.dart';
import '../../core/models/party_balance_summary.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../party_history/party_history_view.dart';
import 'customers_view_model.dart';

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
      body: Consumer<CustomersViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.parties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: AppStrings.searchCustomersHint,
                    ),
                    onChanged: (value) => context
                        .read<CustomersViewModel>()
                        .setSearchQuery(value),
                  ),
                ),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                Expanded(
                  child: vm.parties.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.noCustomersYet,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                          ),
                          itemCount: vm.parties.length,
                          itemBuilder: (context, index) {
                            return _CustomerTile(summary: vm.parties[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.summary});
  final PartyBalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasBalance = summary.balanceDue > 0;

    return Card(
      elevation: AppSizes.cardElevation,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
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
        leading: CircleAvatar(
          backgroundColor: AppColors.lightContainer,
          child: Text(
            summary.partyName.isNotEmpty ? summary.partyName[0] : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          summary.partyName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          summary.partyPhone ?? AppStrings.noPhoneOnFile,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            hasBalance
                ? Text(
                    'Rs ${summary.balanceDue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.tetraColor,
                    ),
                  )
                : Text(
                    AppStrings.settled,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.success,
                    ),
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
                            foregroundColor: AppColors.error,
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
                        SnackBar(
                          content: Text(AppStrings.partyDeletedSuccess),
                        ),
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
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
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
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(AppStrings.deletePartyButton),
                    ],
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
