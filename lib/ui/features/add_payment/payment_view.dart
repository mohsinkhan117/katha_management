import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/features/add_payment/payment_view_model.dart';
import 'package:provider/provider.dart';

class PaymentView extends StatelessWidget {
  static const String routeName = '/payment_view';
  static Route route({String? partyId}) {
    return MaterialPageRoute(
      builder: (context) => PaymentView(partyId: partyId),
      settings: RouteSettings(name: routeName, arguments: partyId),
    );
  }

  const PaymentView({super.key, this.partyId});

  /// When set, the screen shows only this party's payments and new
  /// payments are pre-tagged with it.
  final String? partyId;

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final effectivePartyId =
        partyId ?? (routeArgs is String ? routeArgs : null);

    return ChangeNotifierProvider(
      create: (_) => PaymentViewModel(),
      child: _PaymentViewBody(partyId: effectivePartyId),
    );
  }
}

class _PaymentViewBody extends StatefulWidget {
  const _PaymentViewBody({this.partyId});
  final String? partyId;

  @override
  State<_PaymentViewBody> createState() => _PaymentViewBodyState();
}

class _PaymentViewBodyState extends State<_PaymentViewBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().loadPayments(partyId: widget.partyId);
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PaymentViewModel>(
          builder: (_, vm, _) {
            if (vm.linkedParty != null) {
              return Text(
                '${AppStrings.paymentsTitle} - ${vm.linkedParty!.name}',
              );
            }
            return Text(AppStrings.paymentsTitle);
          },
        ),
      ),
      body: Consumer<PaymentViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.payments.isEmpty) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (viewModel.payments.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => viewModel.loadPayments(partyId: widget.partyId),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Text(
                        AppStrings.noPaymentsYet,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadPayments(partyId: widget.partyId),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: viewModel.payments.length,
              itemBuilder: (context, index) {
                final payment = viewModel.payments[index];
                return Dismissible(
                  key: ValueKey(payment.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(
                        AppSizes.cardRadiusSm,
                      ),
                    ),
                    child: const Icon(Icons.delete, color: AppColors.textWhite),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed: (_) {
                    viewModel.deletePayment(
                      payment.id,
                      partyId: widget.partyId,
                    );
                  },
                  child: Card(
                    elevation: AppSizes.cardElevation,
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.cardRadiusSm,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.success.withValues(
                          alpha: 0.12,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: AppColors.success,
                          size: AppSizes.iconSm,
                        ),
                      ),
                      title: Text(
                        payment.partyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${payment.mode.label} • ${_formatDate(payment.paymentDate)}'
                        '${payment.note != null && payment.note!.isNotEmpty ? '\n${AppStrings.note}: ${payment.note}' : ''}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      isThreeLine:
                          payment.note != null && payment.note!.isNotEmpty,
                      trailing: Text(
                        'Rs ${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeLg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPaymentSheet(context),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.recordPaymentButton),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deletePaymentTitle),
        content: Text(AppStrings.deletePaymentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPaymentSheet(BuildContext context) async {
    final viewModel = context.read<PaymentViewModel>();
    final result = await showModalBottomSheet<_AddPaymentResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.cardRadiusLg),
        ),
      ),
      builder: (_) => _AddPaymentSheet(
        partyId: widget.partyId,
        linkedParty: viewModel.linkedParty,
        availableParties: viewModel.availableParties,
      ),
    );

    if (result == null) return;

    final success = await viewModel.addPayment(
      PaymentModel(
        partyId: result.partyId,
        partyName: result.partyName,
        partyPhone: result.partyPhone,
        amount: result.amount,
        mode: result.mode,
        note: result.note,
      ),
      currentPartyId: widget.partyId,
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.paymentRecordedSuccess)),
      );
    }
  }
}

class _AddPaymentResult {
  _AddPaymentResult({
    this.partyId,
    required this.partyName,
    this.partyPhone,
    required this.amount,
    required this.mode,
    this.note,
  });

  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final double amount;
  final PaymentMode mode;
  final String? note;
}

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet({
    this.partyId,
    this.linkedParty,
    this.availableParties = const [],
  });

  final String? partyId;
  final PartyModel? linkedParty;
  final List<PartyModel> availableParties;

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _partyNameController = TextEditingController();
  final _partyPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMode _mode = PaymentMode.cash;
  String? _selectedPartyId;
  PartyModel? _selectedParty;

  @override
  void initState() {
    super.initState();
    if (widget.linkedParty != null) {
      _selectedParty = widget.linkedParty;
      _selectedPartyId = widget.linkedParty!.id;
      _partyNameController.text = widget.linkedParty!.name;
      _partyPhoneController.text = widget.linkedParty!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyPhoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.recordPaymentButton,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              if (_selectedParty != null) ...[
                Card(
                  elevation: 0,
                  color: AppColors.success.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success,
                      child: Text(
                        _selectedParty!.name.isNotEmpty
                            ? _selectedParty!.name[0]
                            : '?',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _selectedParty!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(_selectedParty!.phone ?? AppStrings.noPhone),
                    trailing: widget.partyId == null
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: AppSizes.iconSm,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedParty = null;
                                _selectedPartyId = null;
                                _partyNameController.clear();
                                _partyPhoneController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ] else ...[
                if (widget.availableParties.isNotEmpty) ...[
                  DropdownButtonFormField<PartyModel>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.selectCustomer,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: widget.availableParties.map((party) {
                      final phoneText =
                          (party.phone != null &&
                              party.phone!.trim().isNotEmpty)
                          ? ' (${party.phone!.trim()})'
                          : '';
                      return DropdownMenuItem<PartyModel>(
                        value: party,
                        child: Text(
                          '${party.name}$phoneText',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (party) {
                      if (party != null) {
                        setState(() {
                          _selectedParty = party;
                          _selectedPartyId = party.id;
                          _partyNameController.text = party.name;
                          _partyPhoneController.text = party.phone ?? '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
                TextFormField(
                  controller: _partyNameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.partyNameLabel,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppStrings.partyNameRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.sm),
              ],

              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: AppStrings.amountRequiredLabel,
                  prefixText: AppStrings.currencyPrefix,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return AppStrings.enterValidPaymentAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButtonFormField<PaymentMode>(
                isExpanded: true,
                initialValue: _mode,
                decoration: InputDecoration(
                  labelText: AppStrings.paymentModeLabel,
                ),
                items: PaymentMode.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(
                          mode.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _mode = value);
                },
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: AppStrings.noteOptional),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),
              SizedBox(
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.savePaymentButton,
                    style: TextStyle(color: AppColors.textWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _AddPaymentResult(
        partyId: _selectedPartyId,
        partyName: _partyNameController.text.trim(),
        partyPhone: _partyPhoneController.text.trim().isEmpty
            ? null
            : _partyPhoneController.text.trim(),
        amount: double.parse(_amountController.text),
        mode: _mode,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }
}
