import 'package:billo_app/models/bill_model.dart';
import 'package:billo_app/utils/price_utils.dart';

class ReceiptParser {
  static List<BillItem> parseReceiptText(String text) {
    List<BillItem> items = [];

    print('=== RECEIPT PARSER START ===');
    print('Raw text length: ${text.length}');
    print('First 500 chars: ${text.substring(0, text.length > 500 ? 500 : text.length)}');

    // Normalize text
    String normalizedText = text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();

    List<String> lines = normalizedText.split('\n');

    print('Total lines: ${lines.length}');

    // Phase 1: Try structured parsing
    items = _structuredParse(lines);

    print('After structured parsing: ${items.length} items');

    // Phase 2: If no items found, try line-by-line parsing
    if (items.isEmpty) {
      items = _lineByLineParse(lines);
      print('After line-by-line parsing: ${items.length} items');
    }

    // Phase 3: If still no items, try aggressive parsing
    if (items.isEmpty) {
      items = _aggressiveParse(lines);
      print('After aggressive parsing: ${items.length} items');
    }

    // Validate items
    items = items.where((item) => _validateItem(item)).toList();

    print('=== RECEIPT PARSER END === Found ${items.length} items');
    
    // Debug: Print all parsed items
    for (var item in items) {
      print('Item: "${item.name}" x${item.quantity} @${item.pricePerUnit} = ${item.totalPrice}');
    }

    return items;
  }

  static List<BillItem> _structuredParse(List<String> lines) {
    List<BillItem> items = [];

    int itemSectionStart = -1;
    int itemSectionEnd = lines.length;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      String lowerLine = line.toLowerCase();

      // Look for section markers or start of items
      if (line.contains('---') ||
          line.contains('===') ||
          line.contains('___') ||
          _looksLikeItemLine(line)) {
        if (itemSectionStart == -1 && i < lines.length - 1) {
          // Check if this line or next lines are items
          for (int j = i; j < lines.length; j++) {
            if (_looksLikeItemLine(lines[j])) {
              itemSectionStart = j;
              break;
            }
          }
        }
      }

      // Look for end markers
      if (itemSectionStart != -1 && i > itemSectionStart) {
        if (lowerLine.contains('subtotal') ||
            lowerLine.contains('total') ||
            lowerLine.contains('tunai') ||
            lowerLine.contains('bayar') ||
            lowerLine.contains('kembalian') ||
            lowerLine.contains('produk')) {
          itemSectionEnd = i;
          break;
        }
      }
    }

    if (itemSectionStart != -1) {
      print('Item section found: lines $itemSectionStart to $itemSectionEnd');
      for (int i = itemSectionStart; i < itemSectionEnd; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;
        
        BillItem? item = _parseItemLine(line);
        if (item != null) {
          items.add(item);
          print('Parsed from structured: "${item.name}"');
        }
      }
    }

    return items;
  }

  static List<BillItem> _lineByLineParse(List<String> lines) {
    List<BillItem> items = [];

    for (String line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      BillItem? item = _parseItemLine(trimmedLine);
      if (item != null) {
        items.add(item);
        print('Parsed from line-by-line: "${item.name}"');
      }
    }

    return items;
  }

  static List<BillItem> _aggressiveParse(List<String> lines) {
    List<BillItem> items = [];

    for (String line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      String lowerLine = trimmedLine.toLowerCase();
      // Skip obvious non-item lines
      if (lowerLine.contains('waktu') ||
          lowerLine.contains('kasir') ||
          lowerLine.contains('terima') ||
          lowerLine.contains('terimakasih') ||
          lowerLine.contains('terbayar') ||
          lowerLine.contains('dicetak') ||
          lowerLine.contains('subtotal') ||
          lowerLine.contains('total') ||
          lowerLine.contains('tunai') ||
          lowerLine.contains('bayar') ||
          lowerLine.contains('kembalian')) {
        continue;
      }

      // Look for any price pattern
      if (PriceUtils.containsPricePattern(trimmedLine)) {
        BillItem? item = _tryAllParsingPatterns(trimmedLine);
        if (item != null) {
          items.add(item);
          print('Parsed from aggressive: "${item.name}"');
        }
      }
    }

    return items;
  }

  static bool _looksLikeItemLine(String line) {
    String lowerLine = line.toLowerCase();

    List<String> excludePatterns = [
      'waktu',
      'kasir',
      'subtotal',
      'total',
      'tunai',
      'bayar',
      'kembalian',
      'terima',
      'terimakasih',
      'terbayar',
      'dicetak',
      'cetak',
      'print',
      'harga',
      'termasuk',
      'ppm',
      'ppn',
      'pajak',
      'jumlah',
      'produk',
      'item',
      'barang',
      'nama',
      'qty',
      'harga satuan',
      'diskon',
      'discount',
      'promo',
      'voucher',
      'member',
      'kembali',
      'uang',
    ];

    for (var pattern in excludePatterns) {
      if (lowerLine.contains(pattern)) {
        return false;
      }
    }

    // Harus mengandung angka (quantity atau price)
    bool hasNumbers = RegExp(r'\d').hasMatch(line);
    if (!hasNumbers) return false;

    // Harus mengandung price pattern
    bool hasPrice = PriceUtils.containsPricePattern(line);

    return hasPrice && line.length > 3;
  }

  static BillItem? _parseItemLine(String line) {
    // Debug
    print("Trying to parse line: '$line'");
    
    // Clean the line
    String cleanedLine = line
        .replaceAll('Rp', ' ')
        .replaceAll('IDR', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    List<String> parts = cleanedLine.split(' ');

    if (parts.isEmpty) {
      print('No parts found');
      return null;
    }

    print('Parts: $parts');

    // Pattern 1: "4 RABBIT BREAD 40,000" - Quantity first
    try {
      if (parts.length >= 3) {
        int? quantity = int.tryParse(parts[0]);
        print('Pattern 1 - quantity from first part: $quantity');
        
        if (quantity != null && quantity > 0) {
          // Try to get price from last part
          double? totalPrice = _tryParsePriceFromParts(parts, startFromEnd: true);
          print('Pattern 1 - total price: $totalPrice');
          
          if (totalPrice != null && totalPrice > 0) {
            // Item name is everything between quantity and price
            int priceIndex = _findPriceIndex(parts);
            if (priceIndex > 1) { // Pastikan ada nama item
              String itemName = parts.sublist(1, priceIndex).join(' ');
              print('Pattern 1 - item name: "$itemName"');
              
              if (itemName.isNotEmpty) {
                double pricePerUnit = totalPrice / quantity;
                print('Pattern 1 - price per unit: $pricePerUnit');
                
                return BillItem(
                  name: _cleanItemName(itemName),
                  quantity: quantity,
                  pricePerUnit: pricePerUnit,
                  totalPrice: totalPrice,
                  assignedTo: [],
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Pattern 1 error: $e');
    }

    // Pattern 2: "RABBIT BREAD 4 40,000" - Quantity before price
    try {
      if (parts.length >= 3) {
        // Cari quantity dari bagian kedua dari belakang
        for (int i = parts.length - 2; i >= 0; i--) {
          int? quantity = int.tryParse(parts[i]);
          if (quantity != null && quantity > 0) {
            print('Pattern 2 - quantity found at index $i: $quantity');
            
            // Harga seharusnya di bagian terakhir
            double? totalPrice = PriceUtils.parsePrice(parts.last);
            print('Pattern 2 - total price: $totalPrice');
            
            if (totalPrice != null && totalPrice > 0) {
              // Item name adalah semua bagian sebelum quantity
              String itemName = parts.sublist(0, i).join(' ');
              print('Pattern 2 - item name: "$itemName"');
              
              if (itemName.isNotEmpty) {
                double pricePerUnit = totalPrice / quantity;
                print('Pattern 2 - price per unit: $pricePerUnit');
                
                return BillItem(
                  name: _cleanItemName(itemName),
                  quantity: quantity,
                  pricePerUnit: pricePerUnit,
                  totalPrice: totalPrice,
                  assignedTo: [],
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Pattern 2 error: $e');
    }

    // Pattern 3: "4x RABBIT BREAD 40,000" atau "4 X RABBIT BREAD 40,000"
    try {
      RegExp quantityXPattern = RegExp(r'^(\d+)\s*[xX]\s+(.+?)\s+(\d{1,3}(?:[.,]\d{3})*)$');
      Match? match = quantityXPattern.firstMatch(line);
      
      if (match != null) {
        print('Pattern 3 matched');
        int? quantity = int.tryParse(match.group(1)!);
        String itemName = match.group(2)!.trim();
        double? totalPrice = PriceUtils.parsePrice(match.group(3)!);
        
        if (quantity != null && quantity > 0 && totalPrice != null && totalPrice > 0) {
          double pricePerUnit = totalPrice / quantity;
          
          return BillItem(
            name: _cleanItemName(itemName),
            quantity: quantity,
            pricePerUnit: pricePerUnit,
            totalPrice: totalPrice,
            assignedTo: [],
          );
        }
      }
    } catch (e) {
      print('Pattern 3 error: $e');
    }

    // Pattern 4: "RABBIT BREAD 40,000" (assume quantity = 1)
    try {
      if (parts.length >= 2) {
        // Cari harga di bagian mana saja
        for (int i = parts.length - 1; i >= 0; i--) {
          double? price = PriceUtils.parsePrice(parts[i]);
          if (price != null && price > 0) {
            print('Pattern 4 - price found at index $i: $price');
            
            // Item name adalah semua bagian kecuali harga
            List<String> nameParts = List.from(parts);
            nameParts.removeAt(i);
            String itemName = nameParts.join(' ');
            print('Pattern 4 - item name: "$itemName"');
            
            if (itemName.isNotEmpty) {
              return BillItem(
                name: _cleanItemName(itemName),
                quantity: 1,
                pricePerUnit: price,
                totalPrice: price,
                assignedTo: [],
              );
            }
          }
        }
      }
    } catch (e) {
      print('Pattern 4 error: $e');
    }

    print('No pattern matched for line: "$line"');
    return null;
  }

  static double? _tryParsePriceFromParts(List<String> parts, {bool startFromEnd = true}) {
    if (startFromEnd) {
      // Coba dari belakang
      for (int i = parts.length - 1; i >= 0; i--) {
        double? price = PriceUtils.parsePrice(parts[i]);
        if (price != null && price > 0) {
          return price;
        }
      }
    } else {
      // Coba dari depan
      for (int i = 0; i < parts.length; i++) {
        double? price = PriceUtils.parsePrice(parts[i]);
        if (price != null && price > 0) {
          return price;
        }
      }
    }
    return null;
  }

  static int _findPriceIndex(List<String> parts) {
    // Cari index bagian yang berisi harga
    for (int i = parts.length - 1; i >= 0; i--) {
      if (PriceUtils.parsePrice(parts[i]) != null) {
        return i;
      }
    }
    return -1;
  }

  static BillItem? _tryAllParsingPatterns(String line) {
    print('Trying aggressive patterns on: "$line"');
    
    // Ekstrak semua angka dari line
    RegExp numberPattern = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d+');
    List<Match> numberMatches = numberPattern.allMatches(line).toList();
    
    print('Found ${numberMatches.length} number matches');
    
    if (numberMatches.length >= 1) {
      // Coba interpretasikan angka-angka
      List<double> numbers = [];
      for (Match match in numberMatches) {
        double? num = PriceUtils.parsePrice(match.group(0)!);
        if (num != null) {
          numbers.add(num);
          print('Number: $num (${match.group(0)})');
        }
      }
      
      if (numbers.isNotEmpty) {
        // Angka terakhir biasanya total harga
        double totalPrice = numbers.last;
        
        // Cari quantity (biasanya angka pertama yang kecil)
        int quantity = 1;
        double pricePerUnit = totalPrice;
        
        if (numbers.length >= 2) {
          // Coba angka pertama sebagai quantity jika kecil (< 100)
          if (numbers[0] < 100 && numbers[0].round() == numbers[0]) {
            quantity = numbers[0].toInt();
            pricePerUnit = numbers.length >= 3 ? numbers[1] : totalPrice / quantity;
          } else if (numbers.length >= 3 && numbers[1] < 100 && numbers[1].round() == numbers[1]) {
            // Atau angka kedua sebagai quantity
            quantity = numbers[1].toInt();
            pricePerUnit = numbers[0];
          }
        }
        
        String itemName = line;
        for (Match match in numberMatches.reversed) {
          itemName = itemName.replaceFirst(match.group(0)!, ' ');
        }
        itemName = itemName
            .replaceAll(RegExp(r'[^\w\s]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        print('Aggressive parse - name: "$itemName", qty: $quantity, price/unit: $pricePerUnit, total: $totalPrice');
        
        if (itemName.isNotEmpty && quantity > 0 && pricePerUnit > 0) {
          return BillItem(
            name: _cleanItemName(itemName),
            quantity: quantity,
            pricePerUnit: pricePerUnit,
            totalPrice: totalPrice,
            assignedTo: [],
          );
        }
      }
    }
    
    return null;
  }

  static String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _validateItem(BillItem item) {
    if (item.name.isEmpty) {
      print('Validation failed: empty name');
      return false;
    }
    if (item.quantity <= 0) {
      print('Validation failed: invalid quantity ${item.quantity}');
      return false;
    }
    if (item.pricePerUnit <= 0) {
      print('Validation failed: invalid price per unit ${item.pricePerUnit}');
      return false;
    }
    if (item.totalPrice <= 0) {
      print('Validation failed: invalid total price ${item.totalPrice}');
      return false;
    }

    double expectedTotal = item.quantity * item.pricePerUnit;
    double tolerance = 0.15;
    double difference = (item.totalPrice - expectedTotal).abs();
    double ratio = difference / expectedTotal;
    
    if (ratio > tolerance) {
      print('Validation failed: price mismatch. Expected: $expectedTotal, Actual: ${item.totalPrice}, Ratio: $ratio');
      return false;
    }

    return true;
  }
}