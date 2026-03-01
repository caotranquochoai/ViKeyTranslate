import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'analytics_platform.dart';

class AnalyticsServiceDesktopImplementation implements AnalyticsPlatform {
  final String _measurementId = 'G-E87J33CQMH';
  final String _apiSecret = 'kbcRsjJkTQWV-5nP5Mm3DQ';

  final String _clientId =
      'desktop_client_${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<void> init() async {
    // Không cần cấu hình đặc biệt khởi tạo cho Measurement Protocol
  }

  @override
  Future<void> logAppOpen() async {
    await _logToMeasurementProtocol('app_open', {});
  }

  @override
  Future<void> logTranslateAction({
    required String serviceName,
    required String sourceLang,
    required String targetLang,
  }) async {
    await _logToMeasurementProtocol('translate_action', {
      'service_name': serviceName,
      'source_language': sourceLang,
      'target_language': targetLang,
    });
  }

  Future<void> _logToMeasurementProtocol(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      final url = Uri.parse(
        'https://www.google-analytics.com/mp/collect?measurement_id=$_measurementId&api_secret=$_apiSecret',
      );

      final body = jsonEncode({
        'client_id': _clientId,
        'events': [
          {'name': eventName, 'params': parameters},
        ],
      });

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (e) {
      debugPrint('Error logging analytics to MP: $e');
    }
  }
}
