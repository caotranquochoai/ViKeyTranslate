import 'package:translator/translator.dart';
import 'translation_service.dart';

/// Triển khai cụ thể của [TranslationService] cho Google Translate.
class GoogleTranslationService implements TranslationService {
  final _translator = GoogleTranslator();

  @override
  String get name => 'Google Translate';

  @override
  Future<String> translate({
    required String text,
    String from = 'auto',
    required String to,
  }) async {
    try {
      final translation = await _translator.translate(text, from: from, to: to);
      return translation.text;
    } catch (e) {
      // Ném ra lỗi để lớp gọi có thể xử lý
      throw Exception('Google Translate API error: $e');
    }
  }
}
