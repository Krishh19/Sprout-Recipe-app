import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceCookingCommand {
  next,
  previous,
  read,
  timer,
  stop,
  question,
  unknown,
}

enum CookingVoiceState {
  idle,
  listening,
  processing,
  speaking,
}

class VoiceCookingService {
  static final VoiceCookingService _instance = VoiceCookingService._internal();
  factory VoiceCookingService() => _instance;
  VoiceCookingService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _shouldKeepListening = false;
  bool _isNarrating = false;
  bool _isSpeakingTTS = false;
  CookingVoiceState _voiceState = CookingVoiceState.idle;

  String? _currentNarratedInstruction;
  String _lastRecognizedWords = '';
  DateTime _lastCommandTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isNarrating => _isNarrating;
  bool get isSpeakingTTS => _isSpeakingTTS;
  CookingVoiceState get voiceState => _voiceState;
  String? get currentNarratedInstruction => _currentNarratedInstruction;
  String get lastWords => _lastRecognizedWords;

  void Function(VoiceCookingCommand command, String spokenText)? _currentCommandHandler;
  VoidCallback? _currentListeningChangedHandler;
  void Function(String partialText)? onPartialTranscript;
  VoidCallback? onBargeIn;

  /// Sets whether the app is currently reading aloud a recipe step or answer.
  void setNarrating(bool narrating, {String? narratedInstruction}) {
    _isNarrating = narrating;
    _currentNarratedInstruction = narrating ? narratedInstruction : null;
  }

  void setSpeakingTTS(bool speaking) {
    _isSpeakingTTS = speaking;
    if (speaking) {
      _voiceState = CookingVoiceState.speaking;
      _isNarrating = true;
    } else {
      _isNarrating = false;
      if (_voiceState == CookingVoiceState.speaking) {
        _voiceState = CookingVoiceState.idle;
      }
    }
  }

  void setVoiceState(CookingVoiceState state) {
    _voiceState = state;
    _currentListeningChangedHandler?.call();
  }

  /// Initializes the speech recognition engine safely.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (val) {
          debugPrint('SpeechToText error: ${val.errorMsg}');
          _onEngineStopped();
        },
        onStatus: (status) {
          debugPrint('SpeechToText status: $status');
          if (status == 'notListening' || status == 'done') {
            _onEngineStopped();
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('VoiceCookingService initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  void _onEngineStopped() {
    _isListening = false;
    if (_voiceState == CookingVoiceState.listening) {
      _voiceState = CookingVoiceState.idle;
    }
    _currentListeningChangedHandler?.call();

    // Guard auto-restart loop:
    // If TTS is currently speaking, or query is processing, or hands-free is inactive, NEVER restart!
    if (!_shouldKeepListening ||
        _isSpeakingTTS ||
        _voiceState == CookingVoiceState.speaking ||
        _voiceState == CookingVoiceState.processing) {
      return;
    }

    // Auto-restart listening if hands-free mode is active
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_shouldKeepListening &&
          !_isSpeakingTTS &&
          _voiceState != CookingVoiceState.speaking &&
          _voiceState != CookingVoiceState.processing &&
          !_speechToText.isListening) {
        _restartListeningSession();
      }
    });
  }

  Future<void> _restartListeningSession() async {
    if (!_shouldKeepListening ||
        _isSpeakingTTS ||
        _voiceState == CookingVoiceState.speaking ||
        _voiceState == CookingVoiceState.processing) {
      return;
    }

    try {
      _isListening = true;
      _voiceState = CookingVoiceState.listening;
      _currentListeningChangedHandler?.call();

      await _speechToText.listen(
        onResult: _handleSpeechResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('VoiceCookingService restart error: $e');
      _isListening = false;
      _voiceState = CookingVoiceState.idle;
      _currentListeningChangedHandler?.call();
    }
  }

  /// Parses voice command text into recognized enum actions.
  /// Made static and pure for complete unit testability.
  static VoiceCookingCommand parseCommand(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return VoiceCookingCommand.unknown;

    // Check for pause/stop triggers (evaluated first so 'stop timer' stops)
    if (lower == 'stop' ||
        lower == 'pause' ||
        lower.contains('stop timer') ||
        lower.contains('pause timer') ||
        lower.contains('cancel timer') ||
        lower.contains('quiet') ||
        lower.contains('silence') ||
        lower.contains('shut up') ||
        lower == 'cancel') {
      return VoiceCookingCommand.stop;
    }

    // Check for next step triggers
    if (lower == 'next' ||
        lower.contains('next step') ||
        lower.contains('go next') ||
        lower.contains('move next') ||
        lower.contains('move forward') ||
        lower.contains('step forward') ||
        lower.contains('forward') ||
        lower.contains('continue') ||
        lower.contains('ahead') ||
        lower.contains('skip step') ||
        lower.contains('step done') ||
        lower == 'done') {
      return VoiceCookingCommand.next;
    }

    // Check for previous step triggers
    if (lower == 'back' ||
        lower.contains('go back') ||
        lower.contains('previous') ||
        lower.contains('step back') ||
        lower.contains('last step') ||
        lower.contains('return')) {
      return VoiceCookingCommand.previous;
    }

    // Check for read/repeat triggers
    if (lower == 'read' ||
        lower.contains('read step') ||
        lower.contains('read this') ||
        lower.contains('read aloud') ||
        lower.contains('speak aloud') ||
        lower.contains('speak') ||
        lower.contains('repeat instructions') ||
        lower.contains('repeat step') ||
        lower.contains('repeat') ||
        lower.contains('say again') ||
        lower.contains('tell me') ||
        lower.contains('what now')) {
      return VoiceCookingCommand.read;
    }

    // Check for timer triggers
    if (lower == 'timer' ||
        lower.contains('start timer') ||
        lower.contains('set timer') ||
        lower.contains('begin timer') ||
        lower.contains('countdown') ||
        lower.contains('begin countdown') ||
        lower.contains('cooking timer')) {
      return VoiceCookingCommand.timer;
    }

    // Check for culinary question triggers
    final isQuestion = lower.contains('?') ||
        lower.startsWith('how') ||
        lower.startsWith('what') ||
        lower.startsWith('why') ||
        lower.startsWith('where') ||
        lower.startsWith('when') ||
        lower.startsWith('who') ||
        lower.startsWith('which') ||
        lower.startsWith('can i') ||
        lower.startsWith('could i') ||
        lower.startsWith('should i') ||
        lower.startsWith('would i') ||
        lower.startsWith('is it') ||
        lower.startsWith('are there') ||
        lower.startsWith('do i') ||
        lower.startsWith('does it') ||
        lower.contains('substitute') ||
        lower.contains('instead of') ||
        lower.contains('how much') ||
        lower.contains('how many') ||
        lower.contains('how long') ||
        lower.contains('how hot') ||
        lower.contains('explain') ||
        lower.contains('chef sprout') ||
        lower.contains('can you') ||
        lower.contains('could you');

    if (isQuestion) {
      return VoiceCookingCommand.question;
    }

    return VoiceCookingCommand.unknown;
  }

  /// Determines whether speech detected during audio playback is acoustic bleed/echo
  /// from the speaker reading out the recipe instruction.
  static bool isInstructionEcho(String spokenWords, String? narratedText) {
    if (narratedText == null || narratedText.trim().isEmpty) return false;
    final cleanSpoken = spokenWords.toLowerCase().trim();
    if (cleanSpoken.isEmpty) return false;

    final cmd = parseCommand(cleanSpoken);
    // Explicit stops, pauses, timer triggers or user culinary questions are NEVER echo
    if (cmd == VoiceCookingCommand.stop ||
        cmd == VoiceCookingCommand.timer ||
        cmd == VoiceCookingCommand.question) {
      return false;
    }

    final cleanInstr = narratedText.toLowerCase().trim();
    // If the instruction itself starts with words like "next" and the speaker reads it
    if (cleanInstr.startsWith(cleanSpoken)) {
      return true;
    }

    // If the spoken text is a multi-word phrase found verbatim in the instruction
    if (cleanSpoken.split(' ').length >= 2 && cleanInstr.contains(cleanSpoken)) {
      return true;
    }

    return false;
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    _lastRecognizedWords = result.recognizedWords;
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;

    // Stream live partial transcript to UI
    onPartialTranscript?.call(words);

    // If TTS is speaking, guard against feedback and allow instant stop
    if (_isSpeakingTTS || _voiceState == CookingVoiceState.speaking) {
      final stopCmd = parseCommand(words);
      if (stopCmd == VoiceCookingCommand.stop) {
        onBargeIn?.call();
      }
      return;
    }

    final cmd = parseCommand(words);

    // 1. Navigation & Action Commands: Trigger promptly with debounce protection
    if (cmd == VoiceCookingCommand.next ||
        cmd == VoiceCookingCommand.previous ||
        cmd == VoiceCookingCommand.read ||
        cmd == VoiceCookingCommand.timer ||
        cmd == VoiceCookingCommand.stop) {
      final now = DateTime.now();
      if (now.difference(_lastCommandTime).inMilliseconds > 1000) {
        _lastCommandTime = now;
        _currentCommandHandler?.call(cmd, words);
        _lastRecognizedWords = '';
      }
      return;
    }

    // 2. Conversational Culinary Question ("Can I replace oil with butter?"):
    // Route any non-command phrase that has finished or contains question/query cues
    final isExplicitQuestion = cmd == VoiceCookingCommand.question;
    final hasMultipleWords = words.split(' ').length >= 2;

    if (result.finalResult || isExplicitQuestion || (hasMultipleWords && !words.endsWith(' '))) {
      final now = DateTime.now();
      if (now.difference(_lastCommandTime).inMilliseconds > 1200) {
        _lastCommandTime = now;
        _voiceState = CookingVoiceState.processing;
        _currentListeningChangedHandler?.call();
        _currentCommandHandler?.call(VoiceCookingCommand.question, words);
        _lastRecognizedWords = '';
      }
    }
  }

  /// Starts listening for voice commands and culinary questions in continuous hands-free mode.
  Future<void> startListening({
    required void Function(VoiceCookingCommand command, String spokenText) onCommand,
    VoidCallback? onListeningChanged,
    void Function(String partialText)? onPartialTranscript,
  }) async {
    _currentCommandHandler = onCommand;
    _currentListeningChangedHandler = onListeningChanged;
    this.onPartialTranscript = onPartialTranscript;
    _shouldKeepListening = true;

    // Mutual exclusion: Never start listening while TTS is speaking or processing
    if (_isSpeakingTTS ||
        _voiceState == CookingVoiceState.speaking ||
        _voiceState == CookingVoiceState.processing) {
      return;
    }

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_speechToText.isListening) return;

    try {
      _isListening = true;
      _voiceState = CookingVoiceState.listening;
      onListeningChanged?.call();

      await _speechToText.listen(
        onResult: _handleSpeechResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('VoiceCookingService startListening error: $e');
      _isListening = false;
      _voiceState = CookingVoiceState.idle;
      onListeningChanged?.call();
    }
  }

  /// Stops speech recognition immediately before TTS begins.
  Future<void> stopMicForTts() async {
    _isSpeakingTTS = true;
    _voiceState = CookingVoiceState.speaking;
    _isNarrating = true;
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
    _isListening = false;
    _currentListeningChangedHandler?.call();
  }

  /// Cleanly completes TTS and resumes hands-free listening after a 250ms release period.
  Future<void> onTtsFinished({required bool resumeIfHandsFree}) async {
    _isSpeakingTTS = false;
    _isNarrating = false;

    if (resumeIfHandsFree && _shouldKeepListening) {
      // Release OS audio output focus cleanly for 250ms
      await Future.delayed(const Duration(milliseconds: 250));
      if (_shouldKeepListening && !_isSpeakingTTS && _voiceState != CookingVoiceState.processing) {
        _voiceState = CookingVoiceState.listening;
        await _restartListeningSession();
      }
    } else {
      if (_voiceState == CookingVoiceState.speaking) {
        _voiceState = CookingVoiceState.idle;
      }
      _currentListeningChangedHandler?.call();
    }
  }

  /// User interruption (barge-in): immediately cancels TTS, waits 150ms, then begins listening.
  Future<void> interruptTtsAndStartListening({
    required Future<void> Function() stopTtsCallback,
    required void Function(VoiceCookingCommand command, String spokenText) onCommand,
    VoidCallback? onListeningChanged,
    void Function(String partialText)? onPartialTranscript,
  }) async {
    await stopTtsCallback();
    _isSpeakingTTS = false;
    _isNarrating = false;
    _voiceState = CookingVoiceState.idle;

    // Wait 150ms for audio focus handover
    await Future.delayed(const Duration(milliseconds: 150));
    await startListening(
      onCommand: onCommand,
      onListeningChanged: onListeningChanged,
      onPartialTranscript: onPartialTranscript,
    );
  }

  /// Temporarily pauses microphone input.
  Future<void> pauseListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
    _isListening = false;
    _currentListeningChangedHandler?.call();
  }

  /// Resumes hands-free listening.
  Future<void> resumeListening() async {
    if (_shouldKeepListening &&
        !_speechToText.isListening &&
        !_isSpeakingTTS &&
        _voiceState != CookingVoiceState.speaking &&
        _voiceState != CookingVoiceState.processing) {
      await _restartListeningSession();
    }
  }

  /// Stops speech listening completely and turns off hands-free mode.
  Future<void> stopListening({VoidCallback? onListeningChanged}) async {
    _shouldKeepListening = false;
    _voiceState = CookingVoiceState.idle;
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}
    _isListening = false;
    onListeningChanged?.call();
    _currentListeningChangedHandler?.call();
    _currentCommandHandler = null;
    _currentListeningChangedHandler = null;
    onPartialTranscript = null;
    onBargeIn = null;
  }
}
