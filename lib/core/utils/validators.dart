import '../constants/app_strings.dart';
import 'money.dart';

abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null;

  static String? email(String? value) =>
      _email.hasMatch(value?.trim() ?? '') ? null : AppStrings.invalidEmail;

  static String? password(String? value) {
    final v = value ?? '';
    final strong =
        v.length >= 8 &&
        v.contains(RegExp('[A-Za-z]')) &&
        v.contains(RegExp('[0-9]'));
    return strong ? null : AppStrings.weakPassword;
  }

  static String? amount(String? value) {
    final minor = Money.parse(value);
    return (minor == null || minor <= 0) ? AppStrings.invalidAmount : null;
  }

  /// Like [amount] but allows the field to be left empty.
  static String? optionalAmount(String? value) =>
      (value == null || value.trim().isEmpty) ? null : amount(value);

  static String? quantity(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    return (n == null || n < 1 || n > 999) ? AppStrings.invalidQuantity : null;
  }
}
