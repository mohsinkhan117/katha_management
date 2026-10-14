// lib/core/utils/app_dialogs/app_dialogs.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';

/// App Colors - Define your app's color scheme here

/// Complete Dialog Utility Class
class AppDialogs {
  // Prevent instantiation
  AppDialogs._();

  /// Confirmation Dialog - Returns true/false based on user choice
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor ?? AppColors.primary,
        icon: icon,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Delete Confirmation Dialog - Specialized confirmation for deletions
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    String? message,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmationDialog(
        title: 'Delete $itemName?',
        message: message ?? 'This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmColor: AppColors.error,
        icon: Icons.delete_outline,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Error Dialog - Shows error message
  static Future<void> showError({
    required BuildContext context,
    required String message,
    String title = 'Error',
    String buttonText = 'OK',
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onClose: onClose,
      ),
    );
  }

  /// Success Dialog - Shows success message
  static Future<void> showSuccess({
    required BuildContext context,
    required String message,
    String title = 'Success',
    String buttonText = 'OK',
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onClose: onClose,
      ),
    );
  }

  /// Info Dialog - Shows informational message
  static Future<void> showInfo({
    required BuildContext context,
    required String message,
    String title = 'Information',
    String buttonText = 'OK',
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onClose: onClose,
      ),
    );
  }

  /// Warning Dialog - Shows warning message
  static Future<void> showWarning({
    required BuildContext context,
    required String message,
    String title = 'Warning',
    String buttonText = 'OK',
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      builder: (context) => WarningDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onClose: onClose,
      ),
    );
  }

  /// Loading Dialog - Shows loading indicator
  /// Returns a function to close the dialog
  static void showLoading({
    required BuildContext context,
    String message = 'Loading...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// Close the currently open dialog
  static void closeDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Input Dialog - Get text input from user
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    String? message,
    String? hintText,
    String? initialValue,
    String confirmText = 'Submit',
    String cancelText = 'Cancel',
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        message: message,
        hintText: hintText,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Choice Dialog - Let user choose from multiple options
  static Future<T?> showChoiceDialog<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<DialogChoice<T>> choices,
    bool barrierDismissible = true,
    void Function(T)? onSelect,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ChoiceDialog<T>(
        title: title,
        message: message,
        choices: choices,
        onSelect: onSelect,
      ),
    );
  }

  /// Custom Dialog - For completely custom content
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: (context) => child,
    );
  }
}

// ============================================================================
// Dialog Widgets
// ============================================================================

/// Confirmation Dialog Widget
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor = AppColors.primary,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Error Dialog Widget
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onClose;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onClose?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Success Dialog Widget
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onClose;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onClose?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Info Dialog Widget
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onClose;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onClose?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Warning Dialog Widget
class WarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onClose;

  const WarningDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: AppColors.warning,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onClose?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Loading Dialog Widget
class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

/// Input Dialog Widget
class InputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? hintText;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final TextInputType keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onConfirm;
  final VoidCallback? onCancel;

  const InputDialog({
    super.key,
    required this.title,
    this.message,
    this.hintText,
    this.initialValue,
    this.confirmText = 'Submit',
    this.cancelText = 'Cancel',
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();

    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        setState(() => _errorText = error);
        return;
      }
    }

    final result = value.isEmpty ? null : value;
    Navigator.pop(context, result);

    if (result != null) {
      widget.onConfirm?.call(result);
    }
  }

  void _cancel() {
    Navigator.pop(context);
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: _errorText,
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: Text(widget.cancelText)),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// Choice Dialog Widget
class DialogChoice<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? description;

  const DialogChoice({
    required this.value,
    required this.label,
    this.icon,
    this.description,
  });
}

class ChoiceDialog<T> extends StatelessWidget {
  final String title;
  final String? message;
  final List<DialogChoice<T>> choices;
  final void Function(T)? onSelect;

  const ChoiceDialog({
    super.key,
    required this.title,
    this.message,
    required this.choices,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[Text(message!), const SizedBox(height: 16)],
          ...choices.map((choice) => _buildChoiceItem(context, choice)),
        ],
      ),
    );
  }

  Widget _buildChoiceItem(BuildContext context, DialogChoice<T> choice) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, choice.value);
        onSelect?.call(choice.value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            if (choice.icon != null) ...[
              Icon(choice.icon, color: AppColors.primary),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (choice.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      choice.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
