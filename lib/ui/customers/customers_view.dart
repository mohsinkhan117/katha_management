// lib/ui/customers/customers_view.dart

import 'package:flutter/material.dart';
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
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or phone',
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
                      ? const Center(
                          child: Text(
                            'No customers yet',
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
          summary.partyPhone ?? 'No phone on file',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: hasBalance
            ? Text(
                'Rs ${summary.balanceDue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.tetraColor,
                ),
              )
            : const Text(
                'Settled',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  color: AppColors.success,
                ),
              ),
      ),
    );
  }
}
