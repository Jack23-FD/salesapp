import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/translation_utils.dart';
import '../../services/localization_service.dart';

class OutboundCard extends StatelessWidget {
  final int quantity;
  final int categories;
  final double value;
  final bool isExpanded;
  final VoidCallback onTap;

  const OutboundCard({
    Key? key,
    required this.quantity,
    required this.categories,
    required this.value,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current locale to force rebuild when language changes
    final locale = Provider.of<LocalizationProvider>(context).locale;
    
    // Calculate text scaling factor for potentially long translations
    final String removedStock = 'dashboard.removedStock'.translate();
    final String units = 'dashboard.units'.translate();
    final double titleFontSize = _calculateFontSize(removedStock, 16.0);
    
    // Log translation for debugging
    print("OutboundCard: Translating 'dashboard.removedStock' = '$removedStock' (locale: ${locale.languageCode})");
    
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          removedStock,
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.w600,
                            fontSize: titleFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$quantity $units',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.w500,
                            fontSize: _calculateFontSize('$quantity $units', 15.0),
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${removedStock} (${'dashboard.outgoingInventory'.translate()})',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w700,
                        fontSize: _calculateFontSize('${removedStock} (${'dashboard.outgoingInventory'.translate()})', 16.0),
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('dashboard.outgoingItems'.translate(), '$quantity $units', true),
                    const SizedBox(height: 6),
                    _buildInfoRow('dashboard.totalCategories'.translate(), '$categories'),
                    const SizedBox(height: 6),
                    _buildInfoRow('dashboard.totalValue'.translate(), '€${value.toStringAsFixed(2)}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [bool highlight = false]) {
    final double labelFontSize = _calculateFontSize(label, highlight ? 15.0 : 14.0);
    final double valueFontSize = _calculateFontSize(value, highlight ? 15.0 : 14.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: highlight ? Colors.red.withOpacity(0.1) : null,
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.urbanist(
                textStyle: TextStyle(
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                  fontSize: labelFontSize,
                  color: Colors.black,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: GoogleFonts.urbanist(
                textStyle: TextStyle(
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                  fontSize: valueFontSize,
                  color: highlight ? Colors.red[700] : Colors.black,
                ),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to calculate font size based on text length
  double _calculateFontSize(String text, double baseSize) {
    // Keep original font size for English language
    if (LocalizationService.currentLocale.languageCode == 'en') {
      return baseSize;
    }
    
    // Adjust font size for other languages based on text length
    if (text.length <= 15) {
      return baseSize;
    } else if (text.length <= 25) {
      return baseSize - 1.0;
    } else if (text.length <= 35) {
      return baseSize - 2.0;
    } else {
      return baseSize - 3.0;
    }
  }
}
