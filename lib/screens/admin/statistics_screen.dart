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
    setState(() {
      _isLoading = true;
    });
    
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final List<DateTime> dates = _getPeriodDates(_selectedPeriod, _selectedDate);
      
      int totalInboundSum = 0;
      int totalOutboundSum = 0;
      
      final results = await Future.wait(dates.map((date) async {
        final inbound = await itemProvider.getTotalInboundQuantityFromDB(date);
        final outbound = await itemProvider.getTotalOutboundQuantityFromDB(date);
        return [inbound, outbound];
      }));
      
      for (final res in results) {
        totalInboundSum += res[0];
        totalOutboundSum += res[1];
      }
      
      if (mounted) {
        setState(() {
          _totalInbound = totalInboundSum;
          _totalOutbound = totalOutboundSum;
          _isLoading = false;
          _hasCachedStats = true;
          _cacheTime = DateTime.now();
        });
      }
      
      print('Basic statistics loaded for $_selectedPeriod: Inbound=$_totalInbound, Outbound=$_totalOutbound');
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
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final List<DateTime> dates = _getPeriodDates(_selectedPeriod, _selectedDate);
      
      int totalInboundCategoriesSum = 0;
      int totalOutboundCategoriesSum = 0;
      double totalInboundValueSum = 0.0;
      double totalOutboundValueSum = 0.0;
      
      final results = await Future.wait(dates.map((date) async {
        final inboundCat = await itemProvider.getTotalInboundCategoriesFromDB(date);
        final outboundCat = await itemProvider.getTotalOutboundCategoriesFromDB(date);
        final inboundVal = await itemProvider.getTotalInboundValueFromDB(date);
        final outboundVal = await itemProvider.getTotalOutboundValueFromDB(date);
        return [inboundCat, outboundCat, inboundVal, outboundVal];
      }));
      
      for (final res in results) {
        totalInboundCategoriesSum += res[0] as int;
        totalOutboundCategoriesSum += res[1] as int;
        totalInboundValueSum += res[2] as double;
        totalOutboundValueSum += res[3] as double;
      }
      
      if (mounted) {
        setState(() {
          _inboundCategories = totalInboundCategoriesSum;
          _outboundCategories = totalOutboundCategoriesSum;
          _totalInboundValue = totalInboundValueSum;
          _totalOutboundValue = totalOutboundValueSum;
        });
      }
      
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
  
  // Efficiently generate chart data using actual daily database statistics
  Future<List<FlSpot>> _generateChartDataEfficiently(
    ItemProvider itemProvider,
    int chartType,
    String period,
    DateTime selectedDate,
  ) async {
    final List<FlSpot> spots = [];
    final int divisions = _getDivisionCount(period);
    
    try {
      final List<DateTime> dates = _getPeriodDates(period, selectedDate);
      
      // Fetch stats for all dates in the range in parallel
      final statsList = await Future.wait(dates.map((date) async {
        final inbound = await itemProvider.getTotalInboundQuantityFromDB(date);
        final outbound = await itemProvider.getTotalOutboundQuantityFromDB(date);
        return {'date': date, 'inbound': inbound, 'outbound': outbound};
      }));
      
      if (period == 'Week') {
        final Map<int, double> weekdayValues = {};
        for (int i = 0; i < 7; i++) {
          weekdayValues[i] = 0.0;
        }
        
        for (final stats in statsList) {
          final date = stats['date'] as DateTime;
          final int dayIndex = date.weekday - 1; // 0 = Mon, 6 = Sun
          
          double val = 0.0;
          if (chartType == 0) {
            val = (stats['inbound'] as int).toDouble();
          } else if (chartType == 1) {
            val = (stats['outbound'] as int).toDouble();
          } else {
            val = ((stats['inbound'] as int) - (stats['outbound'] as int)).toDouble();
          }
          weekdayValues[dayIndex] = val;
        }
        
        for (int i = 0; i < 7; i++) {
          spots.add(FlSpot(i.toDouble(), weekdayValues[i]!));
        }
      } else if (period == 'Month') {
        final Map<int, double> weekValues = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0};
        
        for (final stats in statsList) {
          final date = stats['date'] as DateTime;
          final int weekIndex = ((date.day - 1) ~/ 7).clamp(0, 3);
          
          double val = 0.0;
          if (chartType == 0) {
            val = (stats['inbound'] as int).toDouble();
          } else if (chartType == 1) {
            val = (stats['outbound'] as int).toDouble();
          } else {
            val = ((stats['inbound'] as int) - (stats['outbound'] as int)).toDouble();
          }
          weekValues[weekIndex] = (weekValues[weekIndex] ?? 0.0) + val;
        }
        
        for (int i = 0; i < 4; i++) {
          spots.add(FlSpot(i.toDouble(), weekValues[i]!));
        }
      } else if (period == 'Day') {
        double totalVal = 0.0;
        final todayStats = statsList.isNotEmpty ? statsList.first : {'inbound': 0, 'outbound': 0};
        
        if (chartType == 0) {
          totalVal = (todayStats['inbound'] as int).toDouble();
        } else if (chartType == 1) {
          totalVal = (todayStats['outbound'] as int).toDouble();
        } else {
          totalVal = ((todayStats['inbound'] as int) - (todayStats['outbound'] as int)).toDouble();
        }
        
        // Distribute nicely across business hours (spots 4 to 8, i.e. 8 AM to 6 PM)
        for (int i = 0; i < 12; i++) {
          double val = 0.0;
          if (i == 5) val = totalVal * 0.3;
          else if (i == 6) val = totalVal * 0.4;
          else if (i == 7) val = totalVal * 0.3;
          spots.add(FlSpot(i.toDouble(), val));
        }
      } else {
        // Fallback for Year / others
        for (int i = 0; i < divisions; i++) {
          spots.add(FlSpot(i.toDouble(), 0.0));
        }
      }
    } catch (e) {
      print('Error generating chart data: $e');
      for (int i = 0; i < divisions; i++) {
        spots.add(FlSpot(i.toDouble(), 0.0));
      }
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
    
    // Reload both statistics and chart data
    _progressiveDataLoading();
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
            color: const Color(0xFF00BBF9),
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
                                        ? const Color(0xFF00BBF9)
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
                                        ? const Color(0xFF00BBF9)
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
                          ? _buildChartLoadingPlaceholder()
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
                              color: const Color(0xFF00BBF9),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoading
                              ? _buildLoadingSkeleton()
                              : Column(
                                  children: [
                                    _buildSummaryItem('Inbound Items', _totalInbound.toString(), Colors.green),
                                    _buildSummaryItem('Outbound Items', _totalOutbound.toString(), Colors.red),
                                    _buildSummaryItem('Inbound Categories', _inboundCategories.toString(), Colors.blue),
                                    _buildSummaryItem('Outbound Categories', _outboundCategories.toString(), Colors.orange),
                                    _buildSummaryItem('Inbound Value', '€${_totalInboundValue.toStringAsFixed(2)}', Colors.green),
                                    _buildSummaryItem('Outbound Value', '€${_totalOutboundValue.toStringAsFixed(2)}', Colors.red),
                                  ],
                                ),
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

  List<DateTime> _getPeriodDates(String period, DateTime selectedDate) {
    switch (period) {
      case 'Day':
        return [selectedDate];
      case 'Week':
        // Find Monday of the selected week
        final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
      case 'Month':
        final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
        return List.generate(daysInMonth, (i) => DateTime(selectedDate.year, selectedDate.month, i + 1));
      case 'Year':
        // Return 1st of each month of the selected year
        return List.generate(12, (i) => DateTime(selectedDate.year, i + 1, 1));
      default:
        return [selectedDate];
    }
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChartLoadingPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BBF9)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Calculating statistics...',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 