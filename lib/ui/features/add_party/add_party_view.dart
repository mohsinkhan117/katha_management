// lib/ui/features/add_party/add_party_view.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/core/widgets/glass_card.dart';
import 'package:katha_management/ui/features/add_party/add_party_view_model.dart';
import 'package:provider/provider.dart';

class AddPartyView extends StatelessWidget {
  static const String routeName = '/add-party-view';
  static Route route({PartyModel? partyToEdit}) {
    return MaterialPageRoute(
      builder: (context) => AddPartyView(partyToEdit: partyToEdit),
      settings: RouteSettings(name: routeName, arguments: partyToEdit),
    );
  }

  const AddPartyView({super.key, this.partyToEdit});
  final PartyModel? partyToEdit;

  @override
  Widget build(BuildContext context) {
    final party =
        partyToEdit ??
        (ModalRoute.of(context)?.settings.arguments as PartyModel?);
    return ChangeNotifierProvider(
      create: (_) => AddPartyViewModel(partyToEdit: party),
      child: const _AddPartyViewBody(),
    );
  }
}

class _AddPartyViewBody extends StatefulWidget {
  const _AddPartyViewBody();

  @override
  State<_AddPartyViewBody> createState() => _AddPartyViewBodyState();
}

class _AddPartyViewBodyState extends State<_AddPartyViewBody> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<AddPartyViewModel>();
    if (vm.isEditing) {
      _nameController.text = vm.name;
      _phoneController.text = vm.phone;
      _addressController.text = vm.address;
      if (vm.openingBalance > 0) {
        _openingBalanceController.text = vm.openingBalance.toStringAsFixed(0);
      }
      _noteController.text = vm.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddPartyViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          vm.isEditing ? AppStrings.editPartyTitle : AppStrings.addPartyTitle,
        ),
        actions: [
          if (vm.isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: AppStrings.deletePartyButton,
              onPressed: () async {
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
                  final partyVm = context.read<AddPartyViewModel>();
                  final deleted = await partyVm.deleteParty();
                  if (deleted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.partyDeletedSuccess)),
                    );
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop(true);
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: AmbientScaffoldBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            children: [
              // Basic Information Card (iOS Widget)
              GlassCard(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WidgetSectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: AppStrings.basicInfoSection,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.partyNameLabel,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        suffixIcon: vm.isCheckingDuplicate
                            ? const Padding(
                                padding: EdgeInsets.all(AppSizes.sm),
                                child: SizedBox(
                                  height: AppSizes.iconXs,
                                  width: AppSizes.iconXs,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) =>
                          context.read<AddPartyViewModel>().setName(value),
                    ),
                    if (vm.duplicateWarning != null) ...[
                      const SizedBox(height: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: Text(
                                vm.duplicateWarning!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppStrings.partyPhoneLabel,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      ),
                      onChanged: (value) =>
                          context.read<AddPartyViewModel>().setPhone(value),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: AppStrings.partyAddressLabel,
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                        ),
                      ),
                      onChanged: (value) =>
                          context.read<AddPartyViewModel>().setAddress(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              // Category / Tag Widget
              GlassCard(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WidgetSectionHeader(
                      icon: Icons.label_outline_rounded,
                      title: AppStrings.categorySection,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    _TagSelector(selected: vm.tag),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              // Opening Balance Widget
              GlassCard(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WidgetSectionHeader(
                      icon: Icons.account_balance_wallet_outlined,
                      title: AppStrings.openingBalanceSection,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    TextField(
                      controller: _openingBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: AppStrings.openingBalanceAmountLabel,
                        helperText: AppStrings.openingBalanceHelper,
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          size: 20,
                        ),
                      ),
                      onChanged: (value) => context
                          .read<AddPartyViewModel>()
                          .setOpeningBalance(double.tryParse(value) ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              // Notes Widget (Optional)
              GlassCard(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WidgetSectionHeader(
                      icon: Icons.notes_rounded,
                      title: AppStrings.noteOptional,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppStrings.noteOptional,
                        prefixIcon: const Icon(
                          Icons.edit_note_outlined,
                          size: 22,
                        ),
                      ),
                      onChanged: (value) =>
                          context.read<AddPartyViewModel>().setNote(value),
                    ),
                  ],
                ),
              ),

              // Error Banner (if any)
              if (vm.errorMessage != null) ...[
                const SizedBox(height: AppSizes.spaceBtwItems),
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm + 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.spaceBtwSections),

              // Save / Update Action Button (styled completely via theme)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: vm.isSaving || !vm.canSave
                      ? null
                      : () async {
                          final partyVm = context.read<AddPartyViewModel>();
                          final success = await partyVm.saveParty();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  partyVm.isEditing
                                      ? AppStrings.partyUpdatedSuccess
                                      : AppStrings.partyAddedSuccess,
                                ),
                              ),
                            );
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop(true);
                            }
                          }
                        },
                  child: vm.isSaving
                      ? const SizedBox(
                          height: AppSizes.iconMd,
                          width: AppSizes.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          vm.isEditing
                              ? AppStrings.updatePartyButton
                              : AppStrings.savePartyButton,
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetSectionHeader extends StatelessWidget {
  const _WidgetSectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.accent : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: AppSizes.xs + 4),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({required this.selected});
  final PartyTag? selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: PartyTag.values.map((tag) {
        final isSelected = tag == selected;
        return ChoiceChip(
          label: Text(tag.label),
          selected: isSelected,
          onSelected: (wasSelected) => context.read<AddPartyViewModel>().setTag(
            wasSelected ? tag : null,
          ),
        );
      }).toList(),
    );
  }
}
