abstract class AnalyticsPlatform {
  Future<void> init();

  Future<void> logAppOpen();

  Future<void> logTranslateAction({
    required String serviceName,
    required String sourceLang,
    required String targetLang,
  });
}
