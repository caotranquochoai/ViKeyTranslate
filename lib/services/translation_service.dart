/// Định nghĩa một lớp trừu tượng cho các dịch vụ dịch thuật.
/// Mỗi dịch vụ (Google, Gemini, etc.) sẽ kế thừa từ lớp này.
abstract class TranslationService {
  /// Tên của dịch vụ, dùng để hiển thị trên UI.
  String get name;

  /// Phương thức dịch văn bản.
  ///
  /// [text]: Văn bản cần dịch.
  /// [from]: Mã ngôn ngữ nguồn (ví dụ: 'vi').
  /// [to]: Mã ngôn ngữ đích (ví dụ: 'en').
  Future<String> translate({
    required String text,
    String from = 'auto',
    required String to,
  });
}
