// lib/core/utils/app_dialogs/collect_payment_sheet.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';

/// Shows an interactive bottom sheet for quick payment collection against
/// a Party, a specific Sale, or an Order.
Future<bool?> showCollectPaymentSheet(
  BuildContext context, {
  String? partyId,
  required String partyName,
  String? partyPhone,
  double? suggestedAmount,
  String? saleId,
  String? orderId,
  String? initialNote,
  PaymentRepository? paymentRepository,
  OrderRepository? orderRepository,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.cardRadiusLg),
      ),
    ),
    builder: (ctx) => _CollectPaymentSheet(
      partyId: partyId,
      partyName: partyName,
      partyPhone: partyPhone,
      suggestedAmount: suggestedAmount,
      saleId: saleId,
      orderId: orderId,
      initialNote: initialNote,
      paymentRepository: paymentRepository ?? SqflitePaymentRepository(),
      orderRepository: orderRepository ?? SqfliteOrderRepository(),
    ),
  );
}

class _CollectPaymentSheet extends StatefulWidget {
  const _CollectPaymentSheet({
    this.partyId,
    required this.partyName,
    this.partyPhone,
    this.suggestedAmount,
    this.saleId,
    this.orderId,
    this.initialNote,
    required this.paymentRepository,
    required this.orderRepository,
  });

  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final double? suggestedAmount;
  final String? saleId;
  final String? orderId;
  final String? initialNote;
  final PaymentRepository paymentRepository;
  final OrderRepository orderRepository;

  @override
  State<_CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends State<_CollectPaymentSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  PaymentMode _selectedMode = PaymentMode.cash;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialAmount =
        widget.suggestedAmount != null && widget.suggestedAmount! > 0
        ? widget.suggestedAmount!.toStringAsFixed(0)
        : '';
    _amountController = TextEditingController(text: initialAmount);

    String defaultNote = widget.initialNote ?? '';
    if (defaultNote.isEmpty) {
      if (widget.saleId != null) {
        defaultNote =
            'Payment for Sale #${widget.saleId!.substring(0, 6).toUpperCase()}';
      } else if (widget.orderId != null) {
        defaultNote =
            'Advance for Order #${widget.orderId!.substring(0, 6).toUpperCase()}';
      }
    }
    _noteController = TextEditingController(text: defaultNote);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = AppStrings.enterValidPaymentAmount);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payment = PaymentModel(
        partyId: widget.partyId,
        partyName: widget.partyName.trim(),
        partyPhone: widget.partyPhone?.trim().isNotEmpty == true
            ? widget.partyPhone!.trim()
            : null,
        amount: amount,
        mode: _selectedMode,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      final allocations = <PaymentAllocationModel>[];
      if (widget.saleId != null) {
        allocations.add(
          PaymentAllocationModel(
            paymentId: payment.id,
            saleId: widget.saleId!,
            amountApplied:
                widget.suggestedAmount != null &&
                    amount > widget.suggestedAmount!
                ? widget.suggestedAmount!
                : amount,
          ),
        );
      }

      await widget.paymentRepository.insertPayment(
        payment,
        allocations: allocations,
      );

      // If collected against an order, sync the order's advancePaid and status in SQLite
      if (widget.orderId != null) {
        final order = await widget.orderRepository.getOrderById(
          widget.orderId!,
        );
        if (order != null) {
          final newAdvance = order.advancePaid + amount;
          final isFullyPaid =
              newAdvance >= order.totalAmount && order.totalAmount > 0;
          final updatedOrder = order.copyWith(
            advancePaid: newAdvance,
            status: isFullyPaid ? OrderStatus.paid : order.status,
          );
          await widget.orderRepository.updateOrder(updatedOrder);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to record payment: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxSuggested = widget.suggestedAmount ?? 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.lg,
        bottom: AppSizes.lg + keyboardPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.collectPayment,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.partyName}${widget.partyPhone != null ? ' (${widget.partyPhone})' : ''}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            const Divider(),
            const SizedBox(height: AppSizes.sm),

            // Quick Amount Presets
            if (maxSuggested > 0) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                      label: Text(
                        '${AppStrings.quickFullPaid} (${AppStrings.currencyPrefix}${maxSuggested.toStringAsFixed(0)})',
                      ),
                      onPressed: () {
                        _amountController.text = maxSuggested.toStringAsFixed(
                          0,
                        );
                      },
                    ),
                    const SizedBox(width: AppSizes.xs),
                    ActionChip(
                      avatar: const Icon(
                        Icons.pie_chart_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        '${AppStrings.quickHalfPaid} (${AppStrings.currencyPrefix}${(maxSuggested / 2).toStringAsFixed(0)})',
                      ),
                      onPressed: () {
                        final half = (maxSuggested / 2).roundToDouble();
                        _amountController.text = half.toStringAsFixed(0);
                      },
                    ),
                    const SizedBox(width: AppSizes.xs),
                    ActionChip(
                      avatar: const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      label: const Text(AppStrings.quickToken500),
                      onPressed: () {
                        _amountController.text = '500';
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],

            // Amount Field
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: AppStrings.amountToCollect,
                prefixText: AppStrings.currencyPrefix,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Payment Mode Selector
            const Text(
              AppStrings.paymentModeLabel,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PaymentMode.values.map((mode) {
                  final isSelected = _selectedMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.xs),
                    child: ChoiceChip(
                      label: Text(mode.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                      onSelected: (_) => setState(() => _selectedMode = mode),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Note Field
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.noteOptional,
                border: OutlineInputBorder(),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: AppSizes.iconMd,
                        width: AppSizes.iconMd,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite,
                        ),
                      )
                    : const Text(
                        AppStrings.savePaymentButton,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
