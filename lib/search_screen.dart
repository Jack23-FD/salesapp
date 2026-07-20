import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'screens/scanner/scanner_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/item_details_screen.dart';
import 'providers/notification_provider.dart';
import 'providers/item_provider.dart';
import 'providers/category_provider.dart';
import 'models/item.dart';
import 'main.dart'; // Import main.dart for MainNavigationController
import 'services/localization_service.dart'; // Import localization service

// Define sort option constants
const String kRelevance = 'relevance';
const String kNameAZ = 'name_az';
const String kNameZA = 'name_za';
const String kPriceLowHigh = 'price_low_high';
const String kPriceHighLow = 'price_high_low';
const String kQuantityLowHigh = 'quantity_low_high';
const String kQuantityHighLow = 'quantity_high_low';

// Define availability constants
const String kInStock = 'in_stock';
const String kOutOfStock = 'out_of_stock';

class SearchResult {
  final Item item;
  final String categoryName;

  SearchResult({required this.item, required this.categoryName});
}

class SearchScreen extends StatefulWidget {
  final bool isInMainNavigation;

  const SearchScreen({super.key, this.isInMainNavigation = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = kRelevance; // Use constant instead of translated string
  List<String> _recentSearches = [];
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  Timer? _debounce;
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<String> _filterOptions = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Load recent searches from local storage in a real app
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final hasSearchText = _searchController.text.isNotEmpty;
    final hasFilters = _filterOptions.isNotEmpty;

    setState(() {
      _isSearching = hasSearchText || hasFilters;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    final hasFilters = _filterOptions.isNotEmpty;

    if (searchTerm.isEmpty && !hasFilters) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    // Simulate network delay for demonstration
    Future.delayed(const Duration(milliseconds: 150), () {
      // Add to recent searches if not already there
      if (searchTerm.isNotEmpty && !_recentSearches.contains(searchTerm)) {
        setState(() {
          _recentSearches.insert(0, searchTerm);
          // Keep only the last 8 searches
          if (_recentSearches.length > 8) {
            _recentSearches = _recentSearches.sublist(0, 8);
          }
        });
        // Save to local storage in a real app
      }

      try {
        // Get actual search results from ItemProvider
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        final categoryProvider =
            Provider.of<CategoryProvider>(context, listen: false);

        final results = <SearchResult>[];

        // Search through all categories and items
        for (final categoryId in itemProvider.getAllCategoryIds()) {
          final items = itemProvider.getItemsForCategory(categoryId);
          final category = categoryProvider.getCategoryById(categoryId);
          final categoryName = category?.name ?? 'Unknown Category';

          // Filter items that match the search term with optimized search
          final List<Item> matchingItems;
          if (searchTerm.isEmpty) {
            matchingItems = items; // If search query is empty, pass all items to be filtered by selected chips
          } else if (categoryName.toLowerCase().contains(searchTerm)) {
            matchingItems = items; // Include all items in the category if category matches
          } else {
            matchingItems = _optimizedSearch(items, searchTerm);
          }

          // Add matching items to search results
          for (final item in matchingItems) {
            results.add(SearchResult(
              item: item,
              categoryName: categoryName,
            ));
          }
        }

        // Apply filters if any are selected
        final filteredResults = _filterResults(results);

        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
          // Sort results based on selected sort option
          _sortSearchResults();
        });
      } catch (e) {
        // Handle any errors
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        debugPrint('Error performing search: $e');
      }
    });
  }

  List<Item> _optimizedSearch(List<Item> items, String searchTerm) {
    // Optimization: Create a map for O(1) lookups for exact matches
    final exactMatches = <Item>{};
    final startsWithMatches = <Item>{};
    final containsMatches = <Item>{};
    final barcodeMatches = <Item>{};

    for (final item in items) {
      final name = item.name.toLowerCase();

      // Exact match has highest priority
      if (name == searchTerm) {
        exactMatches.add(item);
      }
      // Starts with match has second priority
      else if (name.startsWith(searchTerm)) {
        startsWithMatches.add(item);
      }
      // Contains match has third priority
      else if (name.contains(searchTerm)) {
        containsMatches.add(item);
      }
      // Barcode match has fourth priority
      else if (item.barcode != null &&
          item.barcode!.toLowerCase().contains(searchTerm)) {
        barcodeMatches.add(item);
      }
    }

    // Combine all matches in priority order
    final result = <Item>[];
    result.addAll(exactMatches);
    result.addAll(startsWithMatches);
    result.addAll(containsMatches);
    result.addAll(barcodeMatches);

    return result;
  }

  List<SearchResult> _filterResults(List<SearchResult> results) {
    if (_filterOptions.isEmpty) return results;

    return results.where((result) {
      // Check category filters
      final categoryFilters =
          _filterOptions.where((f) => !f.startsWith('Availability:')).toList();
      final availabilityFilters = _filterOptions
          .where((f) => f.startsWith('Availability:'))
          .map((f) => f.replaceFirst('Availability: ', ''))
          .toList();

      bool passesCategory = true;
      bool passesAvailability = true;

      // Apply category filters if any are selected
      if (categoryFilters.isNotEmpty) {
        passesCategory = categoryFilters.contains(result.categoryName);
      }

      // Apply availability filters if any are selected
      if (availabilityFilters.isNotEmpty) {
        if (availabilityFilters.contains('In Stock')) {
          passesAvailability = result.item.quantity > 0;
        } else if (availabilityFilters.contains('Out of Stock')) {
          passesAvailability = result.item.quantity <= 0;
        } else if (availabilityFilters.contains('In Stock') &&
            availabilityFilters.contains('Out of Stock')) {
          passesAvailability = true; // Both selected means show all
        }
      }

      return passesCategory && passesAvailability;
    }).toList();
  }

  void _sortSearchResults() {
    // Update to use constants instead of translated strings
    switch (_sortBy) {
      case kNameAZ:
        _searchResults.sort((a, b) => a.item.name.compareTo(b.item.name));
        break;
      case kNameZA:
        _searchResults.sort((a, b) => b.item.name.compareTo(a.item.name));
        break;
      case kPriceLowHigh:
        _searchResults.sort((a, b) => a.item.price.compareTo(b.item.price));
        break;
      case kPriceHighLow:
        _searchResults.sort((a, b) => b.item.price.compareTo(a.item.price));
        break;
      case kQuantityLowHigh:
        _searchResults.sort((a, b) => a.item.quantity.compareTo(b.item.quantity));
        break;
      case kQuantityHighLow:
        _searchResults.sort((a, b) => b.item.quantity.compareTo(a.item.quantity));
        break;
      case kRelevance:
      default:
        // Relevance is already handled by our optimized search function
        break;
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches = [];
      // Clear from local storage in a real app
    });
  }

  void _showAdvancedSearch() {
    final List<String> selectedCategories = [
      ..._filterOptions.where((f) => !f.startsWith('Availability:'))
    ];
    final List<String> selectedAvailability = [
      ..._filterOptions
          .where((f) => f.startsWith('Availability:'))
          .map((f) => f.replaceFirst('Availability: ', ''))
    ];

    // Load actual categories from CategoryProvider
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final List<String> availableCategories = categoryProvider.categories.map((c) => c.name).toList();
    if (availableCategories.isEmpty) {
      availableCategories.addAll(['Food', 'Smarty']); // Fallback
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LocalizationService.translate('search.advancedSearch'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            LocalizationService.translate('search.filters'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Price Range Slider
                          Text(LocalizationService.translate('search.priceRange')),
                          RangeSlider(
                            values: const RangeValues(0, 100),
                            min: 0,
                            max: 100,
                            divisions: 10,
                            labels: const RangeLabels('\$0', '\$100'),
                            onChanged: (RangeValues values) {
                              // Update price range
                            },
                          ),

                          const SizedBox(height: 16),

                          // Category Filter
                          Text(LocalizationService.translate('search.categories')),
                          Wrap(
                            spacing: 8,
                            children: availableCategories
                                .map((category) => FilterChip(
                                      label: Text(category),
                                      selected:
                                          selectedCategories.contains(category),
                                      onSelected: (selected) {
                                        // Toggle category filter
                                        setModalState(() {
                                          if (selected) {
                                            selectedCategories.add(category);
                                          } else {
                                            selectedCategories.remove(category);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 16),

                          // Availability Filter
                          Text(LocalizationService.translate('search.availability')),
                          Wrap(
                            spacing: 8,
                            children: [
                              LocalizationService.translate('search.inStock'), 
                              LocalizationService.translate('search.outOfStock')
                            ]
                                .map((status) => FilterChip(
                                      label: Text(status),
                                      selected:
                                          selectedAvailability.contains(status),
                                      onSelected: (selected) {
                                        // Toggle availability filter
                                        setModalState(() {
                                          if (selected) {
                                            selectedAvailability.add(status);
                                          } else {
                                            selectedAvailability.remove(status);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(LocalizationService.translate('search.cancel')),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF333366),
                                  ),
                                  onPressed: () {
                                    // Apply filters
                                    setState(() {
                                      _filterOptions.clear();
                                      // Add selected categories
                                      _filterOptions.addAll(selectedCategories);
                                      // Add selected availability with prefix
                                      for (final status
                                          in selectedAvailability) {
                                        _filterOptions
                                            .add('Availability: $status');
                                      }
                                    });
                                    Navigator.pop(context);
                                    _performSearch();
                                  },
                                  child: Text(LocalizationService.translate('search.apply')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a list of sort options with their display names and values
    final sortOptions = [
      {'display': LocalizationService.translate('search.relevance'), 'value': kRelevance},
      {'display': LocalizationService.translate('search.nameAZ'), 'value': kNameAZ},
      {'display': LocalizationService.translate('search.nameZA'), 'value': kNameZA},
      {'display': LocalizationService.translate('search.priceLowHigh'), 'value': kPriceLowHigh},
      {'display': LocalizationService.translate('search.priceHighLow'), 'value': kPriceHighLow},
      {'display': LocalizationService.translate('search.quantityLowHigh'), 'value': kQuantityLowHigh},
      {'display': LocalizationService.translate('search.quantityHighLow'), 'value': kQuantityHighLow},
    ];

    // Create availability options for filters
    final availabilityOptions = [
      {'display': LocalizationService.translate('search.inStock'), 'value': kInStock},
      {'display': LocalizationService.translate('search.outOfStock'), 'value': kOutOfStock},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          padding: EdgeInsets.zero,
          onPressed: () {
            if (widget.isInMainNavigation) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigationController(),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.only(left: 4, right: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(22.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: _animation.value * 2,
                      blurRadius: _animation.value * 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 14),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: LocalizationService.translate('search.searchPlaceholder'),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          isDense: true,
                          alignLabelWithHint: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 40, minHeight: 36),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: Icon(Icons.search,
                                color: const Color(0xFF333366), size: 20),
                          ),
                          suffixIconConstraints:
                              const BoxConstraints(minWidth: 40, minHeight: 36),
                          suffixIcon: _isSearching
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey, size: 20),
                                    onPressed: _clearSearch,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner,
                color: Colors.black, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Advanced search and sort by
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _showAdvancedSearch,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF333366).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: const Color(0xFF333366).withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          LocalizationService.translate('search.filters'),
                          style: const TextStyle(
                            color: Color(0xFF333366),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      LocalizationService.translate('search.sortBy'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sortBy,
                      isDense: true,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF333366), size: 18),
                      items: sortOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'] as String,
                          child: Text(
                            option['display'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333366),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _sortBy = newValue;
                            if (_searchResults.isNotEmpty) {
                              _sortSearchResults();
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_filterOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filterOptions.map((filter) {
                  return Chip(
                    backgroundColor: const Color(0xFF333366).withOpacity(0.1),
                    label: Text(
                      filter,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333366),
                      ),
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF333366),
                    ),
                    onDeleted: () {
                      // Remove filter
                      setState(() {
                        _filterOptions.remove(filter);
                        _performSearch();
                      });
                    },
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1),

          // Content area - search results, loading or recent searches
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _isSearching && _searchResults.isNotEmpty
                    ? _buildSearchResults()
                    : _isSearching && _searchResults.isEmpty
                        ? _buildEmptyState(LocalizationService.translate('search.noResultsFound'))
                        : _buildRecentSearches(),
          ),
        ],
      ),
      // Only show bottom navigation bar if not in main navigation
      bottomNavigationBar: widget.isInMainNavigation
          ? null
          : BottomNavigationBar(
              currentIndex: 2, // Search tab is active
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF333366),
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard),
                  label: LocalizationService.translate('navigation.dashboard'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.compare_arrows),
                  label: LocalizationService.translate('navigation.stock'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search),
                  label: LocalizationService.translate('navigation.search'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.category),
                  label: LocalizationService.translate('navigation.categories'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.menu),
                  label: LocalizationService.translate('navigation.menu'),
                ),
              ],
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationController(),
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF333366)),
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.translate('search.searching'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocalizationService.translate('search.recentSearches'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: _clearRecentSearches,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    LocalizationService.translate('search.clearAll'),
                    style: const TextStyle(
                      color: Color(0xFF333366),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Recent search items or empty state
        Expanded(
          child: _recentSearches.isEmpty
              ? _buildEmptyState(LocalizationService.translate('search.noRecentSearches'))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () {
                          _searchController.text = _recentSearches[index];
                          _performSearch();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _recentSearches[index],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.north_west, size: 16),
                                color: Colors.grey,
                                splashRadius: 20,
                                onPressed: () {
                                  _searchController.text =
                                      _recentSearches[index];
                                  _performSearch();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                color: Colors.grey,
                                splashRadius: 20,
                                onPressed: () {
                                  setState(() {
                                    _recentSearches.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            '${LocalizationService.translate('search.resultsFor')} "${_searchController.text}" (${_searchResults.length} ${LocalizationService.translate('search.items')})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              final searchTerm = _searchController.text.toLowerCase();

              // Get spans for highlighting search term
              final spans = _getHighlightedText(result.item.name, searchTerm);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    // Navigate to item detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsScreen(item: result.item),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333366).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Color(0xFF333366),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: spans,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    result.categoryName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: result.item.quantity > 0
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      result.item.quantity > 0
                                          ? '${LocalizationService.translate('search.inStock')}${result.item.quantity} ${result.item.unit}'
                                          : LocalizationService.translate('search.outOfStock'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: result.item.quantity > 0
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\€${result.item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333366),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<TextSpan> _getHighlightedText(String text, String searchTerm) {
    if (searchTerm.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowercaseText = text.toLowerCase();
    final lowercaseSearchTerm = searchTerm.toLowerCase();

    int start = 0;
    int indexOfMatch;

    while (true) {
      indexOfMatch = lowercaseText.indexOf(lowercaseSearchTerm, start);
      if (indexOfMatch < 0) {
        // No more matches
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (indexOfMatch > start) {
        // Add text before match
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + searchTerm.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFFFEFC6),
          fontWeight: FontWeight.bold,
        ),
      ));

      // Move start to end of match
      start = indexOfMatch + searchTerm.length;
    }

    return spans;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.history,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_isSearching) ...[
            const SizedBox(height: 8),
            Text(
              LocalizationService.translate('search.tryDifferentSearch'),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
