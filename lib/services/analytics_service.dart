import 'dart:io';
import 'package:flutter/foundation.dart';
import 'analytics/analytics_platform.dart';
import 'analytics/analytics_mobile.dart';
import 'analytics/analytics_desktop.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  late final AnalyticsPlatform _platform;

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _platform = AnalyticsServiceDesktopImplementation();
    } else {
      _platform = AnalyticsServiceMobileImplementation();
    }
  }

  Future<void> init() => _platform.init();

  Future<void> logAppOpen() => _platform.logAppOpen();

  Future<void> logTranslateAction({
    required String serviceName,
    required String sourceLang,
    required String targetLang,
  }) => _platform.logTranslateAction(
    serviceName: serviceName,
    sourceLang: sourceLang,
    targetLang: targetLang,
  );
}
