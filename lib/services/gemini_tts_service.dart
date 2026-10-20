import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/config.dart';

class GeminiTtsService {
  static final GeminiTtsService _instance = GeminiTtsService._internal();
  factory GeminiTtsService() => _instance;
  GeminiTtsService._internal();

  AudioPlayer? _audioPlayer;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;
  bool _isPlaying = false;
  VoidCallback? _onCompletionCallback;

  AudioPlayer get audioPlayer {
    if (_audioPlayer == null) {
      final player = AudioPlayer();
      _audioPlayer = player;
      _playerCompleteSubscription = player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _onCompletionCallback?.call();
        _onCompletionCallback = null;
      });
      _playerStateSubscription = player.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          _isPlaying = false;
        } else if (state == PlayerState.playing) {
          _isPlaying = true;
        }
      });
    }
    return _audioPlayer!;
  }

  bool get isPlaying => _isPlaying;

  static const String voiceDirection =
      'A light, warm and natural conversational voice with a gentle, medium-to-high pitch. '
      'Friendly and relaxed, with a slightly upbeat tone. Speak clearly at a comfortable, '
      'moderately paced speed. Use natural intonation, subtle breaths and short pauses '
      'between related instructions. Pause a little longer between recipe steps. '
      'Keep the voice soft and approachable, not deep, bass-heavy, dramatic, '
      'overly cheerful or like a commercial narrator. Avoid robotic rhythm and exaggerated emotions. '
      'Sound like a friendly person calmly explaining how to cook.';

  static const String hindiVoiceDirection =
      'A warm, natural, gentle conversational Indian voice speaking Hindi fluently and clearly with a warm, friendly culinary tone. '
      'Speak in polite, everyday conversational Hindi (खड़ी बोली) with natural intonation, comfortable pacing, and subtle breaths. '
      'Sound like an experienced, warm home chef explaining cooking steps simply and encouragingly. '
      'Ensure natural pronunciation of traditional Hindi cooking terms and ingredients.';

  /// Selected voice: 'Aoede' (Warm, friendly, culinary instructor voice)
  static const String selectedVoice = 'Aoede';

  /// Detects if byte payload already contains a 44-byte RIFF WAVE header
  static bool hasWavHeader(Uint8List bytes) {
    if (bytes.length < 12) return false;
    return bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
           bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45;
  }

  /// Wraps raw 16-bit linear PCM audio in a valid 44-byte RIFF WAV header
  static Uint8List addWavHeader(Uint8List pcmBytes, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataLength = pcmBytes.length;
    final totalLength = 36 + dataLength;

    final header = ByteData(44);
    // 'RIFF'
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, totalLength, Endian.little);
    // 'WAVE'
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // 'fmt '
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little); // AudioFormat 1 = PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // 'data'
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataLength, Endian.little);

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(pcmBytes);
    return builder.toBytes();
  }

  /// In-flight requests map to prevent duplicate network calls for the same step
  final Map<String, Future<String?>> _inFlightRequests = {};

  /// Prepares cooking instruction text with subtle human breathing & pause tags.
  static String formatCookingText(String rawText, int stepNumber, {bool isHindi = false}) {
    var text = rawText.trim();
    // Strip leading "Step X:" or "चरण X:" or "स्टेप X:" if already present to avoid duplication
    text = text.replaceFirst(
      RegExp(r'^(?:step\s*\d+[:\.\-]?\s*|चरण\s*\d+[:\.\-]?\s*|स्टेप\s*\d+[:\.\-]?\s*|\d+[\.\)\-]\s*)', caseSensitive: false),
      '',
    ).trim();

    var stepPrefix = isHindi
        ? 'चरण $stepNumber. <short pause> '
        : 'Step $stepNumber. <short pause> ';

    // Add subtle pauses after periods, danda (।), and semicolons for natural culinary pacing
    text = text.replaceAll(RegExp(r'[\.।]\s+'), '. <short pause> ');
    text = text.replaceAll(RegExp(r';\s+'), '; <short pause> ');

    return '$stepPrefix$text';
  }

  /// Synthesizes human-like speech using Gemini 3.8 Flash TTS / Flash-Lite TTS.
  /// Returns the cached audio file path or null if unavailable.
  Future<String?> getOrSynthesizeSpeech({
    required String text,
    required String recipeId,
    required int stepNumber,
    bool isHindi = false,
  }) async {
    final safeRecipeId = recipeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final langPrefix = isHindi ? 'hi' : 'en';
    final cacheKey = 'sprout_tts_${langPrefix}_${selectedVoice.toLowerCase()}_${safeRecipeId}_step_$stepNumber.wav';

    // If already in flight, reuse the running request
    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey];
    }

    final future = _executeSynthesis(
      text: text,
      safeRecipeId: safeRecipeId,
      stepNumber: stepNumber,
      cacheKey: cacheKey,
      isHindi: isHindi,
    );

    _inFlightRequests[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<String?> _executeSynthesis({
    required String text,
    required String safeRecipeId,
    required int stepNumber,
    required String cacheKey,
    bool isHindi = false,
  }) {
    final formattedText = formatCookingText(text, stepNumber, isHindi: isHindi);
    return _synthesizeAudioText(
      spokenText: formattedText,
      cacheKey: cacheKey,
      logLabel: 'step $stepNumber (${isHindi ? "hi" : "en"})',
      isHindi: isHindi,
    );
  }

  /// Synthesizes conversational responses from Chef Sprout using the same human Fola voice.
  Future<String?> synthesizeSpokenAnswer({
    required String text,
    required String answerId,
    bool isHindi = false,
  }) async {
    final safeId = answerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final langPrefix = isHindi ? 'hi' : 'en';
    final cacheKey = 'sprout_tts_answer_${langPrefix}_${selectedVoice.toLowerCase()}_$safeId.wav';

    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey];
    }

    final future = _synthesizeAudioText(
      spokenText: text,
      cacheKey: cacheKey,
      logLabel: 'answer $safeId',
      isHindi: isHindi,
    );

    _inFlightRequests[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<String?> _synthesizeAudioText({
    required String spokenText,
    required String cacheKey,
    String logLabel = '',
    bool isHindi = false,
  }) async {
    try {
      Directory tempDir;
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = Directory.systemTemp;
      }

      final cacheFile = File('${tempDir.path}/$cacheKey');

      // 1. Instant Cache Hit (0ms latency, 0 API cost)
      if (await cacheFile.exists() && (await cacheFile.length()) > 0) {
        debugPrint('GeminiTts: Cache hit for $cacheKey');
        return cacheFile.path;
      }

      // If API key is missing, degrade gracefully
      if (AppConfig.geminiApiKey.isEmpty) {
        debugPrint('GeminiTts: API key empty');
        return null;
      }

      // 1. Try standard generateContent with preview TTS models (generous quota on Free Tier)
      final primaryModels = [
        'gemini-3.8-flash-lite-tts',
        'gemini-3.8-flash-tts',
      ];

      for (final model in primaryModels) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${AppConfig.geminiApiKey}',
        );

        final requestPayload = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': spokenText,
                  'speech_metadata': {
                    'style': isHindi ? hindiVoiceDirection : voiceDirection,
                  },
                }
              ],
            }
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'voice': selectedVoice,
              },
            },
          },
        };

        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(requestPayload),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = decoded['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final inlineData = parts[0]['inlineData'] as Map<String, dynamic>?;
                final base64Audio = inlineData?['data'] as String?;
                final mimeType = inlineData?['mimeType'] as String? ?? '';

                if (base64Audio != null && base64Audio.isNotEmpty) {
                  final audioBytes = base64Decode(base64Audio);
                  Uint8List finalWavBytes;
                  // If already valid RIFF WAV, use directly; otherwise prepend 44-byte standard RIFF WAV header
                  if (hasWavHeader(audioBytes) || mimeType.contains('wav')) {
                    finalWavBytes = audioBytes;
                  } else {
                    finalWavBytes = addWavHeader(audioBytes, sampleRate: 24000);
                  }

                  await cacheFile.writeAsBytes(finalWavBytes);
                  debugPrint('GeminiTts ($model): Synthesized & cached $logLabel with $selectedVoice (${finalWavBytes.length} bytes)');
                  return cacheFile.path;
                }
              }
            }
          } else {
            debugPrint('GeminiTts ($model) HTTP ${response.statusCode}: ${response.body}');
            if (response.statusCode == 429 || response.statusCode >= 500) {
              continue;
            }
          }
        } catch (e) {
          debugPrint('GeminiTts ($model) generateContent attempt error: $e');
        }
      }

      // 2. Fallback to interactions API endpoint if available
      final interactionsUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/interactions?key=${AppConfig.geminiApiKey}',
      );
      final interactionModels = ['gemini-3.8-flash-lite-tts', 'gemini-3.8-flash-tts'];

      for (final model in interactionModels) {
        final requestPayload = {
          'model': model,
          'input': [
            {
              'type': 'user_input',
              'content': [
                {
                  'type': 'text',
                  'text': spokenText,
                  'annotations': [
                    {
                      'type': 'speech_metadata',
                      'style': isHindi ? hindiVoiceDirection : voiceDirection,
                    }
                  ],
                }
              ],
            }
          ],
          'response_format': {
            'type': 'audio',
            'mime_type': 'audio/wav',
          },
          'generation_config': {
            'speech_config': [
              {'voice': selectedVoice}
            ],
          },
        };

        try {
          final response = await http.post(
            interactionsUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body) as Map<String, dynamic>;
            String? base64Audio;
            if (decoded.containsKey('steps')) {
              final steps = decoded['steps'] as List?;
              if (steps != null) {
                for (final step in steps) {
                  if (step is Map<String, dynamic>) {
                    final contents = step['content'] as List?;
                    if (contents != null) {
                      for (final item in contents) {
                        if (item is Map<String, dynamic> &&
                            (item['type'] == 'audio' || item['mime_type']?.toString().contains('audio') == true) &&
                            item['data'] != null) {
                          base64Audio = item['data'] as String?;
                          break;
                        }
                      }
                    }
                  }
                  if (base64Audio != null) break;
                }
              }
            } else if (decoded.containsKey('output_audio')) {
              base64Audio = decoded['output_audio']?['data'] as String?;
            } else if (decoded.containsKey('outputs')) {
              final outputs = decoded['outputs'] as List?;
              if (outputs != null && outputs.isNotEmpty) {
                base64Audio = outputs.first['data'] as String?;
              }
            }

            if (base64Audio != null && base64Audio.isNotEmpty) {
              final audioBytes = base64Decode(base64Audio);
              await cacheFile.writeAsBytes(audioBytes);
              debugPrint('GeminiTts Interactions ($model): Synthesized & cached $logLabel (${audioBytes.length} bytes)');
              return cacheFile.path;
            }
          }
        } catch (e) {
          debugPrint('GeminiTts Interactions ($model) attempt error: $e');
        }
      }
    } catch (e) {
      debugPrint('GeminiTts error: $e');
    }

    return null;
  }

  /// Plays synthesized audio file with duplex audio focus configured.
  Future<void> playAudio(String filePath, {VoidCallback? onComplete}) async {
    try {
      await stopAudio();
      _isPlaying = true;
      _onCompletionCallback = onComplete;

      // Configure audio session for simultaneous speech playback & mic recording (duplex)
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.speech,
              usageType: AndroidUsageType.assistanceNavigationGuidance,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playAndRecord,
              options: const {
                AVAudioSessionOptions.defaultToSpeaker,
                AVAudioSessionOptions.allowBluetooth,
                AVAudioSessionOptions.duckOthers,
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('AudioContext setup error: $e');
      }

      await audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('GeminiTts playAudio error: $e');
      _isPlaying = false;
      _onCompletionCallback = null;
      onComplete?.call();
    }
  }

  /// Stops audio playback.
  Future<void> stopAudio() async {
    try {
      if (_isPlaying && _audioPlayer != null) {
        await _audioPlayer!.stop();
      }
    } catch (_) {}
    _isPlaying = false;
    _onCompletionCallback = null;
  }

  /// Disposes audio player and cancels active stream subscriptions.
  Future<void> dispose() async {
    await stopAudio();
    await _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = null;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    await _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
