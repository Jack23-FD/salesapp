import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/item_provider.dart';
import '../../models/item.dart';
import '../../dashboard/components/date_selector.dart';
import '../../dashboard/components/custom_calendar.dart';
import '../../services/mysql_database_service.dart';
import '../../utils/storage_utils.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Day';
  int _selectedChartIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  bool _isLoading = false;
  bool _isChartLoading = false;
  
  // Statistics from database
  int _totalInbound = 0;
  int _totalOutbound = 0;
  int _inboundCategories = 0;
  int _outboundCategories = 0;
  double _totalInboundValue = 0;
  double _totalOutboundValue = 0;
  
  // Chart data cache
  final Map<String, List<FlSpot>> _chartDataCache = {};
  
  // Add cache variables with more precise control
  bool _hasCachedStats = false;
  DateTime? _cacheTime;
  final _cacheValidDuration = const Duration(minutes: 15);
  
  // Precomputed chart data
  List<FlSpot>? _currentChartData;
  
  final List<String> _timePeriods = ['Day', 'Week', 'Month', 'Year'];
  final List<String> _chartTypes = ['Inbound', 'Outbound', 'Balance'];
  
  final MySqlDatabaseService _dbService = MySqlDatabaseService();

  @override
  void initState() {
    super.initState();
    // Start loading immediately but in a progressive manner
    _progressiveDataLoading();
  }
  
  // Check if cache is valid
  bool get _isCacheValid {
    if (!_hasCachedStats || _cacheTime == null) return false;
    final now = DateTime.now();
    return now.difference(_cacheTime!) < _cacheValidDuration;
  }
  
  // Generate cache key for chart data
  String _getChartCacheKey() {
    return '${_selectedPeriod}_${_selectedChartIndex}_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
  }
  
  // Load data in stages to avoid UI freezing
  Future<void> _progressiveDataLoading() async {
    // First load basic statistics
    await _loadBasicStatistics();
    
    // Then load detailed stats if UI is still mounted
    if (mounted) {
      _loadDetailedStatistics();
    }
    
    // Finally load chart data (most expensive operation)
    if (mounted) {
      _loadChartData();
    }
  }
  
  // Load only the essential statistics first
  Future<void> _loadBasicStatistics() async {
    final cacheKey = 'basic_stats_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
    final cachedData = await StorageUtils.getCachedStringValue(cacheKey);
    
    if (cachedData != null && _isCacheValid) {
      try {
        // Try to parse cached data
        final parts = cachedData.split(',');
        if (parts.length >= 2) {
          setState(() {
            _totalInbound = int.parse(parts[0]);
            _totalOutbound = int.parse(parts[1]);
            _isLoading = false;
          });
          print('Statistics Screen: Using cached basic statistics');
          return;
        }
      } catch (e) {
        print('Error parsing cached data: $e');
      }
    }
  
    setState(() {
      _isLoading = true;
    });
    
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      // Load only essential statistics first
      final futures = await Future.wait([
        itemProvider.getTotalInboundQuantityFromDB(_selectedDate),
        itemProvider.getTotalOutboundQuantityFromDB(_selectedDate),
      ]);
      
      setState(() {
        _totalInbound = int.tryParse(futures[0].toString()) ?? 0;
        _totalOutbound = int.tryParse(futures[1].toString()) ?? 0;
        _isLoading = false;
        _hasCachedStats = true;
        _cacheTime = DateTime.now();
      });
      
      // Cache the basic data
      await StorageUtils.cacheStringValue(
        cacheKey, 
        '$_totalInbound,$_totalOutbound'
      );
      
      print('Basic statistics loaded: Inbound=$_totalInbound, Outbound=$_totalOutbound');
    } catch (e) {
      print('Error loading basic statistics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load statistics. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load the more detailed statistics after basic ones
  Future<void> _loadDetailedStatistics() async {
    final cacheKey = 'detailed_stats_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';
    final cachedData = await StorageUtils.getCachedStringValue(cacheKey);
    
    if (cachedData != null && _isCacheValid) {
      try {
        // Try to parse cached data
        final parts = cachedData.split(',');
        if (parts.length >= 4) {
          setState(() {
            _inboundCategories = int.parse(parts[0]);
            _outboundCategories = int.parse(parts[1]);
            _totalInboundValue = double.parse(parts[2]);
            _totalOutboundValue = double.parse(parts[3]);
          });
          print('Statistics Screen: Using cached detailed statistics');
          return;
        }
      } catch (e) {
        print('Error parsing cached detailed data: $e');
      }
    }
    
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final futures = await Future.wait([
        itemProvider.getTotalInboundCategoriesFromDB(_selectedDate),
        itemProvider.getTotalOutboundCategoriesFromDB(_selectedDate),
        itemProvider.getTotalInboundValueFromDB(_selectedDate),
        itemProvider.getTotalOutboundValueFromDB(_selectedDate),
      ]);
      
      if (mounted) {
        setState(() {
          _inboundCategories = int.tryParse(futures[0].toString()) ?? 0;
          _outboundCategories = int.tryParse(futures[1].toString()) ?? 0;
          _totalInboundValue = double.tryParse(futures[2].toString()) ?? 0.0;
          _totalOutboundValue = double.tryParse(futures[3].toString()) ?? 0.0;
        });
      }
      
      // Cache the detailed data
      await StorageUtils.cacheStringValue(
        cacheKey, 
        '$_inboundCategories,$_outboundCategories,$_totalInboundValue,$_totalOutboundValue'
      );
      
      print('Detailed statistics loaded');
    } catch (e) {
      print('Error loading detailed statistics: $e');
    }
  }
  
  // Load chart data separately and asynchronously
  Future<void> _loadChartData() async {
    if (!mounted) return;
    
    // Only show loading indicator if data isn't already cached
    final cacheKey = _getChartCacheKey();
    if (!_chartDataCache.containsKey(cacheKey)) {
      setState(() {
        _isChartLoading = true;
      });
    }
    
    try {
      // Check if data is cached
      if (_chartDataCache.containsKey(cacheKey)) {
        setState(() {
          _currentChartData = _chartDataCache[cacheKey];
          _isChartLoading = false;
        });
        return;
      }
      
      // Get data from provider in chunks to avoid freezing
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      // Process in the background using compute
      final result = await _generateChartDataEfficiently(
        itemProvider, 
        _selectedChartIndex, 
        _selectedPeriod,
        _selectedDate,
      );
      
      if (mounted) {
        setState(() {
          _currentChartData = result;
          _chartDataCache[cacheKey] = result;
          _isChartLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chart data: $e');
      if (mounted) {
        setState(() {
          _isChartLoading = false;
        });
      }
    }
  }
  
  // Efficiently generate chart data
  Future<List<FlSpot>> _generateChartDataEfficiently(
    ItemProvider itemProvider,
    int chartType,
    String period,
    DateTime selectedDate,
  ) async {
    // For immediate display while real data loads, return empty or placeholder
    if (itemProvider.allItems == null || itemProvider.allItems.isEmpty) {
      return [];
    }
    
    // Get start date based on period
    final DateTime startDate = _getStartDate(period, selectedDate);
    
    // Filter only relevant items first to reduce processing load
    final relevantItems = itemProvider.allItems
        .where((item) => item.createdAt.isAfter(startDate))
        .toList();
    
    // Get division count for the period
    final int divisions = _getDivisionCount(period);
    
    // Process data to spots
    return _processItemsToSpots(relevantItems, chartType, period, divisions);
  }
  
  // Helper for processing items to chart spots
  List<FlSpot> _processItemsToSpots(
    List<Item> items,
    int chartType,
    String period,
    int divisions,
  ) {
    // Initialize result spots
    final List<FlSpot> spots = [];
    
    // Group items by period
    final Map<int, List<Item>> groupedItems = {};
    
    // Initialize all periods with empty lists
    for (int i = 0; i < divisions; i++) {
      groupedItems[i] = [];
    }
    
    // Group items (limit to 500 max to avoid freezing)
    final processingLimit = items.length > 500 ? 500 : items.length;
    for (int i = 0; i < processingLimit; i++) {
      final item = items[i];
      final int index = _getPeriodIndex(item.createdAt, period, divisions);
      if (groupedItems.containsKey(index)) {
        groupedItems[index]!.add(item);
      }
    }
    
    // Calculate data points
    for (int i = 0; i < divisions; i++) {
      final periodItems = groupedItems[i] ?? [];
      
      int value = 0;
      switch (chartType) {
        case 0: // Inbound
          value = periodItems
              .where((item) => item.type == 'inbound')
              .fold(0, (sum, item) => sum + item.quantity);
          break;
        case 1: // Outbound
          value = periodItems
              .where((item) => item.type == 'outbound')
              .fold(0, (sum, item) => sum + item.quantity);
          break;
        case 2: // Balance
          final inbound = periodItems
              .where((item) => item.type == 'inbound')
              .fold(0, (sum, item) => sum + item.quantity);
          final outbound = periodItems
              .where((item) => item.type == 'outbound')
              .fold(0, (sum, item) => sum + item.quantity);
          value = inbound - outbound;
          break;
      }
      
      spots.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    
    return spots;
  }
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _showCalendar = false;
      // Reset data to trigger reload
      _currentChartData = null;
    });
    
    // Reload data in stages
    _progressiveDataLoading();
  }
  
  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      // Clear chart data to trigger reload
      _currentChartData = null;
      _isChartLoading = true;
    });
    
    // Only reload chart data since statistics are date-based
    _loadChartData();
  }
  
  void _onChartTypeChanged(int index) {
    setState(() {
      _selectedChartIndex = index;
      // Clear chart data to trigger reload
      _currentChartData = null;
      _isChartLoading = true;
    });
    
    // Only reload chart data
    _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: const Color(0xFF333366),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _progressiveDataLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector
                    DateSelector(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) => _onDateSelected(date!),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time Period Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: _timePeriods.map((period) {
                          final isSelected = period == _selectedPeriod;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onPeriodChanged(period),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  period,
                                  style: GoogleFonts.urbanist(
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 14.0,
                                    color: isSelected
                                        ? const Color(0xFF333366)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Chart Type Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: _chartTypes.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final String type = entry.value;
                          final isSelected = idx == _selectedChartIndex;
                          
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onChartTypeChanged(idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  type,
                                  style: GoogleFonts.urbanist(
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 14.0,
                                    color: isSelected
                                        ? const Color(0xFF333366)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Chart Container
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isChartLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : (_currentChartData == null || _currentChartData!.isEmpty)
                              ? const Center(
                                  child: Text('No data available for the selected period'),
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: 1,
                                      verticalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[300],
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[300],
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: _getBottomTitleInterval(),
                                          getTitlesWidget: (value, meta) {
                                            return _getBottomTitleWidget(value, meta, _selectedPeriod);
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: null,
                                          reservedSize: 40,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _currentChartData!,
                                        isCurved: true,
                                        color: _getChartColor(),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: _getChartColor().withOpacity(0.2),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                          getTooltipColor: (LineBarSpot touchedSpot) => Colors.grey[800] ?? Colors.black,
                                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            return LineTooltipItem(
                                              '${spot.y.toInt()}',
                                              GoogleFonts.urbanist(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }).toList();
                                        }
                                      ),
                                    ),
                                  ),
                                ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Statistical Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w600,
                              fontSize: 18.0,
                              color: const Color(0xFF333366),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryItem('Inbound Items', _totalInbound.toString(), Colors.green),
                          _buildSummaryItem('Outbound Items', _totalOutbound.toString(), Colors.red),
                          _buildSummaryItem('Inbound Categories', _inboundCategories.toString(), Colors.blue),
                          _buildSummaryItem('Outbound Categories', _outboundCategories.toString(), Colors.orange),
                          _buildSummaryItem('Inbound Value', '€${_totalInboundValue.toStringAsFixed(2)}', Colors.green),
                          _buildSummaryItem('Outbound Value', '€${_totalOutboundValue.toStringAsFixed(2)}', Colors.red),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Loading overlay for initial load only
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 16.0,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  double _getBottomTitleInterval() {
    switch (_selectedPeriod) {
      case 'Day':
        return 4; // Every 4 hours
      case 'Week':
        return 1; // Every day
      case 'Month':
        return 7; // Every week
      case 'Year':
        return 2; // Every 2 months
      default:
        return 1;
    }
  }

  Widget _getBottomTitleWidget(double value, TitleMeta meta, String period) {
    final style = GoogleFonts.urbanist(
      color: Colors.grey[700],
      fontSize: 12,
    );
    
    String text;
    switch (period) {
      case 'Day':
        text = '${value.toInt() * 2}h'; // Every 2 hours
        break;
      case 'Week':
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        text = weekdays[value.toInt() % 7];
        break;
      case 'Month':
        text = 'W${(value + 1).toInt()}'; // Week number
        break;
      case 'Year':
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        text = months[value.toInt() % 12];
        break;
      default:
        text = value.toInt().toString();
    }
    
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Color _getChartColor() {
    switch (_selectedChartIndex) {
      case 0: // Inbound
        return Colors.green;
      case 1: // Outbound
        return Colors.red;
      case 2: // Balance
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  DateTime _getStartDate(String period, DateTime selectedDate) {
    switch (period) {
      case 'Day':
        return DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      case 'Week':
        return selectedDate.subtract(const Duration(days: 7));
      case 'Month':
        return DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day);
      case 'Year':
        return DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day);
      default:
        return selectedDate.subtract(const Duration(days: 7));
    }
  }
  
  int _getDivisionCount(String period) {
    switch (period) {
      case 'Day':
        return 12; // 24 hours / 2
      case 'Week':
        return 7; // 7 days
      case 'Month':
        return 4; // 4 weeks
      case 'Year':
        return 12; // 12 months
      default:
        return 7;
    }
  }

  int _getPeriodIndex(DateTime date, String period, int divisions) {
    final now = DateTime.now();
    
    switch (period) {
      case 'Day':
        // Hours in the day (0-23) divided into groups
        return (date.hour ~/ 2).clamp(0, divisions - 1);
      case 'Week':
        // Day of the week (0-6)
        final difference = now.difference(date).inDays;
        return (6 - difference).clamp(0, divisions - 1);
      case 'Month':
        // Week of the month (0-3)
        final weekOfMonth = (date.day - 1) ~/ 7;
        return weekOfMonth.clamp(0, divisions - 1);
      case 'Year':
        // Month of the year (0-11)
        return (date.month - 1).clamp(0, divisions - 1);
      default:
        return 0;
    }
  }
} 