// lib/ui/settings_view/settings_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'settings_view_model.dart';

class SettingsView extends StatelessWidget {
  static const String routeName = '/settings-view';

  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const SettingsView(),
      settings: const RouteSettings(name: routeName),
    );
  }

  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: const _SettingsViewBody(),
    );
  }
}

class _SettingsViewBody extends StatefulWidget {
  const _SettingsViewBody();

  @override
  State<_SettingsViewBody> createState() => _SettingsViewBodyState();
}

class _SettingsViewBodyState extends State<_SettingsViewBody> {
  final _hotelNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _ntnController = TextEditingController();
  final _currencyController = TextEditingController();
  final _footerNoteController = TextEditingController();
  final _taxPercentageController = TextEditingController();

  bool _initializedControllers = false;

  void _syncControllers(SettingsViewModel vm) {
    if (!_initializedControllers && !vm.isLoading) {
      _hotelNameController.text = vm.hotelName;
      _taglineController.text = vm.tagline;
      _phoneController.text = vm.phone;
      _emailController.text = vm.email;
      _addressController.text = vm.address;
      _ntnController.text = vm.ntnOrTaxNumber;
      _currencyController.text = vm.currencySymbol;
      _footerNoteController.text = vm.invoiceFooterNote;
      _taxPercentageController.text = vm.taxPercentage > 0
          ? vm.taxPercentage.toStringAsFixed(1)
          : '';
      _initializedControllers = true;
    }
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _ntnController.dispose();
    _currencyController.dispose();
    _footerNoteController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    _syncControllers(vm);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Hotel Profile')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                // Error & Success Banners
                if (vm.errorMessage != null) ...[
                  _Banner(message: vm.errorMessage!, isError: true),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                ],
                if (vm.successMessage != null) ...[
                  _Banner(message: vm.successMessage!, isError: false),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                ],

                // ─── Business / Hotel Profile ────────────────────────
                const _SectionTitle(title: 'Hotel / Business Profile'),
                const SizedBox(height: AppSizes.sm),
                _LogoCard(
                  logoPath: vm.logoPath,
                  onPick: vm.pickLogo,
                  onRemove: vm.removeLogo,
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: _hotelNameController,
                  decoration: const InputDecoration(
                    labelText: 'Hotel / Business Name *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  onChanged: vm.setHotelName,
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: _taglineController,
                  decoration: const InputDecoration(
                    labelText: 'Tagline / Slogan',
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                  onChanged: vm.setTagline,
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        onChanged: vm.setPhone,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        onChanged: vm.setEmail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Location / Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  onChanged: vm.setAddress,
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: _ntnController,
                  decoration: const InputDecoration(
                    labelText: 'NTN / Tax Registration No.',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  onChanged: vm.setNtnOrTaxNumber,
                ),

                const SizedBox(height: AppSizes.spaceBtwSections),

                // ─── Invoice & Accounting Settings ───────────────────
                const _SectionTitle(title: 'Invoice & Accounting'),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          hintText: 'Rs, \$, AED',
                        ),
                        onChanged: vm.setCurrencySymbol,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _taxPercentageController,
                        enabled: vm.enableTax,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tax Rate (%)',
                          suffixText: '%',
                        ),
                        onChanged: (val) =>
                            vm.setTaxPercentage(double.tryParse(val) ?? 0.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Tax Calculation on Sales'),
                  subtitle: const Text(
                    'Automatically compute tax on invoices & receipts',
                  ),
                  value: vm.enableTax,
                  activeTrackColor: AppColors.primary,
                  onChanged: vm.setEnableTax,
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: _footerNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Footer Note',
                    hintText: 'e.g. Thank you for your business! Visit again.',
                  ),
                  onChanged: vm.setInvoiceFooterNote,
                ),

                const SizedBox(height: AppSizes.spaceBtwSections),

                // ─── Save Button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: vm.isSaving
                        ? null
                        : () async {
                            final success = await vm.saveSettings();
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Settings saved successfully'),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.buttonRadius,
                        ),
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
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceBtwSections),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppSizes.fontSizeLg,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.logoPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? logoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.lightContainer,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: logoPath != null && File(logoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusMd,
                      ),
                      child: Image.file(File(logoPath!), fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.storefront_outlined,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Logo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Used on printed receipts & invoices',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (logoPath != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: onRemove,
              ),
            OutlinedButton(
              onPressed: onPick,
              child: Text(logoPath != null ? 'Change' : 'Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: AppSizes.iconSm,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: AppSizes.fontSizeSm, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
