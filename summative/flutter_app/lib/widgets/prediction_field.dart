import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/field_spec.dart';
import '../models/field_validator.dart';
import '../theme/app_theme.dart';

/// Renders a single TextFormField for one [FieldSpec] -- one of these per
/// model input variable. Values are entered in the monospace "data" face
/// to reinforce the console identity; key-driver fields get a small dot
/// indicator instead of a generic star, matching the accent color used
/// throughout rather than an unrelated amber.
class PredictionField extends StatelessWidget {
  final FieldSpec spec;
  final TextEditingController controller;

  const PredictionField({
    super.key,
    required this.spec,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: AppTheme.mono(fontSize: 15),
        decoration: InputDecoration(
          labelText: spec.label,
          helperText: spec.hint,
          helperMaxLines: 2,
          suffixIcon: spec.isKeyDriver
              ? Tooltip(
                  message: 'Key driver -- one of the fields the model relies on most.',
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        keyboardType: spec.kind == FieldKind.categorical
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: spec.kind == FieldKind.integer
            ? [FilteringTextInputFormatter.digitsOnly]
            : spec.kind == FieldKind.decimal
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : null,
        validator: (raw) => FieldValidator.validate(spec, raw),
      ),
    );
  }
}
