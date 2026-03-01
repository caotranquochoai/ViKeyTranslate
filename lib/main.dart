import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:keyboard_translator/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'services/gemini_translation_service.dart';
import 'services/google_translation_service.dart';
import 'services/openai_translation_service.dart';
import 'services/translation_service.dart';
import 'services/analytics_service.dart';

// The single entry point for all overlays
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TranslatorOverlay(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService().init();
  AnalyticsService().logAppOpen();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 450),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.hide();
    });

    HotKey _hotKey = HotKey(
      key: LogicalKeyboardKey.keyT,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      },
    );

    HotKey _exitHotKey = HotKey(
      key: LogicalKeyboardKey.keyQ,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      _exitHotKey,
      keyDownHandler: (hotKey) async {
        exit(0);
      },
    );
  }

  final isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TranslatorPage(),
    ),
  );
}

class TranslatorOverlay extends StatefulWidget {
  const TranslatorOverlay({super.key});

  @override
  State<TranslatorOverlay> createState() => _TranslatorOverlayState();
}

class _TranslatorOverlayState extends State<TranslatorOverlay> {
  final TextEditingController _controller = TextEditingController();
  TranslationService? _selectedService;
  bool _isLoadingSettings = true;
  bool _isTranslating = false;
  String _translatedText = '';
  String _errorText = '';
  double _translatorOpacity = 1.0;
  String _sourceLanguage = 'vi';
  String _targetLanguage = 'en';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitService();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
      } else {
        FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndInitService() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedServiceName =
        prefs.getString('selectedServiceName') ?? 'Google Translate';
    final translatorOpacity = prefs.getDouble('translatorOpacity') ?? 1.0;
    final sourceLang = prefs.getString('sourceLanguage') ?? 'vi';
    final targetLang = prefs.getString('targetLanguage') ?? 'en';

    TranslationService service;

    if (selectedServiceName == 'Gemini') {
      final apiKey = prefs.getString('geminiApiKey') ?? '';
      final modelName =
          prefs.getString('geminiModelName') ?? 'gemini-2.0-flash';
      final promptTemplate =
          prefs.getString('geminiPromptTemplate') ??
          'Translate the following text from {from} to {to}: "{text}"';
      service = GeminiTranslationService(
        apiKey: apiKey,
        modelName: modelName,
        promptTemplate: promptTemplate,
      );
    } else if (selectedServiceName == 'OpenAI API') {
      final apiKey = prefs.getString('openAIApiKey') ?? '';
      final baseUrl =
          prefs.getString('openAIBaseUrl') ?? 'https://api.openai.com/v1';
      final modelName = prefs.getString('openAIModelName') ?? 'gpt-4o';
      final promptTemplate =
          prefs.getString('openAIPromptTemplate') ??
          'Translate the following text from {from} to {to}: "{text}"';
      service = OpenAiTranslationService(
        apiKey: apiKey,
        baseUrl: baseUrl,
        modelName: modelName,
        promptTemplate: promptTemplate,
      );
    } else {
      service = GoogleTranslationService();
    }

    if (mounted) {
      setState(() {
        _selectedService = service;
        _translatorOpacity = translatorOpacity;
        _sourceLanguage = sourceLang;
        _targetLanguage = targetLang;
        _isLoadingSettings = false;
      });
    }
  }

  void _translateText() async {
    if (_controller.text.isEmpty || _selectedService == null) return;
    setState(() {
      _isTranslating = true;
      _errorText = '';
      _translatedText = '';
    });
    try {
      final result = await _selectedService!.translate(
        text: _controller.text,
        from: _sourceLanguage,
        to: _targetLanguage,
      );

      AnalyticsService().logTranslateAction(
        serviceName: _selectedService?.name ?? 'Unknown',
        sourceLang: _sourceLanguage,
        targetLang: _targetLanguage,
      );

      setState(() {
        _translatedText = result;
      });
    } catch (e) {
      setState(() {
        _errorText = "Lỗi: $e";
      });
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_translatedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _translatedText));

    Fluttertoast.showToast(
      msg: "Đã sao chép vào clipboard",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _translatorOpacity,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
              ],
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: GestureDetector(
                onTap: () {
                  // Chỉ bỏ focus khi nhấp trúng nền trống của Scaffold
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: _isLoadingSettings
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Yêu cầu Focus lại khi ấn trực tiếp vào TextBox
                                        FocusScope.of(
                                          context,
                                        ).requestFocus(_focusNode);
                                      },
                                      child: TextField(
                                        focusNode: _focusNode,
                                        controller: _controller,
                                        autofocus: false,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Dịch (${_sourceLanguage}->${_targetLanguage}) với ${_selectedService?.name ?? ''}...',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _isTranslating
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.send),
                                          onPressed: _translateText,
                                        ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        FlutterOverlayWindow.closeOverlay(),
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (_translatedText.isNotEmpty ||
                                  _errorText.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8.0),
                                      child: _errorText.isNotEmpty
                                          ? SelectableText(
                                              _errorText,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            )
                                          : SelectableText(_translatedText),
                                    ),
                                  ),
                                ),
                              if (_translatedText.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: _copyToClipboard,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isTranslating = false;
  String _translatedText = '';
  String _errorText = '';

  String _selectedServiceName = 'Google Translate';
  double _translatorOpacity = 1.0;
  double _overlayWidth = 400;
  double _overlayHeight = 200;
  String _sourceLanguage = 'vi';
  String _targetLanguage = 'en';

  String _geminiApiKey = '';
  String _geminiModelName = 'gemini-2.0-flash';
  String _geminiPromptTemplate =
      'Translate the following text from {from} to {to}: "{text}"';
  String _openAIApiKey = '';
  String _openAIBaseUrl = 'https://api.openai.com/v1';
  String _openAIModelName = 'gpt-4o';
  String _openAIPromptTemplate =
      'Translate the following text from {from} to {to}: "{text}"';

  late List<TranslationService> _availableServices;
  late TranslationService _selectedService;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      _requestOverlayPermission();
    }
    _updateServices();
    _selectedService = _availableServices.first;
    _loadSettings();
  }

  Future<void> _requestOverlayPermission() async {
    final bool? status = await FlutterOverlayWindow.isPermissionGranted();
    if (status != true) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  void _updateServices() {
    _availableServices = [
      GoogleTranslationService(),
      GeminiTranslationService(
        apiKey: _geminiApiKey,
        modelName: _geminiModelName,
        promptTemplate: _geminiPromptTemplate,
      ),
      OpenAiTranslationService(
        apiKey: _openAIApiKey,
        baseUrl: _openAIBaseUrl,
        modelName: _openAIModelName,
        promptTemplate: _openAIPromptTemplate,
      ),
    ];
    _selectedService = _availableServices.firstWhere(
      (s) => s.name == _selectedServiceName,
      orElse: () => _availableServices.first,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedServiceName =
          prefs.getString('selectedServiceName') ?? 'Google Translate';
      _translatorOpacity = prefs.getDouble('translatorOpacity') ?? 1.0;
      _overlayWidth =
          prefs.getDouble('overlayWidth') ??
          MediaQuery.of(context).size.width * 0.9;
      _overlayHeight = prefs.getDouble('overlayHeight') ?? 200;
      _sourceLanguage = prefs.getString('sourceLanguage') ?? 'vi';
      _targetLanguage = prefs.getString('targetLanguage') ?? 'en';

      _geminiApiKey = prefs.getString('geminiApiKey') ?? '';
      _geminiModelName =
          prefs.getString('geminiModelName') ?? 'gemini-2.0-flash';
      _geminiPromptTemplate =
          prefs.getString('geminiPromptTemplate') ??
          'Translate the following text from {from} to {to}: "{text}"';

      _openAIApiKey = prefs.getString('openAIApiKey') ?? '';
      _openAIBaseUrl =
          prefs.getString('openAIBaseUrl') ?? 'https://api.openai.com/v1';
      _openAIModelName = prefs.getString('openAIModelName') ?? 'gpt-4o';
      _openAIPromptTemplate =
          prefs.getString('openAIPromptTemplate') ??
          'Translate the following text from {from} to {to}: "{text}"';

      _updateServices();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedServiceName', _selectedServiceName);
    await prefs.setDouble('translatorOpacity', _translatorOpacity);
    await prefs.setDouble('overlayWidth', _overlayWidth);
    await prefs.setDouble('overlayHeight', _overlayHeight);
    await prefs.setString('sourceLanguage', _sourceLanguage);
    await prefs.setString('targetLanguage', _targetLanguage);

    await prefs.setString('geminiApiKey', _geminiApiKey);
    await prefs.setString('geminiModelName', _geminiModelName);
    await prefs.setString('geminiPromptTemplate', _geminiPromptTemplate);

    await prefs.setString('openAIApiKey', _openAIApiKey);
    await prefs.setString('openAIBaseUrl', _openAIBaseUrl);
    await prefs.setString('openAIModelName', _openAIModelName);
    await prefs.setString('openAIPromptTemplate', _openAIPromptTemplate);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          availableServices: _availableServices,
          selectedServiceName: _selectedServiceName,
          translatorOpacity: _translatorOpacity,
          overlayWidth: _overlayWidth,
          overlayHeight: _overlayHeight,
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,

          geminiApiKey: _geminiApiKey,
          geminiModelName: _geminiModelName,
          geminiPromptTemplate: _geminiPromptTemplate,

          openAIApiKey: _openAIApiKey,
          openAIBaseUrl: _openAIBaseUrl,
          openAIModelName: _openAIModelName,
          openAIPromptTemplate: _openAIPromptTemplate,

          onServiceSelected: (serviceName) => setState(() {
            _selectedServiceName = serviceName;
            _updateServicesAndSave();
          }),
          onTranslatorOpacityChanged: (value) => setState(() {
            _translatorOpacity = value;
            _saveSettings();
          }),
          onOverlayWidthChanged: (value) => setState(() {
            _overlayWidth = double.tryParse(value) ?? _overlayWidth;
            _saveSettings();
          }),
          onOverlayHeightChanged: (value) => setState(() {
            _overlayHeight = double.tryParse(value) ?? _overlayHeight;
            _saveSettings();
          }),
          onSourceLanguageChanged: (val) => setState(() {
            _sourceLanguage = val;
            _saveSettings();
          }),
          onTargetLanguageChanged: (val) => setState(() {
            _targetLanguage = val;
            _saveSettings();
          }),

          onGeminiApiKeyChanged: (val) => setState(() {
            _geminiApiKey = val;
            _updateServicesAndSave();
          }),
          onGeminiModelNameChanged: (val) => setState(() {
            _geminiModelName = val;
            _updateServicesAndSave();
          }),
          onGeminiPromptTemplateChanged: (val) => setState(() {
            _geminiPromptTemplate = val;
            _updateServicesAndSave();
          }),

          onOpenAIApiKeyChanged: (val) => setState(() {
            _openAIApiKey = val;
            _updateServicesAndSave();
          }),
          onOpenAIBaseUrlChanged: (val) => setState(() {
            _openAIBaseUrl = val;
            _updateServicesAndSave();
          }),
          onOpenAIModelNameChanged: (val) => setState(() {
            _openAIModelName = val;
            _updateServicesAndSave();
          }),
          onOpenAIPromptTemplateChanged: (val) => setState(() {
            _openAIPromptTemplate = val;
            _updateServicesAndSave();
          }),
        ),
      ),
    );
  }

  void _updateServicesAndSave() {
    _updateServices();
    _saveSettings();
  }

  void _translateText({bool andCopy = false}) async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _isTranslating = true;
      _errorText = '';
      _translatedText = '';
    });
    try {
      final result = await _selectedService.translate(
        text: _controller.text,
        from: _sourceLanguage,
        to: _targetLanguage,
      );

      AnalyticsService().logTranslateAction(
        serviceName: _selectedService.name,
        sourceLang: _sourceLanguage,
        targetLang: _targetLanguage,
      );

      setState(() {
        _translatedText = result;
      });
      if (andCopy) {
        _copyToClipboard(result);
      }
    } catch (e) {
      setState(() {
        _errorText = "Lỗi: $e";
      });
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _copyToClipboard([String? text]) {
    final textToCopy = text ?? _translatedText;
    if (textToCopy.isEmpty) return;
    Clipboard.setData(ClipboardData(text: textToCopy));
    Fluttertoast.showToast(
      msg: "Đã sao chép vào clipboard",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      // Desktop UI
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onSubmitted: (_) => _translateText(andCopy: true),
                      decoration: InputDecoration(
                        hintText:
                            'Dịch (${_sourceLanguage}->${_targetLanguage}) với ${_selectedService.name}...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  _isTranslating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _translateText,
                        ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _openSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => exit(0),
                  ),
                ],
              ),
              const Divider(),
              if (_translatedText.isNotEmpty || _errorText.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      child: _errorText.isNotEmpty
                          ? SelectableText(
                              _errorText,
                              style: const TextStyle(color: Colors.red),
                            )
                          : SelectableText(_translatedText),
                    ),
                  ),
                ),
              if (_translatedText.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyToClipboard,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Mobile UI
      return Scaffold(
        appBar: AppBar(title: const Text("Keyboard Translator"), elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Sử dụng phím tắt (Ctrl+Alt+T) trên desktop."),
              const SizedBox(height: 20),
              if (!kIsWeb && Platform.isAndroid)
                ElevatedButton.icon(
                  icon: const Icon(Icons.translate),
                  label: const Text("Bật cửa sổ dịch"),
                  onPressed: () async {
                    if (await FlutterOverlayWindow.isActive() ?? false) {
                      await FlutterOverlayWindow.closeOverlay();
                    } else {
                      await FlutterOverlayWindow.showOverlay(
                        height: _overlayHeight.toInt(),
                        width: _overlayWidth.toInt(),
                        alignment: OverlayAlignment.center,
                        enableDrag: true,
                        flag: OverlayFlag.defaultFlag,
                      );
                    }
                  },
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Cài đặt"),
                onPressed: _openSettings,
              ),
            ],
          ),
        ),
      );
    }
  }
}
