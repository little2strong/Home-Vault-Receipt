import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vault_palette.dart';

/// Label above a field, as in the mockups. A [warning] gives the field the
/// amber "check against the source" treatment.
class _FieldFrame extends StatelessWidget {
  const _FieldFrame({required this.label, required this.child, this.warning});

  final String label;
  final String? warning;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.labelMedium),
          const SizedBox(height: 6),
          child,
          if (warning != null) ...[
            const SizedBox(height: 6),
            Text(
              warning!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.palette.warningInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

InputBorder? _warningBorder(BuildContext context, String? warning) =>
    warning == null
    ? null
    : OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.palette.warningBorder),
      );

class VaultTextField extends StatelessWidget {
  const VaultTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.maxLines = 1,
    this.warning,
    this.suffix,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final int maxLines;
  final String? warning;
  final Widget? suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      label: label,
      warning: warning,
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autofillHints: autofillHints,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix,
          enabledBorder: _warningBorder(context, warning),
        ),
      ),
    );
  }
}

/// A read-only field that opens a picker (date, category, option sheet).
class VaultSelectField extends StatelessWidget {
  const VaultSelectField({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.placeholder = false,
    this.warning,
    this.icon = Icons.expand_more_rounded,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Renders [value] as hint text, e.g. `Choose date`.
  final bool placeholder;
  final String? warning;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _FieldFrame(
      label: label,
      warning: warning,
      child: Semantics(
        button: onTap != null,
        label: '$label, $value',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: onTap == null ? null : Icon(icon, color: p.muted),
              enabledBorder: _warningBorder(context, warning),
            ),
            child: Text(
              value,
              style: context.textStyles.bodyLarge?.copyWith(
                color: placeholder ? p.muted : p.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
