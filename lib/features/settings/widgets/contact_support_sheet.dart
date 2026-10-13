import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';

/// Drafts a support message. There is no support inbox in this build, so the
/// message is copied for the user to send by email rather than pretending
/// to send it.
class ContactSupportSheet extends StatefulWidget {
  const ContactSupportSheet({super.key});

  @override
  State<ContactSupportSheet> createState() => _ContactSupportSheetState();
}

class _ContactSupportSheetState extends State<ContactSupportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();

  static final _secretPattern = RegExp(
    r'(password|passcode|pin|card number|\b\d{13,19}\b)',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 10) {
      return 'Tell us a little more (at least 10 characters)';
    }
    if (_secretPattern.hasMatch(text)) {
      return 'Remove passwords or card numbers before sending';
    }
    return null;
  }

  Future<void> _copy() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await Clipboard.setData(ClipboardData(text: _message.text.trim()));
    if (!mounted) return;
    Navigator.of(context).pop();
    Toast.show('Message copied. Paste it into an email to the pilot team.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        0,
        AppSizes.pagePadding,
        MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact support', style: context.textStyles.titleLarge),
            const SizedBox(height: AppSizes.md),
            const NoticeBanner(
              text: 'Never include passwords or card numbers.',
              tone: NoticeTone.warning,
            ),
            VaultTextField(
              label: 'What happened?',
              hint: 'Describe the issue and what you expected',
              controller: _message,
              validator: _validate,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
            ),
            VaultButton(label: 'Copy message', onPressed: _copy),
          ],
        ),
      ),
    );
  }
}
