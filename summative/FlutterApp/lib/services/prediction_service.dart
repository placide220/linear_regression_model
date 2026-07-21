import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Thrown when the API call fails for any reason (validation rejected by
/// the server, network error, timeout, unexpected status code). [message]
/// is already formatted for direct display to the user.
class PredictionException implements Exception {
  final String message;
  PredictionException(this.message);

  @override
  String toString() => message;
}

/// Result of a successful prediction call.
class PredictionResult {
  final double predictedCount;
  final String modelName;

  const PredictionResult({required this.predictedCount, required this.modelName});
}

/// Handles all communication with the FastAPI backend (Task 2). Kept
/// separate from any widget so the networking logic can be reasoned about
/// (and swapped/mocked) independently of the UI.
class PredictionService {
  /// Calls POST /predict with [payload] and returns the parsed result, or
  /// throws a [PredictionException] with a user-facing message on failure.
  static Future<PredictionResult> predict(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$kApiBaseUrl$kPredictPath');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw PredictionException(
          'The request timed out. Check the API URL and your connection.');
    } catch (e) {
      throw PredictionException('Could not reach the server: $e');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final predicted = body['predicted_count'] as num;
      final modelName = body['model_name'] as String? ?? 'model';
      return PredictionResult(
        predictedCount: predicted.toDouble(),
        modelName: modelName,
      );
    }

    if (response.statusCode == 422) {
      throw PredictionException(
          'The server rejected the input:\n${_formatDetail(response.body)}');
    }

    throw PredictionException(
        'Server error (${response.statusCode}). Please try again shortly.');
  }

  static String _formatDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail
            .map((e) => e is Map ? '${e['loc']?.last}: ${e['msg']}' : e.toString())
            .join('\n');
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}
