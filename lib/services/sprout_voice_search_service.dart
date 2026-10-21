import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceSearchState {
  idle,
  listening,
  recognized,
  permissionDenied,
  failure,
}

class SproutVoiceSearchService extends ChangeNotifier {
  static final SproutVoiceSearchService _instance = SproutVoiceSearchService._internal();
  factory SproutVoiceSearchService() => _instance;
  SproutVoiceSearchService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  VoiceSearchState _state = VoiceSearchState.idle;
  String _lastRecognizedWords = '';
  String? _errorMessage;
  String? _selectedLocaleId;
  List<LocaleName> _availableLocales = [];

  VoiceSearchState get state => _state;
  bool get isListening => _state == VoiceSearchState.listening;
  String get lastRecognizedWords => _lastRecognizedWords;
  String? get errorMessage => _errorMessage;
  String? get selectedLocaleId => _selectedLocaleId;
  List<LocaleName> get availableLocales => _availableLocales;
  bool get isAvailable => _isInitialized || _speechToText.isAvailable;

  /// Initializes speech recognition and resolves English / Hindi preferred locales.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );

      _isInitialized = available;

      if (available) {
        try {
          _availableLocales = await _speechToText.locales();
          _resolvePreferredLocale();
        } catch (e) {
          debugPrint('SproutVoiceSearchService: Could not load locales: $e');
        }
      }

      return available;
    } catch (e) {
      debugPrint('SproutVoiceSearchService init error: $e');
      _isInitialized = false;
      return false;
    }
  }

  void _resolvePreferredLocale() {
    if (_availableLocales.isEmpty) return;

    // Prefer Indian English (en_IN) or Hindi (hi_IN), fallback to en_US
    final enIn = _availableLocales.cast<LocaleName?>().firstWhere(
      (l) => l?.localeId.toLowerCase().contains('en_in') == true ||
          l?.localeId.toLowerCase().contains('en-in') == true,
      orElse: () => null,
    );

    final hiIn = _availableLocales.cast<LocaleName?>().firstWhere(
      (l) => l?.localeId.toLowerCase().contains('hi') == true,
      orElse: () => null,
    );

    final enUs = _availableLocales.cast<LocaleName?>().firstWhere(
      (l) => l?.localeId.toLowerCase().contains('en_us') == true ||
          l?.localeId.toLowerCase().contains('en-us') == true,
      orElse: () => null,
    );

    _selectedLocaleId = enIn?.localeId ?? hiIn?.localeId ?? enUs?.localeId ?? _availableLocales.first.localeId;
  }

  /// Sets preferred language (e.g. Hindi 'hi_IN' or English 'en_IN')
  void setLocale(String localeId) {
    _selectedLocaleId = localeId;
    notifyListeners();
  }

  /// Starts listening for recipe voice search
  Future<void> startListening({
    required ValueChanged<String> onResult,
    VoidCallback? onDone,
  }) async {
    _lastRecognizedWords = '';
    _errorMessage = null;

    final hasInit = await initialize();
    if (!hasInit) {
      _state = VoiceSearchState.permissionDenied;
      _errorMessage = 'Microphone permission denied or speech recognition unavailable.';
      notifyListeners();
      return;
    }

    _state = VoiceSearchState.listening;
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastRecognizedWords = result.recognizedWords;
          onResult(result.recognizedWords);

          if (result.finalResult) {
            _state = VoiceSearchState.recognized;
            notifyListeners();
            onDone?.call();
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          localeId: _selectedLocaleId,
        ),
      );
    } catch (e) {
      debugPrint('SproutVoiceSearchService listen error: $e');
      _state = VoiceSearchState.failure;
      _errorMessage = 'Could not start voice recognition: $e';
      notifyListeners();
    }
  }

  /// Stops listening and commits recognized text
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      if (_state == VoiceSearchState.listening) {
        _state = VoiceSearchState.idle;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Cancels listening and clears speech recognition
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _state = VoiceSearchState.idle;
      _lastRecognizedWords = '';
      _errorMessage = null;
      notifyListeners();
    } catch (_) {}
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('SproutVoiceSearchService error: ${error.errorMsg}');
    if (error.errorMsg.contains('error_permission')) {
      _state = VoiceSearchState.permissionDenied;
      _errorMessage = 'Microphone permission was denied. Please allow microphone access to search by voice.';
    } else if (error.errorMsg.contains('error_no_match') || error.errorMsg.contains('error_speech_timeout')) {
      _state = VoiceSearchState.failure;
      _errorMessage = 'No speech detected. Try speaking again or type your search.';
    } else {
      _state = VoiceSearchState.failure;
      _errorMessage = 'Voice search unavailable: ${error.errorMsg}';
    }
    notifyListeners();
  }

  void _onStatus(String status) {
    debugPrint('SproutVoiceSearchService status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceSearchState.listening) {
        _state = VoiceSearchState.idle;
        notifyListeners();
      }
    }
  }
}
