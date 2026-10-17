import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/repositories/pantry_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PantryRepository Staples Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default staples when storage is uninitialized', () async {
      final repo = PantryRepository();
      final staples = await repo.fetchStaples();

      expect(staples, contains('salt'));
      expect(staples, contains('cooking oil'));
      expect(staples, contains('turmeric powder'));
      expect(staples.length, PantryRepository.defaultStaples.length);
    });

    test('Staples enabled defaults to true and toggles properly', () async {
      final repo = PantryRepository();
      expect(await repo.fetchStaplesEnabled(), isTrue);

      await repo.setStaplesEnabled(false);
      expect(await repo.fetchStaplesEnabled(), isFalse);

      await repo.setStaplesEnabled(true);
      expect(await repo.fetchStaplesEnabled(), isTrue);
    });

    test('Toggles a staple off and back on', () async {
      final repo = PantryRepository();
      final initial = await repo.fetchStaples();
      expect(initial.contains('garlic'), isTrue);

      final toggledOff = await repo.toggleStaple('garlic');
      expect(toggledOff.contains('garlic'), isFalse);

      final toggledOn = await repo.toggleStaple('garlic');
      expect(toggledOn.contains('garlic'), isTrue);
    });

    test('Adds custom staple and deduplicates', () async {
      final repo = PantryRepository();
      final updated = await repo.addStaple('soy sauce');
      expect(updated.contains('soy sauce'), isTrue);

      // Duplicate addition does not create duplicates
      final again = await repo.addStaple('SOY SAUCE');
      expect(again.where((s) => s == 'soy sauce').length, 1);
    });

    test('Resets staples to defaults', () async {
      final repo = PantryRepository();
      await repo.addStaple('sesame oil');
      await repo.toggleStaple('salt');

      final reset = await repo.resetStaples();
      expect(reset, equals(PantryRepository.defaultStaples));
    });
  });
}
