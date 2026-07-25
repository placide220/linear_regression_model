import 'package:flutter/material.dart';

import '../models/field_defaults.dart';
import '../models/field_sections.dart';
import '../models/field_validator.dart';
import '../models/scenario_presets.dart';
import '../services/prediction_service.dart';
import '../theme/app_theme.dart';
import '../widgets/prediction_field.dart';
import '../widgets/result_banner.dart';
import '../widgets/section_card.dart';

/// Icon shown in each section's panel header.
const Map<String, IconData> kSectionIcons = {
  'Connection type': Icons.lan_outlined,
  'Traffic volume': Icons.speed_outlined,
  'Connection flags': Icons.flag_outlined,
  'Compromise indicators': Icons.warning_amber_outlined,
  'Same-window counts': Icons.timer_outlined,
  'Rate features (0.0 - 1.0)': Icons.percent_outlined,
  'Destination-host rate features (0.0 - 1.0)': Icons.dns_outlined,
};

/// The app's single page: a scrollable form with one TextFormField per
/// model input variable (grouped into labeled panels), a Predict button,
/// and a result display area.
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  ResultState _state = ResultState.idle;
  String _resultMessage = 'Fill in the fields above and press Predict.';
  String? _readoutValue;
  String? _readoutCaption;

  @override
  void initState() {
    super.initState();
    for (final field in kAllFields) {
      _controllers[field.name] =
          TextEditingController(text: kFieldDefaults[field.name] ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetToDefaults() {
    for (final field in kAllFields) {
      _controllers[field.name]!.text = kFieldDefaults[field.name] ?? '';
    }
    setState(() {
      _state = ResultState.idle;
      _resultMessage = 'Fill in the fields above and press Predict.';
      _readoutValue = null;
      _readoutCaption = null;
    });
  }

  /// Applies a [ScenarioPreset]: only overwrites the handful of high-impact
  /// fields it defines, leaving every other field exactly as it is.
  void _applyPreset(ScenarioPreset preset) {
    preset.values.forEach((name, value) {
      _controllers[name]!.text = value;
    });
    setState(() {
      _state = ResultState.idle;
      _resultMessage =
          '"${preset.label}" applied. Press Predict to see the result.';
      _readoutValue = null;
      _readoutCaption = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() {
        _state = ResultState.error;
        _resultMessage =
            'One or more values are missing or out of range. Please fix the highlighted fields.';
        _readoutValue = null;
        _readoutCaption = null;
      });
      return;
    }

    setState(() {
      _state = ResultState.loading;
      _resultMessage = 'Contacting the model...';
      _readoutValue = null;
      _readoutCaption = null;
    });

    final payload = <String, dynamic>{
      for (final spec in kAllFields)
        spec.name: FieldValidator.coerce(spec, _controllers[spec.name]!.text),
    };

    try {
      final result = await PredictionService.predict(payload);
      setState(() {
        _state = ResultState.success;
        _resultMessage = '';
        _readoutValue = result.predictedCount.toStringAsFixed(2);
        _readoutCaption = 'connections in the next 2s window  ·  ${result.modelName}';
      });
    } on PredictionException catch (e) {
      setState(() {
        _state = ResultState.error;
        _resultMessage = e.message;
        _readoutValue = null;
        _readoutCaption = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.accent, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection Count Predictor', style: AppTheme.display(fontSize: 17)),
                Text('NSL-KDD intrusion-detection model',
                    style: AppTheme.body(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'Enter the connection features below to predict the expected '
                'number of connections to the same host in the past two seconds.',
                style: AppTheme.body(fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'marks the fields the model relies on most -- same_srv_rate '
                      'and srv_count alone drive ~90% of every prediction.',
                      style: AppTheme.body(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Fields are pre-filled with valid example values -- edit only '
                      'what you want to test, or press Predict as-is.',
                      style: AppTheme.body(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w400),
                    ),
                  ),
                  TextButton(onPressed: _resetToDefaults, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 14),
              Text('QUICK TEST SCENARIOS',
                  style: AppTheme.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kScenarioPresets
                    .map((preset) => Tooltip(
                          message: preset.description,
                          child: ActionChip(
                            label: Text(preset.label, style: AppTheme.body(fontSize: 12.5, color: AppColors.textPrimary)),
                            backgroundColor: AppColors.surfaceAlt,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () => _applyPreset(preset),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              for (final entry in kSections.entries)
                SectionCard(
                  title: entry.key,
                  icon: kSectionIcons[entry.key] ?? Icons.tune,
                  children: entry.value
                      .map((spec) => PredictionField(
                            spec: spec,
                            controller: _controllers[spec.name]!,
                          ))
                      .toList(),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _state == ResultState.loading ? null : _submit,
                  child: _state == ResultState.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF08222A)),
                        )
                      : const Text('Predict'),
                ),
              ),
              const SizedBox(height: 16),
              ResultBanner(
                state: _state,
                message: _resultMessage,
                readoutValue: _readoutValue,
                readoutCaption: _readoutCaption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
