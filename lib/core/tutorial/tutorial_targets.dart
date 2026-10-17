import 'package:flutter/material.dart';

/// Central repository of [GlobalKey] references for Sprout's in-app
/// feature discovery and spotlight tours.
class TutorialTargets {
  TutorialTargets._();

  /// Singleton instance
  static final TutorialTargets instance = TutorialTargets._();

  /// Target 1: Center floating AI food & ingredient scanner
  final GlobalKey scannerKey = GlobalKey();

  /// Target 2: Home explore & search bar
  final GlobalKey searchKey = GlobalKey();

  /// Target 3: Kitchen ingredients & pantry match action card
  final GlobalKey pantryKey = GlobalKey();

  /// Target 4: Saved recipes & grocery shopping list navigation tab
  final GlobalKey savedKey = GlobalKey();

  /// Target 5: Chef profile & dietary preferences navigation tab
  final GlobalKey profileKey = GlobalKey();

  /// Returns the ordered list of keys for the main 5-step tour.
  List<GlobalKey> get mainTourKeys => [
        scannerKey,
        searchKey,
        pantryKey,
        savedKey,
        profileKey,
      ];
}
