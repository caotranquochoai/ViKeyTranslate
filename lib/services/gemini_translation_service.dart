import 'dart:convert';
import 'package:http/http.dart' as http;
import 'translation_service.dart';

/// Triển khai cụ thể của [TranslationService] cho Gemini API với model và prompt tùy chỉnh.
class GeminiTranslationService implements TranslationService {
  final String apiKey;
  final String modelName;
  final String promptTemplate;

  GeminiTranslationService({
    required this.apiKey,
    this.modelName = 'gemini-2.0-flash', // Model mặc định mới
    // {text}, {from}, {to} sẽ được thay thế
    this.promptTemplate =
        'Translate the following text from {from} to {to}: "{text}"',
  });

  @override
  String get name => 'Gemini';

  @override
  Future<String> translate({
    required String text,
    String from = 'vi',
    required String to,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is missing.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    // Tạo prompt bằng cách thay thế các placeholder
    String prompt = promptTemplate
        .replaceAll('{text}', text)
        .replaceAll('{from}', from)
        .replaceAll('{to}', to);

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText =
            data['candidates'][0]['content']['parts'][0]['text'];
        return translatedText.trim();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Gemini API error (${response.statusCode}): ${errorData['error']['message']}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to Gemini API: $e');
    }
  }
}
