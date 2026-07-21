import 'package:flutter/material.dart';

import '../models/field_defaults.dart';
import '../models/field_sections.dart';
import '../models/field_validator.dart';
import '../models/scenario_presets.dart';
import '../services/prediction_service.dart';
import '../widgets/prediction_field.dart';
import '../widgets/result_banner.dart';
import '../widgets/section_card.dart';

/// The app's single page: a scrollable form with one TextFormField per
/// model input variable (grouped into labeled sections), a Predict button,
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
      });
      return;
    }

    setState(() {
      _state = ResultState.loading;
      _resultMessage = 'Contacting the model...';
    });

    final payload = <String, dynamic>{
      for (final spec in kAllFields)
        spec.name: FieldValidator.coerce(spec, _controllers[spec.name]!.text),
    };

    try {
      final result = await PredictionService.predict(payload);
      setState(() {
        _state = ResultState.success;
        _resultMessage =
            'Predicted count: ${result.predictedCount.toStringAsFixed(2)}\n(using ${result.modelName})';
      });
    } on PredictionException catch (e) {
      setState(() {
        _state = ResultState.error;
        _resultMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Count Predictor'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Enter the connection features below to predict the '
                'expected number of connections to the same host in the '
                'past two seconds.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'marks the fields the model relies on most -- '
                      'same_srv_rate and srv_count alone drive ~90% of '
                      'every prediction.',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Fields are pre-filled with valid example values -- '
                      'edit only what you want to test, or press Predict '
                      'as-is.',
                      style: TextStyle(fontSize: 13, color: Colors.black45, fontStyle: FontStyle.italic),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick test scenarios (only changes the starred fields above):',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kScenarioPresets
                    .map((preset) => Tooltip(
                          message: preset.description,
                          child: ActionChip(
                            label: Text(preset.label),
                            onPressed: () => _applyPreset(preset),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              for (final entry in kSections.entries)
                SectionCard(
                  title: entry.key,
                  children: entry.value
                      .map((spec) => PredictionField(
                            spec: spec,
                            controller: _controllers[spec.name]!,
                          ))
                      .toList(),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _state == ResultState.loading ? null : _submit,
                  child: _state == ResultState.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Predict', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              ResultBanner(state: _state, message: _resultMessage),
            ],
          ),
        ),
      ),
    );
  }
}
