import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_item.dart';
import '../services/notification_service.dart';

/// Persists the user's pantry ingredients locally so Home can show
/// "You Can Make Now" without rescanning, and recipe detail can
/// split ingredients into "You have" / "You're missing".
class PantryRepository {
  static const String _key = 'sprout_pantry_items';

  static const String _staplesKey = 'sprout_pantry_staples';
  static const String _staplesEnabledKey = 'sprout_pantry_staples_enabled';

  static const List<String> defaultStaples = [
    'salt',
    'cooking oil',
    'turmeric powder',
    'red chilli powder',
    'cumin seeds',
    'mustard seeds',
    'garlic',
    'ginger',
    'onion',
  ];

  Future<List<String>> fetchPantry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (_) {
      // Storage unavailable (e.g. in tests) — degrade to empty pantry
      return [];
    }
  }

  Future<List<String>> fetchStaples() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_staplesKey);
      if (saved == null || saved.isEmpty) {
        return List<String>.from(defaultStaples);
      }
      return saved;
    } catch (_) {
      return List<String>.from(defaultStaples);
    }
  }

  Future<bool> fetchStaplesEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_staplesEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setStaplesEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_staplesEnabledKey, enabled);
    } catch (_) {}
  }

  Future<List<String>> saveStaples(List<String> items) async {
    final unique = <String>[];
    for (final item in items) {
      final normalized = item.trim().toLowerCase();
      if (normalized.isNotEmpty && !unique.contains(normalized)) {
        unique.add(normalized);
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_staplesKey, unique);
    } catch (_) {}
    return unique;
  }

  Future<List<String>> toggleStaple(String name) async {
    final current = await fetchStaples();
    final normalized = name.trim().toLowerCase();
    if (current.contains(normalized)) {
      current.remove(normalized);
    } else {
      current.add(normalized);
    }
    return saveStaples(current);
  }

  Future<List<String>> addStaple(String name) async {
    final current = await fetchStaples();
    return saveStaples([...current, name]);
  }

  Future<List<String>> resetStaples() async {
    return saveStaples(defaultStaples);
  }

  Future<List<String>> _save(List<String> items) async {
    // Deduplicate, normalize to lowercase, keep insertion order
    final unique = <String>[];
    for (final item in items) {
      final normalized = item.trim().toLowerCase();
      if (normalized.isNotEmpty && !unique.contains(normalized)) {
        unique.add(normalized);
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, unique);
    } catch (_) {
      // Persistence unavailable — keep the in-memory result
    }
    return unique;
  }

  Future<List<String>> addItems(List<String> names) async {
    final current = await fetchPantry();
    return _save([...current, ...names]);
  }

  Future<List<String>> removeItem(String name) async {
    final current = await fetchPantry();
    current.removeWhere((i) => i.toLowerCase() == name.toLowerCase());
    return _save(current);
  }

  Future<List<String>> clear() async {
    return _save([]);
  }

  // --- Structured PantryItem & Freshness Tracking ---
  static const String _itemsKeyV2 = 'sprout_pantry_items_v2';

  Future<List<PantryItem>> fetchPantryItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_itemsKeyV2);
      if (raw != null && raw.isNotEmpty) {
        return raw.map((s) => PantryItem.fromJson(jsonDecode(s))).toList();
      }

      // Backward-compatibility: migrate legacy string list
      final legacy = await fetchPantry();
      if (legacy.isNotEmpty) {
        final migrated = legacy.map((name) {
          return PantryItem(
            id: name.toLowerCase().replaceAll(' ', '_'),
            name: name,
            category: 'Pantry',
            addedAt: DateTime.now(),
          );
        }).toList();
        await savePantryItems(migrated);
        return migrated;
      }
    } catch (_) {}
    return [];
  }

  Future<void> savePantryItems(List<PantryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((it) => jsonEncode(it.toJson())).toList();
      await prefs.setStringList(_itemsKeyV2, jsonList);
      // Synchronize legacy string keys
      await _save(items.map((it) => it.name).toList());
    } catch (_) {}
  }

  Future<List<PantryItem>> addStructuredItem(PantryItem item) async {
    final current = await fetchPantryItems();
    current.removeWhere((i) => i.id == item.id || i.name.toLowerCase() == item.name.toLowerCase());
    current.add(item);
    await savePantryItems(current);
    return current;
  }

  Future<List<PantryItem>> removeStructuredItem(String id) async {
    final current = await fetchPantryItems();
    current.removeWhere((i) => i.id == id);
    await savePantryItems(current);
    return current;
  }

  Future<List<PantryItem>> updateItemExpiry(String id, DateTime expiresAt) async {
    final current = await fetchPantryItems();
    final index = current.indexWhere((i) => i.id == id);
    if (index != -1) {
      current[index] = current[index].copyWith(expiresAt: expiresAt);
      await savePantryItems(current);
    }
    return current;
  }

  Future<List<PantryItem>> checkAndNotifyExpiringSoon() async {
    final current = await fetchPantryItems();
    final expiring = current
        .where((i) => i.freshness == PantryFreshness.expiringSoon)
        .toList();
    if (expiring.isNotEmpty) {
      await SproutNotificationService().showPantryExpiryAlert(
        expiringItems: expiring.map((i) => i.name).toList(),
      );
    }
    return expiring;
  }
}

