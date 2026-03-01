import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'analytics_platform.dart';

class AnalyticsServiceMobileImplementation implements AnalyticsPlatform {
  FirebaseAnalytics? _firebaseAnalytics;

  @override
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseAnalytics = FirebaseAnalytics.instance;
      _firebaseAnalytics?.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  @override
  Future<void> logAppOpen() async {
    if (_firebaseAnalytics != null) {
      await _firebaseAnalytics!.logAppOpen();
    }
  }

  @override
  Future<void> logTranslateAction({
    required String serviceName,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (_firebaseAnalytics != null) {
      await _firebaseAnalytics!.logEvent(
        name: 'translate_action',
        parameters: {
          'service_name': serviceName,
          'source_language': sourceLang,
          'target_language': targetLang,
        },
      );
    }
  }
}
