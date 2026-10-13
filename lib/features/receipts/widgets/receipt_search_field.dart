import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/vault_palette.dart';

class ReceiptSearchField extends StatelessWidget {
  const ReceiptSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.activeFilters,
    required this.onFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int activeFilters;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        prefixIcon: Icon(Icons.search_rounded, color: p.primary),
        suffixIcon: IconButton(
          tooltip: activeFilters == 0
              ? 'Filters'
              : 'Filters, $activeFilters active',
          onPressed: onFilters,
          icon: Badge(
            isLabelVisible: activeFilters > 0,
            backgroundColor: p.primary,
            label: Text('$activeFilters'),
            child: Icon(Icons.tune_rounded, color: p.ink),
          ),
        ),
      ),
    );
  }
}
