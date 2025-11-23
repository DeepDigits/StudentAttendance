import 'package:translator/translator.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();
  String _selectedLanguage = 'en'; // Default to English

  // Language options
  static const Map<String, String> languageOptions = {
    'en': 'English',
    'hi': 'हिन्दी', // Hindi
    'ml': 'മലയാളം', // Malayalam
    'ta': 'தமிழ்', // Tamil
  };

  String get selectedLanguage => _selectedLanguage;
  String get selectedLanguageName =>
      languageOptions[_selectedLanguage] ?? 'English';

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
  }

  Future<String> translateText(String text, {String? targetLang}) async {
    try {
      final target = targetLang ?? _selectedLanguage;

      // Don't translate if target language is English and text appears to be English
      if (target == 'en') {
        return text;
      }

      final translation = await _translator.translate(text, to: target);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  Future<String> detectAndTranslate(String text, {String? targetLang}) async {
    try {
      final target = targetLang ?? _selectedLanguage;

      // First detect the language
      final detection = await _translator.translate(text, to: 'en');
      final detectedLang = detection.sourceLanguage.code;

      // If detected language is same as target, return original
      if (detectedLang == target) {
        return text;
      }

      // Translate to target language
      final translation = await _translator.translate(text, to: target);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}
