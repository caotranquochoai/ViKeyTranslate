import 'dart:convert';
import 'package:http/http.dart' as http;
import 'translation_service.dart';

/// Triển khai cho các API tương thích với chuẩn OpenAI.
class OpenAiTranslationService implements TranslationService {
  final String apiKey;
  final String baseUrl;
  final String modelName;
  final String promptTemplate;

  OpenAiTranslationService({
    required this.apiKey,
    required this.baseUrl,
    required this.modelName,
    this.promptTemplate =
        'Translate the following text from {from} to {to}: "{text}"',
  });

  @override
  String get name => 'OpenAI API';

  @override
  Future<String> translate({
    required String text,
    String from = 'vi',
    required String to,
  }) async {
    if (apiKey.isEmpty || baseUrl.isEmpty || modelName.isEmpty) {
      throw Exception(
        'OpenAI API settings (Base URL, API Key, Model) are missing.',
      );
    }

    final url = Uri.parse('$baseUrl/chat/completions');

    // Tạo prompt
    String prompt = promptTemplate
        .replaceAll('{text}', text)
        .replaceAll('{from}', from)
        .replaceAll('{to}', to);

    final body = jsonEncode({
      'model': modelName,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful translation assistant.',
        },
        {'role': 'user', 'content': prompt},
      ],
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // OpenAI response structure: choices[0].message.content
        final translatedText = data['choices'][0]['message']['content'];
        return translatedText.trim();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'OpenAI API error (${response.statusCode}): ${errorData['error']['message']}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to OpenAI-compatible API: $e');
    }
  }
}
