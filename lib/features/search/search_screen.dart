import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_filter_chip.dart';
import '../../design/components/sprout_grid_recipe_card.dart';
import '../../design/components/sprout_recipe_card.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/components/sprout_search_bar.dart';
import '../../design/components/sprout_shimmer.dart';
import '../../design/components/sprout_typewriter_hint.dart';
import '../../design/radii.dart';
import '../../design/spacing.dart';
import '../../design/sprout_assets.dart';
import '../../design/sprout_haptics.dart';
import '../../design/typography.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../../repositories/recipe_repository.dart';
import '../../services/sprout_voice_search_service.dart';
import '../recipes/recipe_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chipsScrollController = ScrollController();
  final SproutVoiceSearchService _voiceSearch = SproutVoiceSearchService();

  Timer? _debounce;
  List<Recipe> _results = [];
  List<Recipe> _recommendedRecipes = RecipeRepository.fallbackRecipes.take(4).toList();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Voice Search state
  bool _isListeningVoice = false;
  String _voiceStatusText = '';

  // 1. Quick Chips: Discovery shortcuts (strictly 6 common one-tap user intents)
  String? _selectedQuickFilter;
  final List<Map<String, String>> _quickFilters = const [
    {'label': 'All', 'emoji': '✨'},
    {'label': 'Indian', 'emoji': '🍛'},
    {'label': 'Quick', 'emoji': '⚡'},
    {'label': 'High Protein', 'emoji': '💪'},
    {'label': 'Healthy', 'emoji': '🌿'},
    {'label': 'Vegetarian', 'emoji': '🥬'},
  ];

  // 2. Advanced Filters (Refine results sheet)
  int? _selectedMaxTime;
  Set<String> _selectedCuisines = <String>{};
  String? _selectedDiet; // 'veg', 'vegan', 'non-veg', 'egg'
  int? _selectedMaxCalories;
  final Set<String> _includedIngredients = <String>{};
  final Set<String> _excludedIngredients = <String>{};

  final List<int> _timeOptions = [15, 30, 45, 60];
  final List<String> _cuisineOptions = const [
    'Italian',
    'Mexican',
    'Chinese',
    'Japanese',
    'Thai',
    'Spanish',
    'French',
    'American',
    'Mediterranean',
    'British',
    'Continental',
    'Asian',
    'Indian',
    'North Indian',
    'South Indian',
    'Punjabi',
    'Bengali',
    'Gujarati',
    'Maharashtrian',
    'Rajasthani',
    'Kerala',
    'Tamil Nadu',
    'Goan',
    'Chettinad',
    'Kashmiri',
  ];

  final List<Map<String, String>> _dietOptions = const [
    {'label': 'Any', 'value': ''},
    {'label': 'Vegetarian', 'value': 'veg'},
    {'label': 'Vegan', 'value': 'vegan'},
    {'label': 'Non-Veg', 'value': 'non-veg'},
    {'label': 'Eggitarian', 'value': 'egg'},
  ];

  final List<int> _calorieOptions = [350, 500, 650];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _performSearch();
    _loadRecommendedRecipes();
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != null && widget.initialQuery != oldWidget.initialQuery) {
      _searchController.text = widget.initialQuery!;
      _selectedQuickFilter = null;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _voiceSearch.cancelListening();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _chipsScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedRecipes() async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final trending = await repo.fetchTrendingRecipes(limit: 6);
      if (mounted) {
        setState(() {
          _recommendedRecipes = trending;
        });
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 280;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _scrollChipsTo(int index) {
    if (!_chipsScrollController.hasClients) return;
    final nextIndex = (index + 1).clamp(0, _quickFilters.length - 1);
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (nextIndex * 105.0) - (screenWidth * 0.45);
    final maxScroll = _chipsScrollController.position.maxScrollExtent;
    final clamped = targetOffset.clamp(0.0, maxScroll);
    _chipsScrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch();
    });
  }

  List<String>? _getActiveDiets() {
    final diets = <String>{};
    final prefs = ref.read(preferencesProvider);
    if (prefs.contains('Vegetarian')) {
      diets.add('veg');
    }
    if (_selectedQuickFilter == 'Vegetarian') {
      diets.add('veg');
    }
    if (_selectedDiet != null && _selectedDiet!.isNotEmpty) {
      diets.add(_selectedDiet!);
    }
    return diets.isNotEmpty ? diets.toList() : null;
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    final repo = ref.read(recipeRepositoryProvider);
    final isQuick = _selectedQuickFilter == 'Quick';
    final isIndian = _selectedQuickFilter == 'Indian';
    final isHighProtein = _selectedQuickFilter == 'High Protein';
    final isHealthy = _selectedQuickFilter == 'Healthy';

    final effectiveMaxTime = isQuick ? 25 : _selectedMaxTime;
    final effectiveCuisines = Set<String>.from(_selectedCuisines);
    if (isIndian) {
      effectiveCuisines.add('Indian');
    }

    final rawList = await repo.searchRecipes(
      query: _searchController.text,
      maxTime: effectiveMaxTime,
      cuisine: effectiveCuisines.length == 1 ? effectiveCuisines.first : null,
      cuisines: effectiveCuisines.toList(),
      diets: _getActiveDiets(),
      page: 0,
      pageSize: _pageSize,
    );

    var list = _applyLocalFilters(
      rawList,
      isHighProtein: isHighProtein,
      isHealthy: isHealthy,
    );

    if (mounted) {
      final sortedList = List<Recipe>.from(list);
      sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      setState(() {
        _results = sortedList;
        _isLoading = false;
        _hasMore = rawList.length >= _pageSize;
      });
    }
  }

  List<Recipe> _applyLocalFilters(
    List<Recipe> input, {
    required bool isHighProtein,
    required bool isHealthy,
  }) {
    const proteinKeywords = [
      'paneer', 'dal', 'chicken', 'egg', 'besan', 'soya', 'tofu', 'chana',
      'rajma', 'sprouts', 'fish', 'mutton', 'chickpea', 'lentil', 'moong'
    ];

    return input.where((r) {
      if (isHighProtein) {
        final matches = r.title.toLowerCase().contains('protein') ||
            r.description.toLowerCase().contains('protein') ||
            r.cleanedIngredients.any((i) => proteinKeywords.any((k) => i.toLowerCase().contains(k)));
        if (!matches) return false;
      }
      if (isHealthy) {
        final matches = r.totalTimeMins <= 45 &&
            (r.title.toLowerCase().contains('salad') ||
                r.title.toLowerCase().contains('spinach') ||
                r.title.toLowerCase().contains('dal') ||
                r.cleanedIngredients.any((i) =>
                    i.contains('spinach') ||
                    i.contains('sprouts') ||
                    i.contains('cucumber') ||
                    i.contains('karela')));
        if (!matches) return false;
      }
      if (_includedIngredients.isNotEmpty) {
        final matches = _includedIngredients.every((ing) =>
            r.cleanedIngredients.any((ci) => ci.toLowerCase().contains(ing.toLowerCase())));
        if (!matches) return false;
      }
      if (_excludedIngredients.isNotEmpty) {
        final matches = !_excludedIngredients.any((ing) =>
            r.cleanedIngredients.any((ci) => ci.toLowerCase().contains(ing.toLowerCase())));
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final repo = ref.read(recipeRepositoryProvider);

    final isQuick = _selectedQuickFilter == 'Quick';
    final isIndian = _selectedQuickFilter == 'Indian';
    final isHighProtein = _selectedQuickFilter == 'High Protein';
    final isHealthy = _selectedQuickFilter == 'Healthy';

    final effectiveMaxTime = isQuick ? 25 : _selectedMaxTime;
    final effectiveCuisines = Set<String>.from(_selectedCuisines);
    if (isIndian) {
      effectiveCuisines.add('Indian');
    }

    final rawList = await repo.searchRecipes(
      query: _searchController.text,
      maxTime: effectiveMaxTime,
      cuisine: effectiveCuisines.length == 1 ? effectiveCuisines.first : null,
      cuisines: effectiveCuisines.toList(),
      diets: _getActiveDiets(),
      page: nextPage,
      pageSize: _pageSize,
    );

    final list = _applyLocalFilters(
      rawList,
      isHighProtein: isHighProtein,
      isHealthy: isHealthy,
    );

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _results.addAll(list);
        _results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        _isLoadingMore = false;
        _hasMore = rawList.length >= _pageSize;
      });
    }
  }

  void _toggleVoiceSearch() async {
    if (_isListeningVoice) {
      SproutHaptics.light();
      await _voiceSearch.stopListening();
      if (mounted) {
        setState(() {
          _isListeningVoice = false;
          _voiceStatusText = '';
        });
      }
      return;
    }

    SproutHaptics.medium();
    setState(() {
      _isListeningVoice = true;
      _voiceStatusText = 'Listening... Speak in English or Hindi';
    });

    await _voiceSearch.startListening(
      onResult: (spokenText) {
        if (!mounted) return;
        setState(() {
          _searchController.text = spokenText;
          _voiceStatusText = spokenText;
        });
      },
      onDone: () {
        if (!mounted) return;
        SproutHaptics.success();
        setState(() {
          _isListeningVoice = false;
          _voiceStatusText = '';
        });
        _performSearch();
      },
    );

    if (_voiceSearch.state == VoiceSearchState.permissionDenied) {
      if (!mounted) return;
      setState(() {
        _isListeningVoice = false;
        _voiceStatusText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _voiceSearch.errorMessage ??
                'Microphone permission is required for voice search. You can also type your search.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_voiceSearch.state == VoiceSearchState.failure) {
      if (!mounted) return;
      setState(() {
        _isListeningVoice = false;
        _voiceStatusText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_voiceSearch.errorMessage ?? 'Voice recognition failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFilterSheet() {
    int? tempMaxTime = _selectedMaxTime;
    final Set<String> tempCuisines = Set<String>.from(_selectedCuisines);
    String? tempDiet = _selectedDiet;
    int? tempCalories = _selectedMaxCalories;
    final Set<String> tempIncluded = Set<String>.from(_includedIngredients);
    final Set<String> tempExcluded = Set<String>.from(_excludedIngredients);
    final ingredientInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final totalCount = (tempMaxTime != null ? 1 : 0) +
              tempCuisines.length +
              (tempDiet != null && tempDiet!.isNotEmpty ? 1 : 0) +
              (tempCalories != null ? 1 : 0) +
              tempIncluded.length +
              tempExcluded.length;

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.86,
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: SproutColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: SproutColors.sage.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Pinned Header: Title, Active Badge, and Reset / Clear All Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Filters', style: SproutTypography.h3()),
                          if (totalCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: SproutColors.sproutGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalCount',
                                style: SproutTypography.smallBold(color: SproutColors.sproutGreen),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (totalCount > 0)
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempMaxTime = null;
                                  tempCuisines.clear();
                                  tempDiet = null;
                                  tempCalories = null;
                                  tempIncluded.clear();
                                  tempExcluded.clear();
                                });
                              },
                              child: Text(
                                'Clear All',
                                style: SproutTypography.small(color: SproutColors.tomato),
                              ),
                            ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempMaxTime = null;
                                tempCuisines.clear();
                                tempDiet = null;
                                tempCalories = null;
                                tempIncluded.clear();
                                tempExcluded.clear();
                              });
                              setState(() {
                                _selectedMaxTime = null;
                                _selectedCuisines.clear();
                                _selectedDiet = null;
                                _selectedMaxCalories = null;
                                _includedIngredients.clear();
                                _excludedIngredients.clear();
                                _selectedQuickFilter = null;
                              });
                              _performSearch();
                              Navigator.of(ctx).pop();
                            },
                            child: Text('Reset', style: SproutTypography.smallBold()),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scrollable Body: Cooking time, Cuisines, Diets, Calories, Ingredients
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Cooking Time (Max)
                          Text('Cooking Time (Max)', style: SproutTypography.bodyBold()),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _timeOptions.map((time) {
                              final isSel = tempMaxTime == time;
                              return ChoiceChip(
                                label: Text('≤ $time min'),
                                selected: isSel,
                                selectedColor: SproutColors.sproutGreen,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : SproutColors.primaryInk,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: SproutColors.canvas,
                                shape: RoundedRectangleBorder(
                                  borderRadius: SproutRadii.borderPill,
                                ),
                                onSelected: (selected) {
                                  setSheetState(() {
                                    tempMaxTime = selected ? time : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 2. Dietary Preference
                          Text('Dietary Preference', style: SproutTypography.bodyBold()),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _dietOptions.map((diet) {
                              final isSel = tempDiet == diet['value'];
                              return ChoiceChip(
                                label: Text(diet['label']!),
                                selected: isSel,
                                selectedColor: SproutColors.sproutGreen,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : SproutColors.primaryInk,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: SproutColors.canvas,
                                shape: RoundedRectangleBorder(
                                  borderRadius: SproutRadii.borderPill,
                                ),
                                onSelected: (selected) {
                                  setSheetState(() {
                                    tempDiet = selected ? diet['value'] : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 3. Cuisines
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cuisines', style: SproutTypography.bodyBold()),
                              if (tempCuisines.isNotEmpty)
                                Text(
                                  '${tempCuisines.length} selected',
                                  style: SproutTypography.small(color: SproutColors.sproutGreen),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _cuisineOptions.map((c) {
                              final isSel = tempCuisines.contains(c);
                              return FilterChip(
                                label: Text(c),
                                selected: isSel,
                                selectedColor: SproutColors.sproutGreen,
                                checkmarkColor: Colors.white,
                                showCheckmark: true,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : SproutColors.primaryInk,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: SproutColors.canvas,
                                shape: RoundedRectangleBorder(
                                  borderRadius: SproutRadii.borderPill,
                                ),
                                onSelected: (selected) {
                                  setSheetState(() {
                                    if (selected) {
                                      tempCuisines.add(c);
                                    } else {
                                      tempCuisines.remove(c);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 4. Calories (Max per serving)
                          Text('Calories (Max)', style: SproutTypography.bodyBold()),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _calorieOptions.map((cal) {
                              final isSel = tempCalories == cal;
                              return ChoiceChip(
                                label: Text('≤ $cal kcal'),
                                selected: isSel,
                                selectedColor: SproutColors.sproutGreen,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : SproutColors.primaryInk,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: SproutColors.canvas,
                                shape: RoundedRectangleBorder(
                                  borderRadius: SproutRadii.borderPill,
                                ),
                                onSelected: (selected) {
                                  setSheetState(() {
                                    tempCalories = selected ? cal : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 5. Ingredients Filter (Include / Exclude)
                          Text('Ingredients Available or Excluded',
                              style: SproutTypography.bodyBold()),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ingredientInputController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. paneer, onion...',
                                    hintStyle: SproutTypography.small(color: SproutColors.muted),
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    filled: true,
                                    fillColor: SproutColors.canvas,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: SproutColors.sage.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  final val = ingredientInputController.text.trim().toLowerCase();
                                  if (val.isNotEmpty) {
                                    setSheetState(() {
                                      tempIncluded.add(val);
                                      ingredientInputController.clear();
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: SproutColors.sproutGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                child: const Text('+ Include'),
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton(
                                onPressed: () {
                                  final val = ingredientInputController.text.trim().toLowerCase();
                                  if (val.isNotEmpty) {
                                    setSheetState(() {
                                      tempExcluded.add(val);
                                      ingredientInputController.clear();
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: SproutColors.tomato,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                child: const Text('- Exclude'),
                              ),
                            ],
                          ),
                          if (tempIncluded.isNotEmpty || tempExcluded.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ...tempIncluded.map((ing) => Chip(
                                      avatar: const Icon(Icons.check_circle_rounded,
                                          size: 16, color: SproutColors.sproutGreen),
                                      label: Text('Has: $ing'),
                                      onDeleted: () =>
                                          setSheetState(() => tempIncluded.remove(ing)),
                                    )),
                                ...tempExcluded.map((ing) => Chip(
                                      avatar: const Icon(Icons.cancel_rounded,
                                          size: 16, color: SproutColors.tomato),
                                      label: Text('No: $ing'),
                                      onDeleted: () =>
                                          setSheetState(() => tempExcluded.remove(ing)),
                                    )),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Pinned Footer: Directly accessible without scrolling
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: SproutColors.sage.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SproutColors.sproutGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: SproutRadii.button,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMaxTime = tempMaxTime;
                          _selectedCuisines = Set<String>.from(tempCuisines);
                          _selectedDiet = tempDiet;
                          _selectedMaxCalories = tempCalories;
                          _includedIngredients.clear();
                          _includedIngredients.addAll(tempIncluded);
                          _excludedIngredients.clear();
                          _excludedIngredients.addAll(tempExcluded);

                          if (_selectedCuisines.isEmpty && _selectedQuickFilter == 'Indian') {
                            _selectedQuickFilter = null;
                          }
                        });
                        _performSearch();
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        totalCount > 0 ? 'Apply Filters ($totalCount)' : 'Apply Filters',
                        style: SproutTypography.bodyBold(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || SproutColors.isDarkMode;
    final hasActiveFilters = _selectedMaxTime != null ||
        _selectedCuisines.isNotEmpty ||
        (_selectedDiet != null && _selectedDiet!.isNotEmpty) ||
        _selectedMaxCalories != null ||
        _includedIngredients.isNotEmpty ||
        _excludedIngredients.isNotEmpty;

    // Generous, unclipped header height providing ample space between chips and the 28px bottom border radius
    final headerHeight = hasActiveFilters ? 186.0 : 142.0;
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDiscoveryMode = _searchController.text.trim().isEmpty &&
        !hasActiveFilters &&
        (_selectedQuickFilter == null || _selectedQuickFilter == 'All');

    return SproutScaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: SproutColors.forestGreen,
        backgroundColor: SproutColors.surface,
        edgeOffset: topPadding,
        onRefresh: () async {
          await _performSearch();
          await _loadRecommendedRecipes();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Collapsible Floating Header: Sage top bar + Search bar + unclipped quick discovery chips
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              primary: true,
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E3528) : SproutColors.sage,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              surfaceTintColor: Colors.transparent,
              toolbarHeight: headerHeight,
              titleSpacing: 0,
              title: SizedBox(
                height: headerHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar with animated typewriter placeholder & voice recognition mic button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: SproutSearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onQueryChanged,
                        onFilterTap: _showFilterSheet,
                        enableVoiceSearch: true,
                        isListeningVoice: _isListeningVoice,
                        onVoiceSearchTap: _toggleVoiceSearch,
                        animatedHints: SproutTypewriterHint.defaultSuggestions,
                        hintText: 'Search recipes, ingredients...',
                        onClear: () {
                          setState(() {
                            _selectedQuickFilter = null;
                          });
                          _performSearch();
                        },
                      ),
                    ),

                    // Voice listening feedback indicator if active
                    if (_isListeningVoice && _voiceStatusText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _voiceStatusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SproutTypography.caption(
                                  color: isDark ? SproutColors.nightAccent : Colors.white,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleVoiceSearch,
                              child: Text(
                                'Cancel',
                                style: SproutTypography.caption(
                                  color: isDark ? SproutColors.nightSecondaryInk : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Quick Discovery Chips: Unclipped, dedicated row with consistent vertical spacing
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 6),
                      child: SizedBox(
                        height: 42,
                        child: ListView.builder(
                          controller: _chipsScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _quickFilters.length,
                          itemBuilder: (context, index) {
                            final item = _quickFilters[index];
                            final label = item['label']!;
                            final emoji = item['emoji']!;
                            final isSel = (_selectedQuickFilter == null && label == 'All') ||
                                (_selectedQuickFilter == label);

                            return SproutFilterChip(
                              label: label,
                              emoji: label == 'All' ? null : emoji,
                              isSelected: isSel,
                              onSelected: () {
                                _scrollChipsTo(index);
                                setState(() {
                                  if (label == 'All') {
                                    _selectedQuickFilter = null;
                                    _selectedMaxTime = null;
                                    _selectedCuisines.clear();
                                    _searchController.clear();
                                  } else if (isSel) {
                                    _selectedQuickFilter = null;
                                  } else {
                                    _selectedQuickFilter = label;
                                  }
                                });
                                _performSearch();
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Active Filters indicator if any
                    if (hasActiveFilters) ...[
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: [
                            if (_selectedMaxTime != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InputChip(
                                  label: Text('≤ $_selectedMaxTime min'),
                                  onDeleted: () {
                                    setState(() => _selectedMaxTime = null);
                                    _performSearch();
                                  },
                                ),
                              ),
                            if (_selectedDiet != null && _selectedDiet!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InputChip(
                                  label: Text('Diet: $_selectedDiet'),
                                  onDeleted: () {
                                    setState(() => _selectedDiet = null);
                                    _performSearch();
                                  },
                                ),
                              ),
                            ..._selectedCuisines.map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InputChip(
                                    label: Text(c),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCuisines.remove(c);
                                        if (_selectedCuisines.isEmpty &&
                                            _selectedQuickFilter == 'Indian') {
                                          _selectedQuickFilter = null;
                                        }
                                      });
                                      _performSearch();
                                    },
                                  ),
                                )),
                            ..._includedIngredients.map((i) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InputChip(
                                    label: Text('+$i'),
                                    onDeleted: () {
                                      setState(() => _includedIngredients.remove(i));
                                      _performSearch();
                                    },
                                  ),
                                )),
                            ..._excludedIngredients.map((i) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InputChip(
                                    label: Text('-$i'),
                                    onDeleted: () {
                                      setState(() => _excludedIngredients.remove(i));
                                      _performSearch();
                                    },
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Section 1: Recommended or Trending Recipes (shown in default discovery mode)
            if (isDiscoveryMode && _recommendedRecipes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommended for You ✨',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Expand or filter to trending recipes
                          setState(() {
                            _selectedQuickFilter = 'Healthy';
                          });
                          _performSearch();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See all',
                              style: SproutTypography.smallBold(
                                color: isDark ? SproutColors.nightAccent : SproutColors.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: isDark ? SproutColors.nightAccent : SproutColors.forestGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 275,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _recommendedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recommendedRecipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: SproutRecipeCard(
                          recipe: recipe,
                          heroTagPrefix: 'explore_rec',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                          onFavoriteToggle: () {
                            ref.read(savedRecipesProvider.notifier).toggleFavorite(recipe);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],

            // Section 2: Browse by Cuisine (shown in default discovery mode)
            if (isDiscoveryMode) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    'Browse by Cuisine 🌍',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      'Indian',
                      'Italian',
                      'Mexican',
                      'Asian',
                      'Mediterranean',
                      'Continental',
                      'Thai',
                      'Japanese',
                    ].map((cuisine) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Text(cuisine),
                          backgroundColor:
                              isDark ? SproutColors.nightElevatedSurface : SproutColors.softIvory,
                          labelStyle: TextStyle(
                            color: isDark ? SproutColors.nightPrimaryInk : SproutColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: SproutRadii.borderPill,
                            side: BorderSide(
                              color: isDark ? const Color(0xFF284031) : SproutColors.subtleBorder,
                              width: 1.0,
                            ),
                          ),
                          onPressed: () {
                            SproutHaptics.selection();
                            setState(() {
                              _selectedCuisines = {cuisine};
                              _selectedQuickFilter = null;
                            });
                            _performSearch();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],

            // Section 3: All Recipes ("Explore recipes")
            // No redundant "See all" since all recipes already appear right here in the main list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDiscoveryMode
                          ? 'Explore recipes'
                          : 'Results (${_results.length})',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? SproutColors.nightPrimaryInk : SproutColors.forestGreen,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (!isDiscoveryMode)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _selectedQuickFilter = null;
                            _selectedMaxTime = null;
                            _selectedCuisines.clear();
                            _selectedDiet = null;
                            _selectedMaxCalories = null;
                            _includedIngredients.clear();
                            _excludedIngredients.clear();
                          });
                          _performSearch();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'Clear Filters',
                          style: SproutTypography.smallBold(
                            color: isDark ? SproutColors.nightAccent : SproutColors.forestGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content: Skeleton loading, Empty state, or Recipe 2-column grid
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const SproutRecipeCardSkeleton(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: SproutEmptyState(
                  imageAsset: SproutAssets.emptySearch,
                  title: 'No recipes found',
                  subtitle: 'Try searching for something else or clearing your filters.',
                  actionLabel: 'Reset Search',
                  onAction: () {
                    _searchController.clear();
                    setState(() {
                      _selectedMaxTime = null;
                      _selectedCuisines.clear();
                      _selectedDiet = null;
                      _selectedMaxCalories = null;
                      _includedIngredients.clear();
                      _excludedIngredients.clear();
                      _selectedQuickFilter = null;
                    });
                    _performSearch();
                  },
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = _results[index];
                      return SproutGridRecipeCard(
                        recipe: recipe,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                        onFavoriteToggle: () {
                          ref.read(savedRecipesProvider.notifier).toggleFavorite(recipe);
                        },
                      );
                    },
                    childCount: _results.length,
                  ),
                ),
              ),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            SproutColors.sproutGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: SproutSpacing.navClearance + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
