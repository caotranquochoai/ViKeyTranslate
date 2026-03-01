import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/gemini_translation_service.dart';
import 'services/openai_translation_service.dart';
import 'services/translation_service.dart';

class SettingsPage extends StatefulWidget {
  final List<TranslationService> availableServices;
  final String selectedServiceName;
  final ValueChanged<String> onServiceSelected;

  final double translatorOpacity;
  final ValueChanged<double> onTranslatorOpacityChanged;

  final double overlayWidth;
  final double overlayHeight;
  final ValueChanged<String> onOverlayWidthChanged;
  final ValueChanged<String> onOverlayHeightChanged;

  // Language settings
  final String sourceLanguage;
  final String targetLanguage;
  final ValueChanged<String> onSourceLanguageChanged;
  final ValueChanged<String> onTargetLanguageChanged;

  final String geminiApiKey;
  final String geminiModelName;
  final String geminiPromptTemplate;
  final ValueChanged<String> onGeminiApiKeyChanged;
  final ValueChanged<String> onGeminiModelNameChanged;
  final ValueChanged<String> onGeminiPromptTemplateChanged;

  final String openAIApiKey;
  final String openAIBaseUrl;
  final String openAIModelName;
  final String openAIPromptTemplate;
  final ValueChanged<String> onOpenAIApiKeyChanged;
  final ValueChanged<String> onOpenAIBaseUrlChanged;
  final ValueChanged<String> onOpenAIModelNameChanged;
  final ValueChanged<String> onOpenAIPromptTemplateChanged;

  const SettingsPage({
    super.key,
    required this.availableServices,
    required this.selectedServiceName,
    required this.onServiceSelected,
    required this.translatorOpacity,
    required this.onTranslatorOpacityChanged,
    required this.overlayWidth,
    required this.overlayHeight,
    required this.onOverlayWidthChanged,
    required this.onOverlayHeightChanged,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onSourceLanguageChanged,
    required this.onTargetLanguageChanged,
    required this.geminiApiKey,
    required this.geminiModelName,
    required this.geminiPromptTemplate,
    required this.onGeminiApiKeyChanged,
    required this.onGeminiModelNameChanged,
    required this.onGeminiPromptTemplateChanged,
    required this.openAIApiKey,
    required this.openAIBaseUrl,
    required this.openAIModelName,
    required this.openAIPromptTemplate,
    required this.onOpenAIApiKeyChanged,
    required this.onOpenAIBaseUrlChanged,
    required this.onOpenAIModelNameChanged,
    required this.onOpenAIPromptTemplateChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentServiceName;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _sourceLangController;
  late TextEditingController _targetLangController;

  late TextEditingController _apiKeyController;
  late TextEditingController _modelNameController;
  late TextEditingController _promptTemplateController;

  late TextEditingController _openAIApiKeyController;
  late TextEditingController _openAIBaseUrlController;
  late TextEditingController _openAIModelController;
  late TextEditingController _openAIPromptController;

  @override
  void initState() {
    super.initState();
    _currentServiceName = widget.selectedServiceName;
    _widthController = TextEditingController(
      text: widget.overlayWidth.toInt().toString(),
    );
    _heightController = TextEditingController(
      text: widget.overlayHeight.toInt().toString(),
    );
    _sourceLangController = TextEditingController(text: widget.sourceLanguage);
    _targetLangController = TextEditingController(text: widget.targetLanguage);

    _apiKeyController = TextEditingController(text: widget.geminiApiKey);
    _modelNameController = TextEditingController(text: widget.geminiModelName);
    _promptTemplateController = TextEditingController(
      text: widget.geminiPromptTemplate,
    );

    _openAIApiKeyController = TextEditingController(text: widget.openAIApiKey);
    _openAIBaseUrlController = TextEditingController(
      text: widget.openAIBaseUrl,
    );
    _openAIModelController = TextEditingController(
      text: widget.openAIModelName,
    );
    _openAIPromptController = TextEditingController(
      text: widget.openAIPromptTemplate,
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _sourceLangController.dispose();
    _targetLangController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _promptTemplateController.dispose();
    _openAIApiKeyController.dispose();
    _openAIBaseUrlController.dispose();
    _openAIModelController.dispose();
    _openAIPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionTitle('Giao diện'),
          _buildSizeInput(),
          _buildOpacitySlider(
            label: 'Độ trong suốt cửa sổ dịch',
            value: widget.translatorOpacity,
            onChanged: widget.onTranslatorOpacityChanged,
          ),
          const Divider(),
          _buildSectionTitle('Ngôn ngữ'),
          _buildLanguageInput(),

          const Divider(),
          _buildSectionTitle('Dịch vụ'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.availableServices.length,
            itemBuilder: (context, index) {
              final service = widget.availableServices[index];
              final bool isGemini = service is GeminiTranslationService;
              final bool isGeminiSelected = _currentServiceName == 'Gemini';
              final bool isOpenAI = service is OpenAiTranslationService;
              final bool isOpenAISelected = _currentServiceName == 'OpenAI API';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(service.name),
                    value: service.name,
                    groupValue: _currentServiceName,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _currentServiceName = value);
                        widget.onServiceSelected(value);
                      }
                    },
                  ),
                  if (isGemini)
                    _buildAnimatedSection(
                      isSelected: isGeminiSelected,
                      children: [
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                          ),
                          onChanged: widget.onGeminiApiKeyChanged,
                        ),
                        TextField(
                          controller: _modelNameController,
                          decoration: const InputDecoration(
                            labelText: 'Model Name',
                          ),
                          onChanged: widget.onGeminiModelNameChanged,
                        ),
                        TextField(
                          controller: _promptTemplateController,
                          decoration: const InputDecoration(
                            labelText: 'Prompt Template',
                            hintText: 'Dùng {text}, {from}, {to}',
                          ),
                          onChanged: widget.onGeminiPromptTemplateChanged,
                        ),
                      ],
                    ),
                  if (isOpenAI)
                    _buildAnimatedSection(
                      isSelected: isOpenAISelected,
                      children: [
                        TextField(
                          controller: _openAIApiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                          ),
                          onChanged: widget.onOpenAIApiKeyChanged,
                        ),
                        TextField(
                          controller: _openAIBaseUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Base URL',
                            hintText: 'e.g., https://api.openai.com/v1',
                          ),
                          onChanged: widget.onOpenAIBaseUrlChanged,
                        ),
                        TextField(
                          controller: _openAIModelController,
                          decoration: const InputDecoration(
                            labelText: 'Model Name',
                          ),
                          onChanged: widget.onOpenAIModelNameChanged,
                        ),
                        TextField(
                          controller: _openAIPromptController,
                          decoration: const InputDecoration(
                            labelText: 'Prompt Template',
                            hintText: 'Dùng {text}, {from}, {to}',
                          ),
                          onChanged: widget.onOpenAIPromptTemplateChanged,
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const Divider(),
          _buildSectionTitle('Thông tin ứng dụng'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('Phát triển bởi Vivucloud - Phiên bản 1.0'),
            subtitle: const Text('Nhấn để liên hệ qua Facebook'),
            onTap: () async {
              final Uri url = Uri.parse('https://www.facebook.com/VivuCloud');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch \$url');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSizeInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _widthController,
              decoration: const InputDecoration(labelText: 'Chiều rộng'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: widget.onOverlayWidthChanged,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: 'Chiều cao'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: widget.onOverlayHeightChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _sourceLangController,
              decoration: const InputDecoration(
                labelText: 'Nguồn (ví dụ: vi, auto)',
              ),
              onChanged: widget.onSourceLanguageChanged,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _targetLangController,
              decoration: const InputDecoration(
                labelText: 'Đích (ví dụ: en, zh)',
              ),
              onChanged: widget.onTargetLanguageChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildOpacitySlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${(value * 100).toInt()}%'),
          Slider(
            value: value,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(value * 100).toInt()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({
    required bool isSelected,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSelected ? (children.length * 68.0) : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: child,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
