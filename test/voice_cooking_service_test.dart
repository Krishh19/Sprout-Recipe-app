import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/services/voice_cooking_service.dart';

void main() {
  group('VoiceCookingService Command Parser', () {
    test('parses next step commands correctly', () {
      expect(VoiceCookingService.parseCommand('next'), VoiceCookingCommand.next);
      expect(VoiceCookingService.parseCommand('Next Step please'), VoiceCookingCommand.next);
      expect(VoiceCookingService.parseCommand('move forward'), VoiceCookingCommand.next);
      expect(VoiceCookingService.parseCommand('continue'), VoiceCookingCommand.next);
    });

    test('parses previous step commands correctly', () {
      expect(VoiceCookingService.parseCommand('back'), VoiceCookingCommand.previous);
      expect(VoiceCookingService.parseCommand('previous step'), VoiceCookingCommand.previous);
      expect(VoiceCookingService.parseCommand('go back'), VoiceCookingCommand.previous);
    });

    test('parses read step commands correctly', () {
      expect(VoiceCookingService.parseCommand('read'), VoiceCookingCommand.read);
      expect(VoiceCookingService.parseCommand('repeat instructions'), VoiceCookingCommand.read);
      expect(VoiceCookingService.parseCommand('what now'), VoiceCookingCommand.read);
      expect(VoiceCookingService.parseCommand('speak aloud'), VoiceCookingCommand.read);
    });

    test('parses timer commands correctly', () {
      expect(VoiceCookingService.parseCommand('timer'), VoiceCookingCommand.timer);
      expect(VoiceCookingService.parseCommand('start timer'), VoiceCookingCommand.timer);
      expect(VoiceCookingService.parseCommand('begin countdown'), VoiceCookingCommand.timer);
    });

    test('parses stop and pause commands correctly', () {
      expect(VoiceCookingService.parseCommand('stop'), VoiceCookingCommand.stop);
      expect(VoiceCookingService.parseCommand('pause timer'), VoiceCookingCommand.stop);
      expect(VoiceCookingService.parseCommand('quiet'), VoiceCookingCommand.stop);
      expect(VoiceCookingService.parseCommand('silence'), VoiceCookingCommand.stop);
    });

    test('parses culinary questions correctly for Chef Sprout', () {
      expect(VoiceCookingService.parseCommand('how long do I cook this'), VoiceCookingCommand.question);
      expect(VoiceCookingService.parseCommand('can I use butter instead of oil?'), VoiceCookingCommand.question);
      expect(VoiceCookingService.parseCommand('what can I substitute for cream'), VoiceCookingCommand.question);
      expect(VoiceCookingService.parseCommand('why is my dough sticky'), VoiceCookingCommand.question);
      expect(VoiceCookingService.parseCommand('should I cover the pan?'), VoiceCookingCommand.question);
    });

    test('returns unknown for unhandled phrases', () {
      expect(VoiceCookingService.parseCommand(''), VoiceCookingCommand.unknown);
      expect(VoiceCookingService.parseCommand('hello world'), VoiceCookingCommand.unknown);
      expect(VoiceCookingService.parseCommand('random chatter in kitchen'), VoiceCookingCommand.unknown);
    });

    test('isInstructionEcho identifies speaker bleed from instruction text', () {
      const instruction = 'Heat olive oil in a pan over medium heat for 2 minutes.';

      // Acoustic bleed matching start of instruction
      expect(VoiceCookingService.isInstructionEcho('heat olive oil', instruction), isTrue);
      // Multi-word phrase inside instruction
      expect(VoiceCookingService.isInstructionEcho('over medium heat', instruction), isTrue);

      // Distinct user commands should NEVER be treated as echo
      expect(VoiceCookingService.isInstructionEcho('stop', instruction), isFalse);
      expect(VoiceCookingService.isInstructionEcho('pause', instruction), isFalse);
      expect(VoiceCookingService.isInstructionEcho('timer', instruction), isFalse);
      expect(VoiceCookingService.isInstructionEcho('how long do I cook this?', instruction), isFalse);

      // Unrelated spoken words should not be echo
      expect(VoiceCookingService.isInstructionEcho('next step', instruction), isFalse);
      expect(VoiceCookingService.isInstructionEcho('go back', instruction), isFalse);
    });

    test('setNarrating updates isNarrating state correctly', () {
      final service = VoiceCookingService();
      expect(service.isNarrating, isFalse);

      service.setNarrating(true, narratedInstruction: 'Stir gently');
      expect(service.isNarrating, isTrue);

      service.setNarrating(false);
      expect(service.isNarrating, isFalse);
    });

    test('Audio state machine tracks voiceState and isSpeakingTTS properly', () {
      final service = VoiceCookingService();
      expect(service.voiceState, CookingVoiceState.idle);
      expect(service.isSpeakingTTS, isFalse);

      service.setVoiceState(CookingVoiceState.listening);
      expect(service.voiceState, CookingVoiceState.listening);

      service.setSpeakingTTS(true);
      expect(service.isSpeakingTTS, isTrue);
      expect(service.voiceState, CookingVoiceState.speaking);

      service.setSpeakingTTS(false);
      expect(service.isSpeakingTTS, isFalse);
      expect(service.voiceState, CookingVoiceState.idle);
    });

    test('onTtsFinished transitions state to idle when not hands-free', () async {
      final service = VoiceCookingService();
      service.setSpeakingTTS(true);
      expect(service.isSpeakingTTS, isTrue);

      await service.onTtsFinished(resumeIfHandsFree: false);
      expect(service.isSpeakingTTS, isFalse);
      expect(service.voiceState, CookingVoiceState.idle);
    });
  });
}
