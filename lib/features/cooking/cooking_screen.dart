import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../design/colors.dart';
import '../../design/components/sprout_bouncy_tap.dart';
import '../../design/components/sprout_button.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/sprout_haptics.dart';
import '../../design/typography.dart';
import '../../design/sprout_ingredient_formatter.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../../services/voice_cooking_service.dart';
import '../../services/gemini_tts_service.dart';
import '../../services/gemini_sous_chef_service.dart';
import '../../services/notification_service.dart';
import '../../services/in_app_review_service.dart';
import '../../services/recipe_translation_service.dart';

class CookingScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const CookingScreen({super.key, required this.recipe});

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final GeminiTtsService _geminiTts = GeminiTtsService();
  final FlutterTts _flutterTts = FlutterTts();
  int _currentStep = 0;
  bool _isSpeaking = false;
  bool _isSynthesizingTts = false;

  // Active Translated Recipe & Bilingual Mode
  late Recipe _activeRecipe;
  String _currentLanguage = 'en'; // 'en' or 'hi'
  bool _isTranslating = false;

  // Smart Contextual Timer State
  Timer? _countdownTimer;
  int _timerSecondsRemaining = 0;
  int _timerTotalSeconds = 0;
  bool _isTimerRunning = false;
  bool get _isLowLight => SproutColors.isDarkMode;
  bool _isTimerMorphedToTop = false;

  // Hands-free Voice Cooking & Notifications
  final VoiceCookingService _voiceCookingService = VoiceCookingService();
  bool _isVoiceListening = false;
  bool _isConnectingVoice = false;
  String? _voiceError;
  String? _currentPartialTranscript;

  // AI Sous-Chef Sprout Conversational Assistant
  final GeminiSousChefService _sousChefService = GeminiSousChefService();
  String? _lastSproutQuestion;
  String? _lastSproutAnswer;
  bool _isChefSproutThinking = false;
  String? _voiceFeedbackMessage;
  Timer? _voiceFeedbackTimer;

  @override
  void initState() {
    super.initState();
    // Keep screen awake during cooking
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);

    _activeRecipe = widget.recipe;
    final isSourceHindi = RecipeTranslationService.isRecipeHindi(widget.recipe);
    _currentLanguage = isSourceHindi ? 'hi' : 'en';

    _initFlutterTts();
    _initVoiceBargeIn();
    _restoreSession();
    _prefetchTts(0);
    _prefetchTts(1);
    _checkForSmartTimer(0);
    SproutNotificationService().initialize();
  }

  void _initFlutterTts() {
    try {
      _flutterTts.setCompletionHandler(() async {
        await _voiceCookingService.onTtsFinished(
          resumeIfHandsFree: _isVoiceListening,
        );
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isSynthesizingTts = false;
          });
        }
      });
      _flutterTts.setErrorHandler((_) async {
        await _voiceCookingService.onTtsFinished(
          resumeIfHandsFree: _isVoiceListening,
        );
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isSynthesizingTts = false;
          });
        }
      });
      _flutterTts.setCancelHandler(() async {
        await _voiceCookingService.onTtsFinished(
          resumeIfHandsFree: _isVoiceListening,
        );
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isSynthesizingTts = false;
          });
        }
      });
    } catch (_) {}
  }

  void _initVoiceBargeIn() {
    _voiceCookingService.onBargeIn = () async {
      if (_isSpeaking || _isSynthesizingTts) {
        await _geminiTts.stopAudio();
        try {
          await _flutterTts.stop();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isSynthesizingTts = false;
          });
        }
      }
    };
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    _closeVoiceSession();
    _countdownTimer?.cancel();
    _voiceFeedbackTimer?.cancel();
    SproutNotificationService().cancel(1001);
    _pageController.dispose();
    super.dispose();
  }

  // Persist step when the app is backgrounded so cooking can resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref
          .read(cookSessionProvider.notifier)
          .saveProgress(widget.recipe, _currentStep);
    }
  }

  Future<void> _toggleLanguage() async {
    final newLang = _currentLanguage == 'hi' ? 'en' : 'hi';
    setState(() => _isTranslating = true);
    SproutHaptics.selection();
    try {
      final translated = await RecipeTranslationService().translateRecipe(
        widget.recipe,
        targetLanguage: newLang,
      );
      if (mounted) {
        setState(() {
          _currentLanguage = newLang;
          _activeRecipe = translated;
          _isTranslating = false;
        });
        _checkForSmartTimer(_currentStep);
        _prefetchTts(_currentStep);
        _prefetchTts(_currentStep + 1);
      }
    } catch (e) {
      debugPrint('Error toggling language: $e');
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _restoreSession() {
    final session = ref.read(cookSessionProvider).value;
    if (session != null && session.recipe.id == widget.recipe.id) {
      final step = session.currentStep.clamp(
        0,
        _activeRecipe.instructions.length - 1,
      );
      if (step > 0) {
        _currentStep = step;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) _pageController.jumpToPage(step);
        });
      }
    }
  }

  void _prefetchTts(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _activeRecipe.instructions.length) {
      final cleanText = _cleanStepInstruction(
        _activeRecipe.instructions[stepIndex],
      );
      final isHindi =
          _currentLanguage == 'hi' ||
          RecipeTranslationService.isHindi(cleanText);
      _geminiTts.getOrSynthesizeSpeech(
        text: cleanText,
        recipeId: widget.recipe.id,
        stepNumber: stepIndex + 1,
        isHindi: isHindi,
      );
    }
  }

  Future<void> _speakWithDeviceTts(String text, {required bool isHindi}) async {
    try {
      if (mounted) setState(() => _isSpeaking = true);
      if (isHindi) {
        try {
          await _flutterTts.setLanguage("hi-IN");
          await _flutterTts.setSpeechRate(0.48);
        } catch (_) {}
      } else {
        try {
          await _flutterTts.setLanguage("en-US");
          await _flutterTts.setSpeechRate(0.5);
        } catch (_) {}
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Device TTS speak error: $e');
      await _voiceCookingService.onTtsFinished(
        resumeIfHandsFree: _isVoiceListening,
      );
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _speakCurrentStep() async {
    // If currently speaking or synthesizing, stop immediately
    if (_isSpeaking || _isSynthesizingTts) {
      await _geminiTts.stopAudio();
      try {
        await _flutterTts.stop();
      } catch (_) {}
      await _voiceCookingService.onTtsFinished(
        resumeIfHandsFree: _isVoiceListening,
      );
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isSynthesizingTts = false;
        });
      }
      return;
    }

    final rawText = _activeRecipe.instructions[_currentStep];
    final stepText = _cleanStepInstruction(rawText);
    final currentStepNumber = _currentStep + 1;
    final isHindi =
        _currentLanguage == 'hi' || RecipeTranslationService.isHindi(rawText);

    // Mutual Exclusion: Stop SpeechRecognizer mic before starting TTS
    await _voiceCookingService.stopMicForTts();
    setState(() => _isSynthesizingTts = true);

    try {
      // High-fidelity human conversational Gemini AI voice with Aoede voice (Hindi/English)
      final audioPath = await _geminiTts.getOrSynthesizeSpeech(
        text: stepText,
        recipeId: widget.recipe.id,
        stepNumber: currentStepNumber,
        isHindi: isHindi,
      );

      if (!mounted) return;
      setState(() => _isSynthesizingTts = false);

      if (audioPath != null) {
        setState(() => _isSpeaking = true);
        await _geminiTts.playAudio(
          audioPath,
          onComplete: () async {
            await _voiceCookingService.onTtsFinished(
              resumeIfHandsFree: _isVoiceListening,
            );
            if (mounted) {
              setState(() => _isSpeaking = false);
            }
          },
        );
      } else {
        // Seamless on-device TTS fallback
        await _speakWithDeviceTts(stepText, isHindi: isHindi);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSynthesizingTts = false);
      // Fallback to on-device TTS on exception
      await _speakWithDeviceTts(stepText, isHindi: isHindi);
    }
  }

  void _showVoiceFeedback(String message) {
    _voiceFeedbackTimer?.cancel();
    if (mounted) {
      setState(() => _voiceFeedbackMessage = message);
      _voiceFeedbackTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) {
          setState(() => _voiceFeedbackMessage = null);
        }
      });
    }
  }

  Future<void> _closeVoiceSession() async {
    await _voiceCookingService.stopListening();
    await _geminiTts.stopAudio();
    try {
      await _flutterTts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isVoiceListening = false;
        _isConnectingVoice = false;
        _isChefSproutThinking = false;
        _isSpeaking = false;
        _isSynthesizingTts = false;
        _currentPartialTranscript = null;
        _lastSproutAnswer = null;
        _lastSproutQuestion = null;
        _voiceError = null;
      });
    }
  }

  Future<void> _startAskSproutVoiceSession() async {
    // If TTS is currently speaking, barge-in / interrupt immediately!
    if (_isSpeaking || _isSynthesizingTts) {
      await _geminiTts.stopAudio();
      try {
        await _flutterTts.stop();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isSynthesizingTts = false;
        });
      }
    }

    setState(() {
      _isConnectingVoice = true;
      _voiceError = null;
      _currentPartialTranscript = null;
      _lastSproutAnswer = null;
    });

    final ok = await _voiceCookingService.initialize();
    if (!ok) {
      if (mounted) {
        setState(() {
          _isConnectingVoice = false;
          _voiceError = 'Microphone permission required for Ask Sprout.';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isConnectingVoice = false;
      _isVoiceListening = true;
      _currentPartialTranscript = null;
      _voiceError = null;
    });

    await _voiceCookingService.startListening(
      onListeningChanged: () {
        if (mounted) {
          setState(() {
            _isVoiceListening = _voiceCookingService.isListening;
          });
        }
      },
      onPartialTranscript: (transcript) {
        if (mounted) {
          setState(() => _currentPartialTranscript = transcript);
        }
      },
      onCommand: (cmd, spokenText) {
        if (!mounted) return;
        _handleVoiceCommand(cmd, spokenText);
      },
    );
  }

  void _toggleVoiceControl() async {
    final isLiveActive =
        _isVoiceListening ||
        _isConnectingVoice ||
        _isChefSproutThinking ||
        _isSpeaking;
    if (isLiveActive) {
      await _closeVoiceSession();
    } else {
      await _startAskSproutVoiceSession();
    }
  }

  void _handleVoiceCommand(VoiceCookingCommand cmd, String spokenText) {
    SproutHaptics.medium();
    switch (cmd) {
      case VoiceCookingCommand.next:
        _showVoiceFeedback("Heard 'Next' ⏭️");
        if (_currentStep < widget.recipe.instructions.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _completeCooking();
        }
        break;

      case VoiceCookingCommand.previous:
        _showVoiceFeedback("Heard 'Back' ⏮️");
        if (_currentStep > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        break;

      case VoiceCookingCommand.read:
        _showVoiceFeedback("Reading Step ${_currentStep + 1} 🔊");
        _speakCurrentStep();
        break;

      case VoiceCookingCommand.timer:
        _showVoiceFeedback(
          _isTimerRunning ? "Pausing Timer ⏱️" : "Starting Timer ⏱️",
        );
        _toggleTimer();
        break;

      case VoiceCookingCommand.stop:
        _showVoiceFeedback("Stopped ⏹️");
        if (_isTimerRunning) _toggleTimer();
        if (_isSpeaking || _isSynthesizingTts) {
          _geminiTts.stopAudio();
          setState(() {
            _isSpeaking = false;
            _isSynthesizingTts = false;
          });
          _voiceCookingService.onTtsFinished(
            resumeIfHandsFree: _isVoiceListening,
          );
        }
        break;

      case VoiceCookingCommand.question:
        _showVoiceFeedback("Chef Sprout is thinking... 🧑‍🍳");
        _askChefSprout(spokenText);
        break;

      case VoiceCookingCommand.unknown:
        break;
    }
  }

  Future<void> _askChefSprout(String question) async {
    // Mutual Exclusion: Stop SpeechRecognizer before processing or speaking
    await _voiceCookingService.stopMicForTts();
    _voiceCookingService.setVoiceState(CookingVoiceState.processing);

    setState(() {
      _isChefSproutThinking = true;
      _lastSproutQuestion = question;
      _lastSproutAnswer = null;
    });

    try {
      final isHindi =
          _currentLanguage == 'hi' ||
          RecipeTranslationService.isHindi(_activeRecipe.title);
      final answer = await _sousChefService.askCookingQuestion(
        question: question,
        recipeTitle: _activeRecipe.displayTitle,
        ingredients: _activeRecipe.ingredients,
        currentStepText: _activeRecipe.instructions[_currentStep],
        stepNumber: _currentStep + 1,
      );

      if (!mounted) return;

      if (answer != null && answer.isNotEmpty) {
        setState(() {
          _isChefSproutThinking = false;
          _lastSproutAnswer = answer;
        });

        // Synthesize spoken answer with Gemini natural voice
        _voiceCookingService.setVoiceState(CookingVoiceState.speaking);
        final audioPath = await _geminiTts.synthesizeSpokenAnswer(
          text: answer,
          answerId:
              '${widget.recipe.id}_q_${DateTime.now().millisecondsSinceEpoch}',
          isHindi: isHindi || RecipeTranslationService.isHindi(answer),
        );

        if (audioPath != null && mounted) {
          setState(() => _isSpeaking = true);
          await _geminiTts.playAudio(
            audioPath,
            onComplete: () async {
              await _voiceCookingService.onTtsFinished(
                resumeIfHandsFree: _isVoiceListening,
              );
              if (mounted) {
                setState(() => _isSpeaking = false);
              }
            },
          );
        } else if (mounted) {
          await _speakWithDeviceTts(
            answer,
            isHindi: isHindi || RecipeTranslationService.isHindi(answer),
          );
        }
      } else {
        setState(() {
          _isChefSproutThinking = false;
          _voiceError = "Connection error. Chef Sprout couldn't respond.";
        });
        await _voiceCookingService.onTtsFinished(
          resumeIfHandsFree: _isVoiceListening,
        );
      }
    } catch (e) {
      debugPrint('Error asking Chef Sprout: $e');
      if (mounted) {
        setState(() {
          _isChefSproutThinking = false;
          _voiceError = "Could not process question. Tap to retry.";
        });
        await _voiceCookingService.onTtsFinished(
          resumeIfHandsFree: _isVoiceListening,
        );
      }
    }
  }

  void _showAskChefSproutDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SproutColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Image.asset(
              SproutAssets.stylingCookingMascot,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text('Ask Chef Sprout', style: SproutTypography.h3()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask any culinary question about Step ${_currentStep + 1} (e.g. substitutions, temperature, or cooking tips)',
              style: SproutTypography.caption(color: SproutColors.secondaryInk),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g. Can I use butter instead of oil?',
                hintStyle: SproutTypography.body(color: SproutColors.sage),
                filled: true,
                fillColor: SproutColors.canvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: SproutColors.sage.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: SproutColors.sproutGreen,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(ctx).pop();
                  _askChefSprout(val.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: SproutTypography.body(color: SproutColors.secondaryInk),
            ),
          ),
          SproutButton(
            label: 'Ask',
            width: 90,
            height: 40,
            onPressed: () {
              final q = textController.text.trim();
              if (q.isNotEmpty) {
                Navigator.of(ctx).pop();
                _askChefSprout(q);
              }
            },
          ),
        ],
      ),
    ).then((_) => textController.dispose());
  }

  int _extractDurationSeconds(String text) {
    final lower = text.toLowerCase();

    // 1. Explicit minutes in text (e.g. "for 2 minutes", "10-15 mins")
    final minRegExp = RegExp(
      r'(\d+)\s*(?:to\s*\d+\s*)?(?:minutes|mins|minute|min)',
    );
    final minMatch = minRegExp.firstMatch(lower);
    if (minMatch != null) {
      final mins = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
      if (mins > 0) return mins * 60;
    }

    // 2. Explicit seconds in text (e.g. "30 seconds")
    final secRegExp = RegExp(r'(\d+)\s*(?:seconds|secs|second|sec)');
    final secMatch = secRegExp.firstMatch(lower);
    if (secMatch != null) {
      final secs = int.tryParse(secMatch.group(1) ?? '0') ?? 0;
      if (secs > 0) return secs;
    }

    // 3. Explicit hours in text (e.g. "1 hour")
    final hrRegExp = RegExp(r'(\d+)\s*(?:hours|hour|hr|hrs)');
    final hrMatch = hrRegExp.firstMatch(lower);
    if (hrMatch != null) {
      final hrs = int.tryParse(hrMatch.group(1) ?? '0') ?? 0;
      if (hrs > 0) return hrs * 3600;
    }

    // 4. Smart step duration for preheating steps without explicit numbers:
    // Defaults to 2 minutes (120s -> 02:00), never binding the total recipe time!
    if (RegExp(r'\b(?:preheat|pre-heat)\b').hasMatch(lower) ||
        RegExp(
          r'\bheat\s+(?:a|the)?\s*(?:dosa\s+)?(?:tawa|pan|skillet|griddle|kadai|kadhai|wok|oil|oven)\b',
        ).hasMatch(lower)) {
      return 120; // 02:00 for preheating cookware
    }

    return 0;
  }

  // Parse duration from text or initialize with smart step duration on start
  void _checkForSmartTimer(int stepIndex) {
    if (_isTimerRunning) return;

    if (stepIndex >= _activeRecipe.instructions.length) return;

    final currentInstruction = _activeRecipe.instructions[stepIndex];
    int stepDuration = _extractDurationSeconds(currentInstruction);
    if (stepDuration == 0 &&
        RecipeTranslationService.isHindi(currentInstruction)) {
      stepDuration = RecipeTranslationService.extractHindiDurationSeconds(
        currentInstruction,
      );
    }

    if (stepDuration > 0) {
      setState(() {
        _timerTotalSeconds = stepDuration;
        _timerSecondsRemaining = stepDuration;
      });
      return;
    }

    // At the start (step 0), ensure a timer is present right from the beginning
    if (stepIndex == 0) {
      int initialSeconds = 0;
      if (widget.recipe.totalTimeMins > 0) {
        initialSeconds = widget.recipe.totalTimeMins * 60;
      } else {
        for (final instruction in _activeRecipe.instructions) {
          var s = _extractDurationSeconds(instruction);
          if (s == 0 && RecipeTranslationService.isHindi(instruction)) {
            s = RecipeTranslationService.extractHindiDurationSeconds(
              instruction,
            );
          }
          if (s > 0) {
            initialSeconds = s;
            break;
          }
        }
      }
      if (initialSeconds <= 0) initialSeconds = 120;

      setState(() {
        _timerTotalSeconds = initialSeconds;
        _timerSecondsRemaining = initialSeconds;
      });
      return;
    }

    if (_timerTotalSeconds > 0) {
      return;
    }
  }

  void _adjustTimer(int deltaSeconds) {
    HapticFeedback.selectionClick();
    setState(() {
      _timerSecondsRemaining = (_timerSecondsRemaining + deltaSeconds).clamp(
        5,
        7200,
      );
      if (_timerTotalSeconds < _timerSecondsRemaining) {
        _timerTotalSeconds = _timerSecondsRemaining;
      }
    });
  }

  void _toggleTimer() {
    HapticFeedback.selectionClick();
    if (_isTimerRunning) {
      _countdownTimer?.cancel();
      SproutNotificationService().cancel(1001);
      setState(() => _isTimerRunning = false);
    } else {
      if (_timerSecondsRemaining <= 0) {
        _timerSecondsRemaining = _timerTotalSeconds > 0
            ? _timerTotalSeconds
            : 120;
      }
      setState(() {
        _isTimerRunning = true;
        _isTimerMorphedToTop = true; // Morphs into top when clicked/started
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerSecondsRemaining > 0) {
          setState(() => _timerSecondsRemaining--);
          if (_timerSecondsRemaining % 5 == 0 || _timerSecondsRemaining <= 10) {
            SproutNotificationService().showTimerProgress(
              recipeTitle: widget.recipe.title,
              stepDescription:
                  'Step ${_currentStep + 1}: ${widget.recipe.instructions[_currentStep]}',
              secondsRemaining: _timerSecondsRemaining,
              totalSeconds: _timerTotalSeconds,
            );
          }
        } else {
          timer.cancel();
          setState(() => _isTimerRunning = false);
          SproutNotificationService().showTimerComplete(
            recipeTitle: widget.recipe.title,
            stepDescription:
                'Step ${_currentStep + 1}: ${widget.recipe.instructions[_currentStep]}',
          );
          _showTimerCompletedDialog();
        }
      });
    }
  }

  void _showTimerCompletedDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SproutColors.surface,
        shape: RoundedRectangleBorder(borderRadius: SproutRadii.card),
        title: Row(
          children: const [
            Icon(
              Icons.alarm_on_rounded,
              color: SproutColors.sproutGreen,
              size: 28,
            ),
            SizedBox(width: 10),
            Text('Timer Complete! 🔔'),
          ],
        ),
        content: Text(
          'Your timer for step ${_currentStep + 1} has finished.',
          style: SproutTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Dismiss',
              style: SproutTypography.bodyBold(color: SproutColors.sproutGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _onStepChanged(int index) {
    setState(() {
      _currentStep = index;
    });
    _checkForSmartTimer(index);
    ref.read(cookSessionProvider.notifier).saveProgress(widget.recipe, index);
    _prefetchTts(index + 1);
    if (_isSpeaking) {
      _geminiTts.stopAudio();
      _voiceCookingService.setNarrating(false);
      _isSpeaking = false;
      _speakCurrentStep();
    }
  }

  Future<bool> _confirmExitCooking() async {
    final totalSteps = widget.recipe.instructions.length;
    if (_currentStep == 0 || _currentStep >= totalSteps - 1) {
      return true;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SproutColors.surface,
        shape: RoundedRectangleBorder(borderRadius: SproutRadii.card),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: SproutColors.tomato),
            SizedBox(width: 8),
            Text('Exit Cooking?'),
          ],
        ),
        content: Text(
          'You are on step ${_currentStep + 1} of $totalSteps for ${widget.recipe.displayTitle}. Do you want to leave this session?',
          style: SproutTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep Cooking',
              style: SproutTypography.bodyBold(color: SproutColors.sproutGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(cookSessionProvider.notifier).clear();
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              'Exit',
              style: SproutTypography.bodyBold(color: SproutColors.tomato),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  /// Extracts a crisp, 3-5 word action-oriented title for the step header.
  String _getActionTitle(String instruction) {
    var cleaned = instruction.trim();
    if (cleaned.isEmpty) {
      return _currentLanguage == 'hi' ? 'विधि चरण' : 'Cooking Step';
    }

    // If text is Hindi or current mode is Hindi, extract clean Hindi action title
    if (RecipeTranslationService.isHindi(cleaned) || _currentLanguage == 'hi') {
      return RecipeTranslationService.getHindiActionTitle(cleaned);
    }

    // Remove leading numbering like "1. ", "Step 1: "
    cleaned = cleaned
        .replaceFirst(
          RegExp(
            r'^(?:step\s*\d+[:\.\-]?\s*|\d+[\.\)\-]\s*)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Remove boilerplate introductory clauses like "To begin making the [Name] Recipe, "
    cleaned = cleaned
        .replaceFirst(
          RegExp(
            r'^(?:to\s+(?:begin|start)\s+(?:making|preparing|cooking|with)\s+(?:the\s+)?(?:[^,]+)?,\s*)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    cleaned = cleaned
        .replaceFirst(
          RegExp(
            r'^(?:first(?:ly)?|next|then|now|meanwhile|after\s+that|finally),?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    final lower = cleaned.toLowerCase();

    // Specific culinary actions with crisp 3-4 word titles
    if (RegExp(r'\b(?:preheat|pre-heat)\b').hasMatch(lower) ||
        RegExp(r'\bheat\s+(?:a|the)?\s*(?:dosa\s+)?tawa\b').hasMatch(lower)) {
      if (lower.contains('tawa')) return 'Preheat the Tawa';
      if (lower.contains('pan')) return 'Preheat the Pan';
      if (lower.contains('skillet')) return 'Preheat the Skillet';
      if (lower.contains('oven')) return 'Preheat the Oven';
      return 'Preheat Cookware';
    }

    // Check for colon prefix like "Prep aromatics: Chop onions."
    final colonIdx = cleaned.indexOf(':');
    if (colonIdx > 2 && colonIdx < 30) {
      final phrase = cleaned.substring(0, colonIdx).trim();
      final words = phrase.split(RegExp(r'\s+'));
      if (words.length <= 5) {
        return _toTitleCase(phrase);
      }
    }

    // Look for first sentence or clause
    final punctIdx = cleaned.indexOf(RegExp(r'[\.\;\n]'));
    String phrase = punctIdx != -1
        ? cleaned.substring(0, punctIdx).trim()
        : cleaned;

    // Take meaningful first clause up to comma if reasonable
    final commaIdx = phrase.indexOf(',');
    if (commaIdx > 8 && commaIdx < 35) {
      phrase = phrase.substring(0, commaIdx).trim();
    }

    // Truncate to maximum 4 words for a clean, concise action title
    final words = phrase.split(RegExp(r'\s+'));
    if (words.length > 4) {
      phrase = words.take(4).join(' ');
    }

    return _toTitleCase(phrase);
  }

  /// Strips conversational filler like "To begin making the [Recipe Name] Recipe..."
  /// and leading filler words so the card body delivers direct, clean instructions.
  String _cleanStepInstruction(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return text;

    if (RecipeTranslationService.isHindi(text)) {
      text = text
          .replaceFirst(
            RegExp(
              r'^(?:स्टेप\s*\d+[:\.\-]?\s*|चरण\s*\d+[:\.\-]?\s*|\d+[\.\)\-]\s*)',
            ),
            '',
          )
          .trim();
      text = text
          .replaceFirst(
            RegExp(r'^(?:[^,]+?बनाने\s+के\s+लिए\s+(?:सबसे\s+पहले\s+)?,?\s*)'),
            '',
          )
          .trim();
      text = text
          .replaceFirst(RegExp(r'^(?:सबसे\s+पहले|इसके\s+बाद|फिर|अब),?\s*'), '')
          .trim();
      return text;
    }

    // Remove leading numbering
    text = text
        .replaceFirst(
          RegExp(
            r'^(?:step\s*\d+[:\.\-]?\s*|\d+[\.\)\-]\s*)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Strip conversational filler like "To begin making the Paneer Chilli Dosa Recipe, "
    text = text
        .replaceFirst(
          RegExp(
            r'^(?:to\s+(?:begin|start)\s+(?:making|preparing|cooking|with)\s+(?:the\s+)?(?:[^,]+)?,\s*)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Strip generic filler like "Firstly, " / "To start, "
    text = text
        .replaceFirst(
          RegExp(
            r'^(?:firstly|first of all|to start with|to begin with),?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }
    return text;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    final lowerWords = {
      'a',
      'an',
      'the',
      'and',
      'or',
      'in',
      'on',
      'at',
      'to',
      'for',
      'with',
      'of',
    };
    final parts = text.split(RegExp(r'\s+'));
    final capitalized = <String>[];
    for (int i = 0; i < parts.length; i++) {
      final word = parts[i];
      if (word.isEmpty) continue;
      final lower = word.toLowerCase();
      if (i > 0 && lowerWords.contains(lower)) {
        capitalized.add(lower);
      } else {
        capitalized.add(
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        );
      }
    }
    return capitalized.join(' ');
  }

  List<String> _extractActionBlocks(String instruction) {
    var cleaned = _cleanStepInstruction(instruction);
    if (cleaned.isEmpty) return [];

    final colonIdx = cleaned.indexOf(':');
    if (colonIdx > 2 && colonIdx < 35 && colonIdx < cleaned.length - 1) {
      final afterColon = cleaned.substring(colonIdx + 1).trim();
      if (afterColon.isNotEmpty) {
        cleaned = afterColon;
      }
    }

    final rawParts = cleaned.split(
      RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])|\n+|;\s*'),
    );
    final results = <String>[];

    for (final part in rawParts) {
      var item = part.trim();
      item = item.replaceFirst(RegExp(r'^[-•*]\s*|^\d+[\.\)]\s*'), '').trim();
      if (item.isNotEmpty) {
        results.add(item);
      }
    }

    if (results.isEmpty && cleaned.isNotEmpty) {
      results.add(cleaned);
    }
    return results;
  }

  // --- EXPANDABLE INSTRUCTION FULL MODAL ---
  void _showExpandedInstructionModal(
    BuildContext context,
    int stepNumber,
    String actionTitle,
    String fullText,
    List<String> actionBlocks,
    Color surfaceColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color accentColor,
    Color borderColor,
  ) {
    SproutHaptics.selection();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: SproutColors.sage.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Top Modal Bar: Step Badge + Close Icon
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: SproutRadii.borderPill,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'STEP $stepNumber DETAILS',
                                  style: SproutTypography.caption(
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                  ).copyWith(letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: primaryTextColor,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Scrollable Detailed Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Action Title & Watercolor Underline (non-clipped)
                            Text(
                              actionTitle,
                              style:
                                  SproutTypography.h2(color: primaryTextColor)
                                      .copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                            ),
                            const SizedBox(height: 6),
                            Image.asset(
                              SproutAssets.stylingStroke1,
                              width: 140,
                              height: 14,
                              fit: BoxFit.contain,
                              color: SproutColors.sage.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 16),

                            // Complete Instruction Text
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _isLowLight
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : SproutColors.canvas.withValues(
                                        alpha: 0.6,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                fullText,
                                style:
                                    SproutTypography.body(
                                      color: primaryTextColor,
                                    ).copyWith(
                                      fontSize: 18,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),

                            if (actionBlocks.length > 1) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Action Breakdown',
                                style:
                                    SproutTypography.h3(color: primaryTextColor)
                                        .copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(actionBlocks.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: SproutTypography.caption(
                                            color: accentColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          actionBlocks[i],
                                          style:
                                              SproutTypography.body(
                                                color: primaryTextColor,
                                              ).copyWith(
                                                fontSize: 16,
                                                height: 1.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Floating Action Inside Modal
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Got It ✓',
                            style: SproutTypography.bodyBold(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _completeCooking() async {
    if (!mounted) return;

    SproutHaptics.success();

    int userRating = 5;
    String difficulty = 'Easy';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark =
              Theme.of(context).brightness == Brightness.dark ||
              SproutColors.isDarkMode;
          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: SproutColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: SproutColors.sage.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.7, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Image.asset(
                        SproutAssets.mascotSuccess,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SproutColors.sproutGreen.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: SproutColors.sproutGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: SproutColors.sproutGreen,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'CHEF SPROUT MASTERED',
                                style: SproutTypography.caption(
                                  color: SproutColors.sproutGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bon Appétit! 🎉',
                      style: SproutTypography.h2(
                        color: isDark
                            ? SproutColors.nightPrimaryInk
                            : SproutColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You successfully completed ${widget.recipe.displayTitle}! Logged to your cook history.',
                      textAlign: TextAlign.center,
                      style: SproutTypography.body(
                        color: SproutColors.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          avatar: Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: SproutColors.primaryInk,
                          ),
                          label: Text('${widget.recipe.totalTimeMins} mins'),
                          backgroundColor: SproutColors.canvas,
                          side: BorderSide.none,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: Icon(
                            Icons.format_list_numbered_rounded,
                            size: 16,
                            color: SproutColors.primaryInk,
                          ),
                          label: Text(
                            '${widget.recipe.instructions.length} steps',
                          ),
                          backgroundColor: SproutColors.canvas,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Post-cooking Star Rating
                    Text(
                      'How did it turn out?',
                      style: SproutTypography.smallBold(
                        color: SproutColors.primaryInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= userRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFE8933A),
                            size: 32,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              userRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Post-cooking Difficulty Rating
                    Text(
                      'How difficult was it?',
                      style: SproutTypography.smallBold(
                        color: SproutColors.primaryInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDifficultyChip('Easy', '🌱 Easy', difficulty, (
                          val,
                        ) {
                          setSheetState(() => difficulty = val);
                        }),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(
                          'Okay',
                          '👌 Just Right',
                          difficulty,
                          (val) {
                            setSheetState(() => difficulty = val);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(
                          'Challenging',
                          '🔥 Challenging',
                          difficulty,
                          (val) {
                            setSheetState(() => difficulty = val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    SproutButton(
                      label: 'Done Cooking',
                      width: double.infinity,
                      onPressed: () async {
                        await ref
                            .read(cookHistoryProvider.notifier)
                            .recordCook(
                              widget.recipe,
                              rating: userRating,
                              difficulty: difficulty,
                            );
                        await ref.read(cookSessionProvider.notifier).clear();
                        InAppReviewService().requestReviewIfAppropriate();
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyChip(
    String value,
    String label,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == current;
    return InkWell(
      borderRadius: SproutRadii.borderPill,
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SproutColors.sproutGreen : SproutColors.canvas,
          borderRadius: SproutRadii.borderPill,
          border: Border.all(
            color: isSelected
                ? SproutColors.sproutGreen
                : SproutColors.sage.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: SproutTypography.caption(
            color: isSelected ? Colors.white : SproutColors.primaryInk,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMorphedTopTimer(
    Color surfaceColor,
    Color accentColor,
    Color borderColor,
    Color secondaryTextColor,
    Color primaryTextColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        color: surfaceColor,
        shape: SproutRadii.squircleCard(
          side: BorderSide(
            color: _isTimerRunning
                ? accentColor.withValues(alpha: 0.6)
                : borderColor,
            width: 1.5,
          ),
          smoothing: 0.6,
        ),
        shadows: [
          BoxShadow(
            color: _isTimerRunning
                ? accentColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            SproutAssets.stylingTimerMascot,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isTimerRunning ? 'Cooking Timer' : 'Suggested Duration',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              Text(
                _formatTime(_timerSecondsRemaining),
                style: GoogleFonts.fraunces(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          SproutBouncyTap(
            onTap: () => _adjustTimer(-60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Icon(
                Icons.remove_rounded,
                size: 16,
                color: primaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SproutBouncyTap(
            onTap: () => _adjustTimer(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Icon(Icons.add_rounded, size: 16, color: primaryTextColor),
            ),
          ),
          const SizedBox(width: 8),
          SproutBouncyTap(
            onTap: _toggleTimer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isTimerRunning ? SproutColors.tomato : accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isTimerRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isTimerRunning ? 'Pause' : 'Start',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: secondaryTextColor,
              size: 20,
            ),
            tooltip: 'Expand timer to step card',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isTimerMorphedToTop = false);
            },
          ),
        ],
      ),
    );
  }

  // --- UNIFIED ASK SPROUT 🎤 PILL (TOP BAR TRAILING) ---
  Widget _buildUnifiedAskChefSproutPill(
    Color surfaceColor,
    Color borderColor,
    Color accentColor,
  ) {
    final isLiveActive =
        _isVoiceListening ||
        _isConnectingVoice ||
        _isChefSproutThinking ||
        _isSpeaking;

    return Tooltip(
      message: isLiveActive
          ? 'Close Ask Sprout'
          : 'Ask Sprout (voice / question)',
      child: SproutBouncyTap(
        onTap: _toggleVoiceControl,
        onLongPress: _showAskChefSproutDialog,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: isLiveActive
                ? SproutColors.tomato
                : SproutColors.sproutGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLiveActive
                  ? SproutColors.tomato
                  : SproutColors.sproutGreen.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                    isLiveActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 15,
                    color: isLiveActive
                        ? Colors.white
                        : SproutColors.sproutGreen,
                  )
                  .animate(
                    target: isLiveActive ? 1 : 0,
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .scaleXY(end: 1.15, duration: 600.ms),
              const SizedBox(width: 4),
              Text(
                'Ask Sprout',
                style: GoogleFonts.inter(
                  color: isLiveActive ? Colors.white : SproutColors.sproutGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BILINGUAL TRANSLATION SWITCHER PILL [ 🌐 EN | HI ] ---
  Widget _buildLanguageSwitcherPill(
    Color surfaceColor,
    Color borderColor,
    Color accentColor,
    Color secondaryTextColor,
  ) {
    final isHi = _currentLanguage == 'hi';

    return Tooltip(
      message: isHi
          ? 'Switch to English'
          : 'हिंदी में अनुवाद करें (Translate to Hindi)',
      child: SproutBouncyTap(
        onTap: _isTranslating ? null : _toggleLanguage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: isHi
                ? SproutColors.carrot.withValues(alpha: 0.12)
                : surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHi ? SproutColors.carrot : borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isLowLight ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTranslating)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              else
                const Text('🌐', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
              Text(
                isHi ? 'HI' : 'EN',
                style: GoogleFonts.inter(
                  color: isHi ? SproutColors.carrot : accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EXTRACT INGREDIENTS USED IN CURRENT STEP ---
  List<String> _extractStepIngredients(String stepText) {
    final lowerStep = stepText.toLowerCase();
    final matched = <String>[];

    const stopWords = {
      'and',
      'the',
      'with',
      'for',
      'into',
      'from',
      'heat',
      'pan',
      'cook',
      'until',
      'add',
      'mix',
      'well',
      'minutes',
      'seconds',
      'bowl',
      'pot',
      'over',
      'medium',
      'high',
      'low',
      'flame',
      'taste',
      'water',
      'spoon',
      'cup',
      'cups',
      'tbsp',
      'tsp',
      'tablespoon',
      'teaspoon',
      'gram',
      'grams',
      'pinch',
      'pieces',
      'chopped',
      'finely',
      'sliced',
    };

    for (final rawIngredient in _activeRecipe.ingredients) {
      final normalized = SproutIngredientFormatter.normalize(rawIngredient);
      final lowerIng = rawIngredient.toLowerCase();

      final tokens = lowerIng
          .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
          .split(' ')
          .where((t) => t.length >= 3 && !stopWords.contains(t))
          .toList();

      bool isMatch = false;
      for (final token in tokens) {
        if (lowerStep.contains(token)) {
          isMatch = true;
          break;
        }
      }

      if (!isMatch) {
        if (lowerIng.contains('oil') && lowerStep.contains('oil')) {
          isMatch = true;
        }
        if (lowerIng.contains('butter') && lowerStep.contains('butter')) {
          isMatch = true;
        }
        if (lowerIng.contains('ghee') && lowerStep.contains('ghee')) {
          isMatch = true;
        }
      }

      if (isMatch && !matched.contains(normalized)) {
        matched.add(normalized);
      }
    }
    return matched;
  }

  // --- EXTRACT HEAT / FLAME LEVEL FROM STEP TEXT ---
  String? _extractHeatLevel(String stepText) {
    final lower = stepText.toLowerCase();
    if (lower.contains('medium-high flame') ||
        lower.contains('medium-high heat') ||
        lower.contains('medium to high')) {
      return '🔥 Med-High Flame';
    }
    if (lower.contains('medium flame') ||
        lower.contains('medium heat') ||
        lower.contains('medium-low') ||
        lower.contains('मध्यम आंच')) {
      return '🔥 Medium Flame';
    }
    if (lower.contains('high flame') ||
        lower.contains('high heat') ||
        lower.contains('तेज आंच')) {
      return '🔥 High Flame';
    }
    if (lower.contains('low flame') ||
        lower.contains('low heat') ||
        lower.contains('simmer') ||
        lower.contains('slow flame') ||
        lower.contains('धीमी आंच')) {
      return '🔥 Low Flame';
    }
    return null;
  }

  // --- STEP AT-A-GLANCE CHIPS: INGREDIENTS & HEAT LEVEL ---
  Widget _buildStepAtAGlanceChips(
    String stepText,
    Color primaryTextColor,
    Color accentColor,
  ) {
    final ingredients = _extractStepIngredients(stepText);
    final heat = _extractHeatLevel(stepText);

    if (ingredients.isEmpty && heat == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heat != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _isLowLight
                      ? const Color(0x334A2820)
                      : const Color(0x18E53935),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isLowLight
                        ? SproutColors.tomato.withValues(alpha: 0.35)
                        : SproutColors.tomato.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  heat,
                  style: GoogleFonts.inter(
                    color: _isLowLight
                        ? const Color(0xFFFF8A80)
                        : SproutColors.tomato,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ...ingredients.map((ing) {
            String emoji = '🥄';
            final lower = ing.toLowerCase();
            if (lower.contains('oil') ||
                lower.contains('ghee') ||
                lower.contains('butter')) {
              emoji = '🧈';
            }
            if (lower.contains('milk') ||
                lower.contains('curd') ||
                lower.contains('cream')) {
              emoji = '🥛';
            }
            if (lower.contains('coconut')) emoji = '🥥';
            if (lower.contains('onion')) emoji = '🧅';
            if (lower.contains('tomato')) emoji = '🍅';
            if (lower.contains('chilli') ||
                lower.contains('chili') ||
                lower.contains('pepper')) {
              emoji = '🌶️';
            }
            if (lower.contains('paneer') || lower.contains('cheese')) {
              emoji = '🧀';
            }
            if (lower.contains('rice') ||
                lower.contains('dosa') ||
                lower.contains('batter') ||
                lower.contains('flour')) {
              emoji = '🌾';
            }
            if (lower.contains('coriander') ||
                lower.contains('curry') ||
                lower.contains('mint') ||
                lower.contains('leaves')) {
              emoji = '🌿';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ing,
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- COMPACT ASK SPROUT STATUS INDICATOR (~40dp height, Zero Screen Obstruction) ---
  Widget _buildCompactVoiceStatusIndicator({
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color accentColor,
  }) {
    final isConnecting = _isConnectingVoice;
    final isListening = _isVoiceListening;
    final isProcessing = _isChefSproutThinking;
    final isSpeaking = _isSpeaking;
    final hasAnswer = _lastSproutAnswer != null;
    final hasError = _voiceError != null;
    final hasFeedback = _voiceFeedbackMessage != null;

    if (!isConnecting &&
        !isListening &&
        !isProcessing &&
        !isSpeaking &&
        !hasAnswer &&
        !hasError &&
        !hasFeedback) {
      return const SizedBox.shrink();
    }

    Widget leadingWidget;
    Widget messageWidget;

    if (hasFeedback &&
        !isProcessing &&
        !isSpeaking &&
        !hasAnswer &&
        !hasError) {
      leadingWidget = Icon(
        Icons.check_circle_outline_rounded,
        size: 16,
        color: accentColor,
      );
      messageWidget = Text(
        _voiceFeedbackMessage!,
        style: GoogleFonts.inter(
          color: accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (hasError) {
      leadingWidget = const Icon(
        Icons.error_outline_rounded,
        size: 16,
        color: SproutColors.tomato,
      );
      messageWidget = Text(
        _voiceError!,
        style: GoogleFonts.inter(
          color: SproutColors.tomato,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (isProcessing) {
      leadingWidget = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(SproutColors.carrot),
        ),
      );
      messageWidget = Text(
        _lastSproutQuestion != null
            ? 'Thinking: "${_lastSproutQuestion!}"'
            : 'Chef Sprout is thinking...',
        style: GoogleFonts.inter(
          color: primaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (isConnecting) {
      leadingWidget = SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        ),
      );
      messageWidget = Text(
        'Connecting to Ask Sprout...',
        style: GoogleFonts.inter(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (isSpeaking || hasAnswer) {
      leadingWidget = Icon(
        Icons.volume_up_rounded,
        size: 16,
        color: accentColor,
      );
      messageWidget = Text(
        _lastSproutAnswer ?? 'Chef Sprout is speaking...',
        style: GoogleFonts.inter(
          color: primaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      leadingWidget = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: SproutColors.tomato,
        ),
      );
      final hasTranscript =
          _currentPartialTranscript != null &&
          _currentPartialTranscript!.isNotEmpty;
      messageWidget = Text(
        hasTranscript
            ? '“${_currentPartialTranscript!}”'
            : 'Listening... Ask anything about this step',
        style: GoogleFonts.inter(
          color: hasTranscript ? primaryTextColor : secondaryTextColor,
          fontSize: 12,
          fontWeight: hasTranscript ? FontWeight.w600 : FontWeight.w500,
          fontStyle: hasTranscript ? FontStyle.italic : FontStyle.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isLowLight ? const Color(0xEE1A2820) : surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? SproutColors.tomato.withValues(alpha: 0.5)
                  : (isProcessing
                        ? SproutColors.carrot.withValues(alpha: 0.5)
                        : (isListening
                              ? SproutColors.tomato.withValues(alpha: 0.5)
                              : accentColor.withValues(alpha: 0.35))),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 8),
              Expanded(child: messageWidget),
              if (hasAnswer && !isProcessing && !hasError) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Replay answer',
                  child: SproutBouncyTap(
                    onTap: () async {
                      if (_lastSproutAnswer != null) {
                        await _voiceCookingService.stopMicForTts();
                        setState(() => _isSpeaking = true);
                        final isHindi =
                            _currentLanguage == 'hi' ||
                            RecipeTranslationService.isHindi(
                              _lastSproutAnswer!,
                            );
                        final audioPath = await _geminiTts
                            .synthesizeSpokenAnswer(
                              text: _lastSproutAnswer!,
                              answerId: 'replay_${_lastSproutAnswer.hashCode}',
                              isHindi: isHindi,
                            );
                        if (audioPath != null && mounted) {
                          await _geminiTts.playAudio(
                            audioPath,
                            onComplete: () async {
                              await _voiceCookingService.onTtsFinished(
                                resumeIfHandsFree: _isVoiceListening,
                              );
                              if (mounted) setState(() => _isSpeaking = false);
                            },
                          );
                        } else if (mounted) {
                          await _speakWithDeviceTts(
                            _lastSproutAnswer!,
                            isHindi: isHindi,
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.replay_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Tooltip(
                message: 'Close',
                child: SproutBouncyTap(
                  onTap: _closeVoiceSession,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final totalSteps = _activeRecipe.instructions.length;
    final progress = totalSteps > 0 ? (_currentStep + 1) / totalSteps : 1.0;

    final bgColor = _isLowLight
        ? SproutColors.nightCanvas
        : SproutColors.canvas;
    final surfaceColor = _isLowLight
        ? SproutColors.nightSurface
        : SproutColors.surface;
    final primaryTextColor = _isLowLight
        ? SproutColors.nightPrimaryInk
        : SproutColors.primaryInk;
    final secondaryTextColor = _isLowLight
        ? SproutColors.nightSecondaryInk
        : SproutColors.secondaryInk;
    final accentColor = _isLowLight
        ? SproutColors.nightAccent
        : SproutColors.sproutGreen;
    final borderColor = _isLowLight
        ? Colors.white.withValues(alpha: 0.12)
        : SproutColors.sage.withValues(alpha: 0.3);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmExitCooking();
        if (ok && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // --- CLEANED TOP BAR: Exit [✕] | Centered STEP X OF Y + Recipe Title | Language Switcher | Ask Sprout 🎤 ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        // Exit Button in modern tactile circle
                        SproutBouncyTap(
                          onTap: () async {
                            final ok = await _confirmExitCooking();
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: _isLowLight ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Centered Step Counter with subtle Recipe Title Subtitle (removes redundant pill below)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'STEP ${_currentStep + 1} OF $totalSteps',
                                  style: GoogleFonts.inter(
                                    color: accentColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _activeRecipe.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Language Switcher Pill [ 🌐 EN | HI ]
                        _buildLanguageSwitcherPill(
                          surfaceColor,
                          borderColor,
                          accentColor,
                          secondaryTextColor,
                        ),
                        const SizedBox(width: 6),

                        // Trailing Unified Ask Chef Sprout 🎤 Button (animates with flutter_animate)
                        _buildUnifiedAskChefSproutPill(
                          surfaceColor,
                          borderColor,
                          accentColor,
                        ),
                      ],
                    ),
                  ),

                  // Smooth Animated Rounded Step Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, _) {
                        return Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: _isLowLight
                                ? Colors.white.withValues(alpha: 0.12)
                                : SproutColors.sage.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: animatedValue.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Assistant Voice Banner in layout flow (Smooth AnimatedSize, never obscures top bar)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _buildCompactVoiceStatusIndicator(
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      accentColor: accentColor,
                    ),
                  ),

                  // Morphed Sticky Top Timer
                  if (_isTimerMorphedToTop &&
                      (_timerTotalSeconds > 0 || _isTimerRunning))
                    _buildMorphedTopTimer(
                      surfaceColor,
                      accentColor,
                      borderColor,
                      secondaryTextColor,
                      primaryTextColor,
                    ),

                  // Main Step Carousel (Illustrated Cookbook Style)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: totalSteps,
                      onPageChanged: _onStepChanged,
                      itemBuilder: (context, index) {
                        final rawStepText = _activeRecipe.instructions[index];
                        final actionTitle = _getActionTitle(rawStepText);
                        final cleanedStepText = _cleanStepInstruction(
                          rawStepText,
                        );
                        final actionBlocks = _extractActionBlocks(
                          cleanedStepText,
                        );

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hero Header Row: Action Title (3-5 words) + Non-clipped Underline + Mascot Illustration
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left: Editorial Serif Action Title + Brush Stroke (height 14, BoxFit.contain)
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          actionTitle,
                                          style: GoogleFonts.fraunces(
                                            color: primaryTextColor,
                                            fontSize: 26,
                                            height: 1.18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Image.asset(
                                          SproutAssets.stylingStroke1,
                                          width: 130,
                                          height: 14,
                                          fit: BoxFit.contain,
                                          color: SproutColors.sage.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Right: Mascot Sprout Cooking in Pan Illustration
                                  Expanded(
                                    flex: 5,
                                    child: Image.asset(
                                      SproutAssets.stylingCookingMascot,
                                      height: 120,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Open Step Instruction Area (Unboxed with ample breathing room)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Instruction Text (Tap to expand modal if long)
                                        Expanded(
                                          child: SproutBouncyTap(
                                            onTap: () {
                                              _showExpandedInstructionModal(
                                                context,
                                                index + 1,
                                                actionTitle,
                                                cleanedStepText,
                                                actionBlocks,
                                                surfaceColor,
                                                primaryTextColor,
                                                secondaryTextColor,
                                                accentColor,
                                                borderColor,
                                              );
                                            },
                                            child: Text(
                                              cleanedStepText,
                                              style:
                                                  SproutTypography.body(
                                                    color: primaryTextColor,
                                                  ).copyWith(
                                                    fontSize: 17,
                                                    height: 1.58,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Step At-a-Glance Chips: Ingredients & Heat Level
                                    _buildStepAtAGlanceChips(
                                      cleanedStepText,
                                      primaryTextColor,
                                      accentColor,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Navigation Controls: Back Button + Next Step
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        if (_currentStep > 0) ...[
                          SproutBouncyTap(
                            onTap: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: _isLowLight ? 0.2 : 0.03,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 22,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: SproutBouncyTap(
                            onTap: () {
                              if (_currentStep < totalSteps - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              } else {
                                _completeCooking();
                              }
                            },
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: SproutColors.sproutGreen,
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [
                                  BoxShadow(
                                    color: SproutColors.sproutGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep == totalSteps - 1
                                        ? (_currentLanguage == 'hi'
                                              ? 'पकाना पूरा हुआ ✓'
                                              : 'Complete Recipe ✓')
                                        : (_currentLanguage == 'hi'
                                              ? 'अगला चरण →'
                                              : 'Next Step →'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
