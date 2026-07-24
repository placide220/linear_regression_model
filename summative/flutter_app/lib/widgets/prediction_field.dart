import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/field_spec.dart';
import '../models/field_validator.dart';

/// Renders a single TextFormField for one [FieldSpec] -- one of these per
/// model input variable.
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
        decoration: InputDecoration(
          labelText: spec.label,
          helperText: spec.hint,
          helperMaxLines: 2,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: spec.kind == FieldKind.integer
            ? [FilteringTextInputFormatter.digitsOnly]
            : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        validator: (raw) => FieldValidator.validate(spec, raw),
      ),
    );
  }
}
