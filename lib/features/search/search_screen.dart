import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/colors.dart';
import '../../design/components/sprout_empty_state.dart';
import '../../design/components/sprout_filter_chip.dart';
import '../../design/components/sprout_grid_recipe_card.dart';
import '../../design/components/sprout_scaffold.dart';
import '../../design/components/sprout_search_bar.dart';
import '../../design/radii.dart';
import '../../design/spacing.dart';
import '../../design/sprout_assets.dart';
import '../../design/typography.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../recipes/recipe_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chipsScrollController = ScrollController();

  Timer? _debounce;
  List<Recipe> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Quick Category Filters (moved from Home screen)
  String? _selectedQuickFilter;
  final List<Map<String, String>> _quickFilters = const [
    {'label': 'All', 'emoji': '✨'},
    {'label': 'Quick', 'emoji': '⚡'},
    {'label': 'Healthy', 'emoji': '🌿'},
    {'label': 'Indian', 'emoji': '❤️'},
    {'label': 'Vegetarian', 'emoji': '🥬'},
    {'label': 'High Protein', 'emoji': '💪'},
    {'label': 'Breakfast', 'emoji': '🥞'},
    {'label': 'Comfort Food', 'emoji': '🍲'},
    {'label': 'Desserts', 'emoji': '🍨'},
    {'label': 'Low Calorie', 'emoji': '🥗'},
    {'label': 'Snacks', 'emoji': '🥪'},
  ];

  // Active Filters
  int? _selectedMaxTime;
  String? _selectedCuisine;

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _performSearch();
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _chipsScrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final prefs = ref.read(preferencesProvider);
    final isVegetarianPref = prefs.contains('Vegetarian');
    final isVegFilter = _selectedQuickFilter == 'Vegetarian';
    if (isVegetarianPref || isVegFilter) {
      return ['veg'];
    }
    return null;
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });
    final repo = ref.read(recipeRepositoryProvider);
    final list = await repo.searchRecipes(
      query: _searchController.text,
      maxTime: _selectedMaxTime,
      cuisine: _selectedCuisine,
      diets: _getActiveDiets(),
      page: 0,
      pageSize: _pageSize,
    );
    if (mounted) {
      final sortedList = List<Recipe>.from(list);
      sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      setState(() {
        _results = sortedList;
        _isLoading = false;
        _hasMore = list.length >= _pageSize;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final repo = ref.read(recipeRepositoryProvider);
    final list = await repo.searchRecipes(
      query: _searchController.text,
      maxTime: _selectedMaxTime,
      cuisine: _selectedCuisine,
      diets: _getActiveDiets(),
      page: nextPage,
      pageSize: _pageSize,
    );
    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _results.addAll(list);
        _results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        _isLoadingMore = false;
        _hasMore = list.length >= _pageSize;
      });
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: SproutColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: SproutTypography.h3()),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedMaxTime = null;
                            _selectedCuisine = null;
                          });
                          setState(() {
                            _selectedMaxTime = null;
                            _selectedCuisine = null;
                            _selectedQuickFilter = null;
                          });
                          _performSearch();
                          Navigator.of(ctx).pop();
                        },
                        child: Text('Reset', style: SproutTypography.smallBold()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Cooking Time (Max)', style: SproutTypography.bodyBold()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeOptions.map((time) {
                      final isSel = _selectedMaxTime == time;
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
                            _selectedMaxTime = selected ? time : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Cuisine', style: SproutTypography.bodyBold()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cuisineOptions.map((c) {
                      final isSel = _selectedCuisine == c;
                      return ChoiceChip(
                        label: Text(c),
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
                            _selectedCuisine = selected ? c : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SproutColors.sproutGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: SproutRadii.button,
                        ),
                      ),
                      onPressed: () {
                        setState(() {});
                        _performSearch();
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        'Apply Filters',
                        style: SproutTypography.bodyBold(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedMaxTime != null || _selectedCuisine != null;
    final headerHeight = hasActiveFilters ? 162.0 : 120.0;

    return SproutScaffold(
      body: SafeArea(
        bottom: false, // let content scroll beneath the glass nav bar
        child: RefreshIndicator(
          color: SproutColors.sproutGreen,
          backgroundColor: SproutColors.surface,
          onRefresh: _performSearch,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Pinned Sticky Header: Search bar + quick category filter pills
              SliverAppBar(
                floating: false,
                snap: false,
                pinned: true,
                primary: false,
                automaticallyImplyLeading: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: SproutColors.canvas,
                toolbarHeight: headerHeight,
                titleSpacing: 0,
                title: SizedBox(
                  height: headerHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Input Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: SproutSearchBar(
                          controller: _searchController,
                          onChanged: _onQueryChanged,
                          onFilterTap: _showFilterSheet,
                          onClear: () {
                            setState(() {
                              _selectedQuickFilter = null;
                            });
                            _performSearch();
                          },
                        ),
                      ),

                      // Quick Category Filters (Placed in Explore Screen)
                      SizedBox(
                        height: 38,
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
                                    _selectedCuisine = null;
                                    _searchController.clear();
                                  } else if (isSel) {
                                    _selectedQuickFilter = null;
                                    if (label == 'Quick') {
                                      _selectedMaxTime = null;
                                    } else if (label == 'Indian') {
                                      _selectedCuisine = null;
                                    } else if (label == 'Vegetarian') {
                                      // cleared via _selectedQuickFilter
                                    } else {
                                      _searchController.clear();
                                    }
                                  } else {
                                    _selectedQuickFilter = label;
                                    if (label == 'Quick') {
                                      _selectedMaxTime = 30;
                                    } else if (label == 'Indian') {
                                      _selectedCuisine = 'Indian';
                                    } else if (label == 'Vegetarian') {
                                      // handled automatically by _getActiveDiets()
                                    } else {
                                      _searchController.text = label;
                                    }
                                  }
                                });
                                _performSearch();
                              },
                            );
                          },
                        ),
                      ),

                      // Active Filters indicator if any
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              if (_selectedMaxTime != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text('≤ $_selectedMaxTime min'),
                                    onDeleted: () {
                                      setState(() => _selectedMaxTime = null);
                                      _performSearch();
                                    },
                                  ),
                                ),
                              if (_selectedCuisine != null)
                                Chip(
                                  label: Text(_selectedCuisine!),
                                  onDeleted: () {
                                    setState(() => _selectedCuisine = null);
                                    _performSearch();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Scrollable Section Header: "Explore recipes" & "See all >"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Explore recipes',
                        style: SproutTypography.h2().copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: SproutColors.primaryInk,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _selectedQuickFilter = null;
                            _selectedMaxTime = null;
                            _selectedCuisine = null;
                          });
                          _performSearch();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See all',
                              style: SproutTypography.small().copyWith(
                                color: SproutColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: SproutColors.muted,
                            ),
                          ],
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
                      crossAxisSpacing: 14.0,
                      mainAxisSpacing: 22.0,
                      childAspectRatio: 0.71,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const SproutGridRecipeCardSkeleton(),
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
                    subtitle:
                        'Try searching for something else or clearing your filters.',
                    actionLabel: 'Reset Search',
                    onAction: () {
                      _searchController.clear();
                      setState(() {
                        _selectedMaxTime = null;
                        _selectedCuisine = null;
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
                      crossAxisSpacing: 14.0,
                      mainAxisSpacing: 22.0,
                      childAspectRatio: 0.71,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recipe = _results[index];
                        return SproutGridRecipeCard(
                          recipe: recipe,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                          onFavoriteToggle: () {
                            ref
                                .read(savedRecipesProvider.notifier)
                                .toggleFavorite(recipe);
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
                    height: SproutSpacing.navClearance +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
