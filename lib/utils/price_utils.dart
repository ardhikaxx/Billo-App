class PriceUtils {
  static double? parsePrice(String priceString) {
    if (priceString.isEmpty) return null;
    
    // Remove currency symbols and extra characters
    String cleaned = priceString
        .replaceAll(RegExp(r'[Rr][Pp]\s*'), '')
        .replaceAll(RegExp(r'[Ii][Dd][Rr]\s*'), '')
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .trim();
    
    if (cleaned.isEmpty) return null;
    
    // Handle different decimal/thousands separators
    bool hasComma = cleaned.contains(',');
    bool hasDot = cleaned.contains('.');
    
    if (hasComma && hasDot) {
      // If both exist, comma is likely thousands, dot is decimal
      // Or vice versa depending on position
      int lastComma = cleaned.lastIndexOf(',');
      int lastDot = cleaned.lastIndexOf('.');
      
      if (lastComma > lastDot) {
        // Comma is last, likely decimal (e.g., 10.000,50)
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Dot is last, likely decimal (e.g., 10,000.50)
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (hasComma) {
      // Only comma - check if it's thousands or decimal
      List<String> commaParts = cleaned.split(',');
      if (commaParts.length == 2 && commaParts[1].length == 3) {
        // Likely thousands (e.g., 40,000)
        cleaned = cleaned.replaceAll(',', '');
      } else if (commaParts.length == 2 && commaParts[1].length <= 2) {
        // Likely decimal (e.g., 40,00 or 40,5)
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // Multiple commas, likely thousands separators
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (hasDot) {
      List<String> dotParts = cleaned.split('.');
      if (dotParts.length > 2) {
        cleaned = cleaned.replaceAll('.', '');
      } else if (dotParts.length == 2 && dotParts[1].length <= 2) {
      } else if (dotParts.length == 2 && dotParts[1].length > 2) {
        cleaned = cleaned.replaceAll('.', '');
      }
    }
    
    try {
      return double.tryParse(cleaned);
    } catch (e) {
      print('Error parsing price: $priceString -> $cleaned');
      return null;
    }
  }
  
  static String formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
    String result = '';
    
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      result = priceStr[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = '.$result';
        count = 0;
      }
    }
    
    return 'Rp$result';
  }
  
  static bool isPriceString(String text) {
    String trimmed = text.trim();
    RegExp pricePattern = RegExp(
      r'^(Rp\s*)?\d{1,3}([.,]\d{3})*([.,]\d{2})?$|'
      r'^\d{1,3}([.,]\d{3})*([.,]\d{2})?\s*(Rp)?$'
    );
    return pricePattern.hasMatch(trimmed);
  }
  
  static bool containsPricePattern(String text) {
    RegExp pricePattern = RegExp(r'(\d{1,3}([.,]\d{3})+)');
    return pricePattern.hasMatch(text);
  }
}