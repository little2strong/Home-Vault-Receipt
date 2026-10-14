import '../models/enums.dart';
import '../models/item.dart';
import '../utils/dates.dart';
import '../utils/receipt_date_parser.dart';
import 'ocr_document.dart';

class ParsedItem {
  const ParsedItem({
    required this.name,
    required this.rawText,
    required this.lineTotalMinor,
    this.quantity = 1,
    this.unitPriceMinor,
    this.category = Category.other,
    this.box,
  });

  final String name;

  /// The wording exactly as printed, e.g. `SAMSUNG 55 QLED TV`.
  final String rawText;
  final int quantity;
  final int? unitPriceMinor;
  final int lineTotalMinor;
  final Category category;
  final LineBox? box;
}

/// What the parser proposes. Every field may be null: an unknown stays
/// "Not stated" until the user fills it in.
class ParsedReceipt {
  const ParsedReceipt({
    this.shop,
    this.purchaseDate,
    this.dateAmbiguous = false,
    this.currency,
    this.totalMinor,
    this.taxMinor,
    this.orderNumber,
    this.returnWording,
    this.returnDays,
    this.returnDate,
    this.items = const [],
  });

  final String? shop;
  final DateTime? purchaseDate;
  final bool dateAmbiguous;
  final String? currency;
  final int? totalMinor;
  final int? taxMinor;
  final String? orderNumber;

  /// The returns sentence as printed. A deadline is never set from it
  /// without the user confirming.
  final String? returnWording;
  final int? returnDays;
  final DateTime? returnDate;
  final List<ParsedItem> items;

  int get itemsTotal => items.fold(0, (s, i) => s + i.lineTotalMinor);

  bool get itemsMatchTotal =>
      items.isNotEmpty && totalMinor != null && itemsTotal == totalMinor;

  /// Suggested deadline the user can accept: an explicit date, or the
  /// purchase date plus the stated number of days.
  DateTime? get suggestedReturnDeadline {
    if (returnDate != null) return returnDate;
    if (returnDays != null && purchaseDate != null) {
      return Dates.addDays(purchaseDate!, returnDays!);
    }
    return null;
  }

  Map<String, dynamic> toExtractedMap() => {
    'shop': shop,
    'purchaseDate': purchaseDate == null ? null : Dates.toIso(purchaseDate!),
    'dateAmbiguous': dateAmbiguous,
    'currency': currency,
    'totalMinor': totalMinor,
    'taxMinor': taxMinor,
    'orderNumber': orderNumber,
    'returnWording': returnWording,
    'itemCount': items.length,
  };
}

/// A receipt row: OCR lines that sit at the same height, joined left to
/// right. ML Kit often returns the name and the price as separate lines.
class _Row {
  _Row(this.page, this.pageWidth, this.pageHeight, OcrLine first)
    : lines = [first];

  final int page;
  final double pageWidth;
  final double pageHeight;
  final List<OcrLine> lines;

  double get centerY => lines.fold(0.0, (s, l) => s + l.centerY) / lines.length;
  double get height => lines.fold(0.0, (s, l) => s + l.height) / lines.length;

  String get text {
    final sorted = [...lines]..sort((a, b) => a.left.compareTo(b.left));
    return sorted.map((l) => l.text.trim()).join('  ');
  }

  LineBox get box {
    var l = double.infinity, t = double.infinity, r = 0.0, b = 0.0;
    for (final line in lines) {
      if (line.left < l) l = line.left;
      if (line.top < t) t = line.top;
      if (line.right > r) r = line.right;
      if (line.bottom > b) b = line.bottom;
    }
    double fx(double v) => pageWidth <= 0 ? 0 : (v / pageWidth).clamp(0, 1);
    double fy(double v) => pageHeight <= 0 ? 0 : (v / pageHeight).clamp(0, 1);
    return LineBox(
      page: page,
      x: fx(l),
      y: fy(t),
      w: fx(r) - fx(l),
      h: fy(b) - fy(t),
    );
  }
}

/// Turns recognised receipt text into proposed fields. It proposes; the
/// user confirms. Written for UK receipts first.
class ReceiptParser {
  ReceiptParser({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  static final _amount = RegExp(
    r'(-)?\s?(?:£|€|\$|GBP\s?|EUR\s?|USD\s?)?(\d{1,3}(?:,\d{3})+|\d+)\.(\d{2})(?!\d)(\s?-)?',
  );
  static final _trailingCode = RegExp(r'\s+(?:[A-Z]|\*|[A-Z]\*)$');
  static final _letters = RegExp('[A-Za-z]{2,}');
  static final _qtyPrefix = RegExp(r'^(\d{1,3})\s*[xX@×]\s+');
  static final _qtySuffix = RegExp(r'\s+[xX×]\s?(\d{1,3})$');
  static final _qtyOnlyRow = RegExp(
    r'^(\d{1,3})\s*[xX@×]\s*(?:£|€|\$)?(\d+\.\d{2})',
  );
  static final _numericDate = RegExp(
    r'\b(\d{1,2}[/\-.]\d{1,2}[/\-.](?:\d{4}|\d{2}))\b',
  );
  static final _writtenDate = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})\b',
  );
  static final _isoDate = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
  static final _orderNumber = RegExp(
    r'\b(?:order|receipt|invoice|transaction|trans|ref(?:erence)?)\s*(?:no\.?|number|num|#|id)?\s*[:#.]?\s*([A-Z0-9][A-Z0-9\-/]{3,})',
    caseSensitive: false,
  );
  static final _returnDays = RegExp(
    r'(\d{1,3})\s*(?:-|\s)?\s*days?',
    caseSensitive: false,
  );

  static const _skipWords = [
    'subtotal',
    'sub total',
    'sub-total',
    'total',
    'vat',
    'tax',
    'change',
    'cash',
    'card',
    'visa',
    'mastercard',
    'amex',
    'contactless',
    'debit',
    'credit',
    'balance',
    'tender',
    'paid',
    'payment',
    'due',
    'savings',
    'saving',
    'discount',
    'points',
    'clubcard',
    'nectar',
    'auth',
    'tip',
    'refund',
    'returns',
    'tel',
    'phone',
    'www',
    'http',
    'merchant',
    'terminal',
    'aid:',
    'pan',
    'expiry',
    'approved',
    'cashback',
    'rounding',
    'promo',
    'multibuy',
    'price cut',
    'you saved',
    'item count',
    'items sold',
    'qty',
    'number of items',
    'delivery address',
    'invoice',
    'order',
  ];

  static const knownShops = {
    'tesco': 'Tesco',
    'sainsbury': "Sainsbury's",
    'asda': 'Asda',
    'morrisons': 'Morrisons',
    'aldi': 'Aldi',
    'lidl': 'Lidl',
    'waitrose': 'Waitrose',
    'marks & spencer': 'Marks & Spencer',
    'marks and spencer': 'Marks & Spencer',
    'm&s': 'Marks & Spencer',
    'co-op': 'Co-op',
    'coop': 'Co-op',
    'iceland': 'Iceland',
    'ocado': 'Ocado',
    'boots': 'Boots',
    'superdrug': 'Superdrug',
    'argos': 'Argos',
    'currys': 'Currys',
    'john lewis': 'John Lewis',
    'ikea': 'IKEA',
    'b&q': 'B&Q',
    'screwfix': 'Screwfix',
    'toolstation': 'Toolstation',
    'wickes': 'Wickes',
    'homebase': 'Homebase',
    'halfords': 'Halfords',
    'dunelm': 'Dunelm',
    'next': 'Next',
    'primark': 'Primark',
    'tk maxx': 'TK Maxx',
    'h&m': 'H&M',
    'zara': 'Zara',
    'uniqlo': 'Uniqlo',
    'amazon': 'Amazon',
    'apple': 'Apple',
    'ao.com': 'AO.com',
    'very.co.uk': 'Very',
    'wilko': 'Wilko',
    'the range': 'The Range',
    'b&m': 'B&M',
    'poundland': 'Poundland',
    'smyths': 'Smyths',
    'game': 'GAME',
    'microsoft': 'Microsoft',
    'costa': 'Costa',
    'greggs': 'Greggs',
    'pret': 'Pret',
    'shell': 'Shell',
    'bp': 'BP',
    'esso': 'Esso',
  };

  static const _grocers = {
    'Tesco',
    "Sainsbury's",
    'Asda',
    'Morrisons',
    'Aldi',
    'Lidl',
    'Waitrose',
    'Co-op',
    'Iceland',
    'Ocado',
  };

  static const _acronyms = {
    'TV',
    'HD',
    'HDMI',
    'QLED',
    'OLED',
    'LED',
    'LCD',
    'USB',
    'UK',
    'XL',
    'XXL',
    'PC',
    'DVD',
    'SSD',
    'HDD',
    'GB',
    'TB',
    'AA',
    'AAA',
    'DAB',
    'UHD',
    'BBQ',
    'DIY',
    'LG',
    'HP',
    'JBL',
    'M&S',
    'B&Q',
    'IKEA',
    'PS5',
    'MDF',
    'W',
    'V',
  };

  /// Category keywords, checked in order; the first match wins.
  static const _categoryWords = <Category, List<String>>{
    Category.electronics: [
      'tv',
      'television',
      'laptop',
      'phone',
      'iphone',
      'ipad',
      'tablet',
      'headphone',
      'earbud',
      'airpods',
      'speaker',
      'monitor',
      'camera',
      'console',
      'playstation',
      'xbox',
      'switch',
      'kindle',
      'macbook',
      'printer',
      'router',
      'soundbar',
      'watch',
    ],
    Category.accessories: [
      'cable',
      'charger',
      'bracket',
      'adapter',
      'case',
      'mount',
      'battery',
      'batteries',
      'plug',
      'extension lead',
      'mouse',
      'keyboard',
      'hdmi',
    ],
    Category.appliances: [
      'vacuum',
      'dyson',
      'kettle',
      'toaster',
      'microwave',
      'fridge',
      'freezer',
      'washing machine',
      'dishwasher',
      'dryer',
      'oven',
      'hob',
      'blender',
      'mixer',
      'air fryer',
      'coffee machine',
      'iron',
      'hoover',
    ],
    Category.lighting: ['lamp', 'bulb', 'light', 'lantern'],
    Category.furniture: [
      'sofa',
      'table',
      'chair',
      'desk',
      'bed',
      'mattress',
      'wardrobe',
      'drawer',
      'shelf',
      'shelving',
      'bookcase',
      'sideboard',
      'cabinet',
      'stool',
      'bench',
      'rug',
      'cushion',
      'curtain',
    ],
    Category.homeDiy: [
      'drill',
      'screw',
      'paint',
      'brush',
      'hammer',
      'saw',
      'tool',
      'nail',
      'filler',
      'sealant',
      'tape',
      'ladder',
      'hose',
      'compost',
      'plant',
    ],
    Category.clothing: [
      'shirt',
      't-shirt',
      'tee',
      'coat',
      'jacket',
      'jeans',
      'trouser',
      'dress',
      'skirt',
      'jumper',
      'sock',
      'shoe',
      'trainer',
      'boot',
      'hoodie',
      'shorts',
      'scarf',
      'hat',
      'glove',
    ],
    Category.jewellery: ['ring', 'necklace', 'bracelet', 'earring', 'pendant'],
    Category.car: [
      'engine oil',
      'motor oil',
      '5w-30',
      '5w30',
      'tyre',
      'wiper',
      'screenwash',
      'antifreeze',
      'unleaded',
      'diesel',
      'petrol',
      'fuel',
      'car wash',
      'mot',
    ],
    Category.health: [
      'shampoo',
      'conditioner',
      'toothpaste',
      'deodorant',
      'paracetamol',
      'ibuprofen',
      'vitamin',
      'soap',
      'shower gel',
      'moisturiser',
      'razor',
    ],
    Category.software: [
      'subscription',
      'licence',
      'license',
      'microsoft 365',
      'office 365',
      'app store',
      'netflix',
      'spotify',
      'download',
      'gift card',
    ],
    Category.services: [
      'installation',
      'install',
      'delivery',
      'service',
      'repair',
      'labour',
      'fitting',
      'warranty',
      'care plan',
      'cover',
    ],
    Category.groceries: [
      'milk',
      'bread',
      'eggs',
      'cheese',
      'butter',
      'chicken',
      'beef',
      'pasta',
      'rice',
      'apple',
      'banana',
      'tomato',
      'potato',
      'onion',
      'yoghurt',
      'cereal',
      'juice',
      'water',
      'coffee',
      'tea',
      'biscuit',
      'crisps',
      'chocolate',
      'wine',
      'beer',
    ],
  };

  ParsedReceipt parse(OcrDocument doc) {
    final rows = _rows(doc);
    if (rows.isEmpty) return const ParsedReceipt();
    final texts = [for (final r in rows) r.text];
    final all = texts.join('\n');

    final shop = _shop(texts);
    final date = _date(texts);
    final total = _total(rows);
    final tax = _tax(rows);
    final returns = _returns(texts);
    final purchaseDate = date?.date;

    return ParsedReceipt(
      shop: shop,
      purchaseDate: purchaseDate,
      dateAmbiguous: date?.ambiguous ?? false,
      currency: _currency(all),
      totalMinor: total?.amount,
      taxMinor: tax,
      orderNumber: _order(texts),
      returnWording: returns?.wording,
      returnDays: returns?.days,
      returnDate: returns?.date,
      items: _items(rows, shop, total?.index),
    );
  }

  // ---------------------------------------------------------------- rows

  List<_Row> _rows(OcrDocument doc) {
    final rows = <_Row>[];
    for (var p = 0; p < doc.pages.length; p++) {
      final page = doc.pages[p];
      final lines = [...page.lines]
        ..sort((a, b) => a.centerY.compareTo(b.centerY));
      final pageRows = <_Row>[];
      for (final line in lines) {
        if (line.text.trim().isEmpty) continue;
        final last = pageRows.isEmpty ? null : pageRows.last;
        if (last != null &&
            (line.centerY - last.centerY).abs() <
                0.5 * (last.height > 0 ? last.height : line.height)) {
          last.lines.add(line);
        } else {
          pageRows.add(_Row(p, page.width, page.height, line));
        }
      }
      rows.addAll(pageRows);
    }
    return rows;
  }

  // --------------------------------------------------------------- amounts

  /// The amount a row ends with, in minor units, or null.
  static int? trailingAmount(String text) {
    final cleaned = text.trim().replaceFirst(_trailingCode, '');
    final matches = _amount.allMatches(cleaned).toList();
    if (matches.isEmpty) return null;
    final m = matches.last;
    // The amount must close the row; a price mid-sentence is not a line total.
    if (cleaned.length - m.end > 2) return null;
    final whole = int.parse(m.group(2)!.replaceAll(',', ''));
    final minor = whole * 100 + int.parse(m.group(3)!);
    final negative = m.group(1) != null || (m.group(4)?.contains('-') ?? false);
    return negative ? -minor : minor;
  }

  static String _withoutAmount(String text) {
    final cleaned = text.trim().replaceFirst(_trailingCode, '');
    final matches = _amount.allMatches(cleaned).toList();
    if (matches.isEmpty) return cleaned;
    return cleaned.substring(0, matches.last.start).trim();
  }

  // ------------------------------------------------------------------ shop

  String? _shop(List<String> texts) {
    final top = texts.take(8).join('\n').toLowerCase();
    final all = texts.join('\n').toLowerCase();
    for (final source in [top, all]) {
      for (final entry in knownShops.entries) {
        final key = RegExp.escape(entry.key);
        if (RegExp('(^|[^a-z])$key([^a-z]|\$)').hasMatch(source)) {
          return entry.value;
        }
      }
    }
    for (final text in texts.take(5)) {
      final t = text.trim();
      if (t.length < 3 || !_letters.hasMatch(t)) continue;
      if (trailingAmount(t) != null || _numericDate.hasMatch(t)) continue;
      final lower = t.toLowerCase();
      if (lower.startsWith('welcome') ||
          lower.contains('vat') ||
          lower.contains('receipt') ||
          lower.contains('tel') ||
          lower.contains('www')) {
        continue;
      }
      return tidyName(t);
    }
    return null;
  }

  // ------------------------------------------------------------------ date

  ParsedReceiptDate? _date(List<String> texts) {
    final latest = Dates.addDays(_clock(), 1);
    final candidates = <ParsedReceiptDate>[];
    for (final text in texts) {
      final lower = text.toLowerCase();
      // Expiry, return and warranty dates are not the purchase date.
      if (lower.contains('exp') ||
          lower.contains('return') ||
          lower.contains('valid') ||
          lower.contains('until') ||
          lower.contains('due')) {
        continue;
      }
      for (final m in _isoDate.allMatches(text)) {
        final d = DateTime.tryParse(m.group(0)!);
        if (d != null) candidates.add(ParsedReceiptDate(date: d));
      }
      for (final m in _numericDate.allMatches(text)) {
        candidates.add(ReceiptDateParser.parse(m.group(1)!));
      }
      for (final m in _writtenDate.allMatches(text)) {
        candidates.add(
          ReceiptDateParser.parse('${m.group(1)} ${m.group(2)} ${m.group(3)}'),
        );
      }
    }
    for (final c in candidates) {
      final d = c.date;
      if (d != null && !d.isAfter(latest) && d.year >= 1990) return c;
    }
    return null;
  }

  // ----------------------------------------------------------------- total

  ({int amount, int index})? _total(List<_Row> rows) {
    const strong = [
      'grand total',
      'total to pay',
      'amount due',
      'balance due',
      'total due',
      'order total',
      'total paid',
      'amount paid',
    ];
    ({int amount, int index})? best;
    var bestRank = 99;
    for (var i = 0; i < rows.length; i++) {
      final text = rows[i].text;
      final lower = text.toLowerCase();
      final amount = trailingAmount(text);
      if (amount == null || amount <= 0) continue;
      int? rank;
      if (strong.any(lower.contains)) {
        rank = 0;
      } else if (RegExp(r'(^|[^a-z])total([^a-z]|$)').hasMatch(lower) &&
          !lower.contains('sub') &&
          !lower.contains('saving') &&
          !lower.contains('vat') &&
          !lower.contains('items') &&
          !lower.contains('discount')) {
        rank = 1;
      } else if (RegExp(
        r'^(card|visa|mastercard|debit|credit|contactless|cash|amex|paid)\b',
      ).hasMatch(lower.trim())) {
        rank = 2;
      } else if (lower.contains('balance')) {
        rank = 3;
      }
      if (rank != null && rank < bestRank) {
        best = (amount: amount, index: i);
        bestRank = rank;
      }
    }
    return best;
  }

  int? _tax(List<_Row> rows) {
    for (final row in rows) {
      final lower = row.text.toLowerCase();
      if (!lower.contains('vat') && !RegExp(r'\btax\b').hasMatch(lower)) {
        continue;
      }
      if (lower.contains('vat no') ||
          lower.contains('vat reg') ||
          lower.contains('vat number') ||
          lower.contains('excl') ||
          lower.contains('net')) {
        continue;
      }
      final amount = trailingAmount(row.text);
      if (amount != null && amount > 0) return amount;
    }
    return null;
  }

  String? _currency(String all) {
    if (all.contains('£') || all.contains('GBP')) return 'GBP';
    if (all.contains('€') || all.contains('EUR')) return 'EUR';
    if (all.contains(r'$') || all.contains('USD')) return 'USD';
    return null;
  }

  String? _order(List<String> texts) {
    for (final text in texts) {
      final lower = text.toLowerCase();
      if (lower.contains('vat')) continue;
      final m = _orderNumber.firstMatch(text);
      if (m == null) continue;
      final value = m.group(1)!;
      // A plain date or amount after "Receipt" is not a reference.
      if (!RegExp(r'\d').hasMatch(value)) continue;
      if (_numericDate.hasMatch(value) || _amount.hasMatch(value)) continue;
      return value;
    }
    return null;
  }

  // --------------------------------------------------------------- returns

  ({String wording, int? days, DateTime? date})? _returns(List<String> texts) {
    for (var i = 0; i < texts.length; i++) {
      final lower = texts[i].toLowerCase();
      if (!lower.contains('return') && !lower.contains('refund')) continue;
      if (trailingAmount(texts[i]) != null && !lower.contains('day')) continue;
      // The sentence often wraps onto the next printed line.
      var wording = texts[i].trim();
      if (i + 1 < texts.length &&
          !wording.endsWith('.') &&
          trailingAmount(texts[i + 1]) == null &&
          texts[i + 1].trim().length < 60) {
        wording = '$wording ${texts[i + 1].trim()}';
      }
      final days = _returnDays.firstMatch(wording);
      DateTime? date;
      final written = _writtenDate.firstMatch(wording);
      if (written != null) {
        date = ReceiptDateParser.parse(
          '${written.group(1)} ${written.group(2)} ${written.group(3)}',
        ).date;
      } else {
        final numeric = _numericDate.firstMatch(wording);
        if (numeric != null) {
          date = ReceiptDateParser.parse(numeric.group(1)!).date;
        }
      }
      if (days == null && date == null) continue;
      return (
        wording: wording,
        days: days == null ? null : int.parse(days.group(1)!),
        date: date,
      );
    }
    return null;
  }

  // ----------------------------------------------------------------- items

  List<ParsedItem> _items(List<_Row> rows, String? shop, int? totalIndex) {
    final end = totalIndex ?? rows.length;
    final items = <ParsedItem>[];
    // A name printed on its own row, waiting for a `2 @ 0.45  0.90` row.
    _Row? nameRow;
    for (var i = 0; i < end; i++) {
      final row = rows[i];
      final text = row.text.trim();
      final pendingName = nameRow;
      nameRow = null;

      final qtyOnly = _qtyOnlyRow.firstMatch(text);
      if (qtyOnly != null && !_letters.hasMatch(text) && pendingName != null) {
        final qty = int.parse(qtyOnly.group(1)!);
        final unit = _toMinor(qtyOnly.group(2)!);
        final line = trailingAmount(text);
        final name = pendingName.text.trim();
        items.add(
          ParsedItem(
            name: tidyName(name),
            rawText: name,
            quantity: qty,
            unitPriceMinor: unit,
            lineTotalMinor: line == null || line == unit ? unit * qty : line,
            category: guessCategory(name, shop: shop),
            box: pendingName.box,
          ),
        );
        continue;
      }
      if (qtyOnly != null && !_letters.hasMatch(text) && items.isNotEmpty) {
        // `2 x 24.00` printed under the item: set its quantity.
        final prev = items.removeLast();
        final qty = int.parse(qtyOnly.group(1)!);
        final unit = _toMinor(qtyOnly.group(2)!);
        final line = trailingAmount(text) ?? prev.lineTotalMinor;
        items.add(
          ParsedItem(
            name: prev.name,
            rawText: prev.rawText,
            quantity: qty,
            unitPriceMinor: unit,
            lineTotalMinor: line == unit ? unit * qty : line,
            category: prev.category,
            box: prev.box,
          ),
        );
        continue;
      }

      final amount = trailingAmount(text);
      if (amount == null) {
        final lower = text.toLowerCase();
        if (_letters.hasMatch(text) &&
            !_amount.hasMatch(text) &&
            !_skipWords.any((w) => _containsWord(lower, w))) {
          nameRow = row;
        }
        continue;
      }
      if (amount <= 0) continue;
      var name = _withoutAmount(text);
      if (!_letters.hasMatch(name)) continue;
      final lower = name.toLowerCase();
      if (_skipWords.any((w) => _containsWord(lower, w))) continue;
      if (_numericDate.hasMatch(name)) continue;

      var quantity = 1;
      final prefix = _qtyPrefix.firstMatch(name);
      final suffix = _qtySuffix.firstMatch(name);
      if (prefix != null) {
        quantity = int.parse(prefix.group(1)!);
        name = name.substring(prefix.end);
      } else if (suffix != null) {
        quantity = int.parse(suffix.group(1)!);
        name = name.substring(0, suffix.start);
      }
      // Unit prices printed mid-line, e.g. `LAMP 2 @ 24.00  48.00`.
      name = name.replaceAll(RegExp(r'\s+\d+\s*@\s*\d+\.\d{2}$'), '');
      name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      if (name.length < 2) continue;
      if (shop != null && name.toLowerCase() == shop.toLowerCase()) continue;

      items.add(
        ParsedItem(
          name: tidyName(name),
          rawText: name,
          quantity: quantity,
          unitPriceMinor: quantity > 1 ? amount ~/ quantity : amount,
          lineTotalMinor: amount,
          category: guessCategory(name, shop: shop),
          box: row.box,
        ),
      );
    }
    return items;
  }

  static bool _containsWord(String haystack, String word) {
    if (word.contains(' ') || word.contains(':') || word.contains('.')) {
      return haystack.contains(word);
    }
    return RegExp(
      '(^|[^a-z])${RegExp.escape(word)}([^a-z]|\$)',
    ).hasMatch(haystack);
  }

  static int _toMinor(String s) {
    final parts = s.split('.');
    return int.parse(parts[0]) * 100 + int.parse(parts[1]);
  }

  /// `SAMSUNG 55 QLED TV` → `Samsung 55 QLED TV`. Leaves mixed case alone.
  static String tidyName(String raw) {
    final text = raw.trim();
    if (text != text.toUpperCase()) return text;
    return text
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          if (_acronyms.contains(w) || RegExp(r'\d').hasMatch(w)) return w;
          return w[0] + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static Category guessCategory(String name, {String? shop}) {
    final lower = ' ${name.toLowerCase()} ';
    for (final entry in _categoryWords.entries) {
      for (final word in entry.value) {
        if (lower.contains(' $word') || lower.contains('$word ')) {
          return entry.key;
        }
      }
    }
    if (shop != null && _grocers.contains(shop)) return Category.groceries;
    if (shop == 'Halfords') return Category.car;
    return Category.other;
  }
}
