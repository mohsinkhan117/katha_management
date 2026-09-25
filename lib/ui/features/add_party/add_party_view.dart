import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/ui/features/add_party/add_party_view_model.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/sizes/sizes.dart';
import '../../../../core/theme/app_colors/app_colors.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          vm.isEditing ? AppStrings.editPartyTitle : AppStrings.addPartyTitle,
        ),
        actions: [
          if (vm.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: AppStrings.deletePartyButton,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(AppStrings.deletePartyTitle),
                    content: const Text(AppStrings.deletePartyMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(AppStrings.no),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text(AppStrings.deletePartyButton),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final partyVm = context.read<AddPartyViewModel>();
                  final deleted = await partyVm.deleteParty();
                  if (deleted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.partyDeletedSuccess),
                      ),
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
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          const _SectionLabel(AppStrings.basicInfoSection),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppStrings.partyNameLabel,
              suffixIcon: vm.isCheckingDuplicate
                  ? const Padding(
                      padding: EdgeInsets.all(AppSizes.sm),
                      child: SizedBox(
                        height: AppSizes.iconXs,
                        width: AppSizes.iconXs,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: (value) =>
                context.read<AddPartyViewModel>().setName(value),
          ),
          if (vm.duplicateWarning != null) ...[
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: AppSizes.iconXs,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Text(
                    vm.duplicateWarning!,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: AppStrings.partyPhoneLabel,
            ),
            onChanged: (value) =>
                context.read<AddPartyViewModel>().setPhone(value),
          ),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: AppStrings.partyAddressLabel,
            ),
            onChanged: (value) =>
                context.read<AddPartyViewModel>().setAddress(value),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),
          const _SectionLabel(AppStrings.categorySection),
          const SizedBox(height: AppSizes.sm),
          _TagSelector(selected: vm.tag),
          const SizedBox(height: AppSizes.spaceBtwSections),
          const _SectionLabel(AppStrings.openingBalanceSection),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _openingBalanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: AppStrings.openingBalanceAmountLabel,
              helperText: AppStrings.openingBalanceHelper,
            ),
            onChanged: (value) => context
                .read<AddPartyViewModel>()
                .setOpeningBalance(double.tryParse(value) ?? 0),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: AppStrings.noteOptional,
            ),
            onChanged: (value) =>
                context.read<AddPartyViewModel>().setNote(value),
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSizes.spaceBtwSections),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                ),
              ),
              child: vm.isSaving
                  ? const SizedBox(
                      height: AppSizes.iconMd,
                      width: AppSizes.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textWhite,
                      ),
                    )
                  : Text(
                      vm.isEditing
                          ? AppStrings.updatePartyButton
                          : AppStrings.savePartyButton,
                      style: const TextStyle(color: AppColors.textWhite),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppSizes.fontSizeLg,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
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
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
          onSelected: (wasSelected) => context.read<AddPartyViewModel>().setTag(
            wasSelected ? tag : null,
          ),
        );
      }).toList(),
    );
  }
}
