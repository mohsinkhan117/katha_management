// lib\ui\add_payment\payment_view.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/ui/add_payment/payment_view_model.dart';
import 'package:provider/provider.dart';

class PaymentView extends StatefulWidget {
  static const String routeName = '/payment_view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const PaymentView(),
      settings: RouteSettings(name: routeName),
    );
  }

  const PaymentView({super.key, this.partyId});

  /// When set, the screen shows only this party's payments and new
  /// payments are pre-tagged with it.
  final String? partyId;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().loadPayments(partyId: widget.partyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Consumer<PaymentViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          if (viewModel.payments.isEmpty) {
            return const Center(child: Text('No payments recorded yet.'));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadPayments(partyId: widget.partyId),
            child: ListView.separated(
              itemCount: viewModel.payments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final payment = viewModel.payments[index];
                return Dismissible(
                  key: ValueKey(payment.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed: (_) {
                    viewModel.deletePayment(
                      payment.id,
                      partyId: widget.partyId,
                    );
                  },
                  child: ListTile(
                    title: Text(payment.partyName),
                    subtitle: Text(
                      '${payment.mode.label} • '
                      '${payment.paymentDate.toLocal().toString().split(' ').first}'
                      '${payment.note != null ? '\n${payment.note}' : ''}',
                    ),
                    isThreeLine: payment.note != null,
                    trailing: Text(
                      payment.amount.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddPaymentSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete payment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
      builder: (_) => _AddPaymentSheet(partyId: widget.partyId),
    );

    if (result == null) return;

    await viewModel.addPayment(
      PaymentModel(
        partyId: widget.partyId,
        partyName: result.partyName,
        amount: result.amount,
        mode: result.mode,
        note: result.note,
      ),
    );
  }
}

class _AddPaymentResult {
  _AddPaymentResult({
    required this.partyName,
    required this.amount,
    required this.mode,
    this.note,
  });

  final String partyName;
  final double amount;
  final PaymentMode mode;
  final String? note;
}

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet({this.partyId});

  final String? partyId;

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _partyNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMode _mode = PaymentMode.cash;

  @override
  void dispose() {
    _partyNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partyNameController,
              decoration: const InputDecoration(labelText: 'Party name'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0)
                  return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Mode'),
              items: PaymentMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _mode = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _AddPaymentResult(
        partyName: _partyNameController.text.trim(),
        amount: double.parse(_amountController.text),
        mode: _mode,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }
}
