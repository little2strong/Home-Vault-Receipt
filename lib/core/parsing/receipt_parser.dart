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
    return ReceiptParser.normalise(
      sorted.map((l) => l.text.trim()).join('  '),
    );
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
  // `LAMP 2 @ 24.00` once the line total is taken off the end.
  static final _qtyMidline = RegExp(
    r'\s+(\d{1,3})\s*[xX@×]\s*(?:£|€|\$)?(\d+\.\d{2})(?:\s*each)?$',
  );
  // `BANANAS 0.856 kg @ £0.68/kg`
  static final _weighed = RegExp(
    r'\s+\d+(?:\.\d+)?\s*kg\s*@?\s*(?:£|€|\$)?\d+\.\d{2}\s*/\s*kg$',
    caseSensitive: false,
  );
  static final _numericDate = RegExp(
    r'\b(\d{1,2}[/\-.]\d{1,2}[/\-.](?:\d{4}|\d{2}))\b',
  );
  static final _writtenDate = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})\b',
  );
  // `Oct 1, 2026`
  static final _writtenDateMonthFirst = RegExp(
    r'\b([A-Za-z]{3,9})\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})\b',
  );
  static final _isoDate = RegExp(r'\b(\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2})\b');
  // Dates near these words are not the purchase date. `exp` must be a word
  // of its own so "Tesco Express" still counts.
  static final _notPurchaseDate = RegExp(
    r'\bexp(?:iry|ires?|\b|[.:/])|return|refund|valid|until|due|warranty|guarantee',
  );
  // `CARD 12.99`, `DEBIT CARD`, but not `GIFT CARD` or `SD CARD`.
  static final _paymentCard = RegExp(
    r'^(?:(?:credit|debit|bank|payment|visa|master|contactless)\s+)?card'
    r'(?:\s+(?:payment|sale|tendered|paid|no\.?|number|ending.*))?$',
  );

  // OCR misreads in amounts, fixed before anything is parsed.
  static final _euroThousands = RegExp(r'(\d)\.(\d{3}),(\d{2})(?!\d)');
  static final _decimalComma = RegExp(r'(\d),(\d{2})(?![\d,])');
  static final _spacedDecimal = RegExp(r'(\d) ?\. ?(\d{2})(?!\d)');
  static final _letterO = RegExp(
    r'(?<=\d)[Oo](?=[\d.,])|(?<=\d[.,])[Oo]|(?<=\d[.,]\d)[Oo]',
  );
  // A zero between letters is the letter O (`B0OKCASE`); `PS5`, `V12` and
  // `64GB` are left alone.
  static final _zeroInWord = RegExp(r'(?<=[A-Za-z])0(?=[A-Za-z])');
  // A bracket stuck to the `@` of `2 @ 24.00`.
  static final _bracketedAt = RegExp(r'[(\[{]\s*@|@\s*[)\]}]');

  /// Fixes the common ways text recognition garbles prices: `12,99` for
  /// `12.99`, `1.234,56` for `1234.56`, `12. 99`, and the letter O in
  /// place of a zero (`1O.99`), plus a zero read for an O inside a word and
  /// stray brackets around `@`.
  static String normalise(String text) => text
      .replaceAll(_zeroInWord, 'O')
      .replaceAll(_bracketedAt, '@')
      .replaceAll(_letterO, '0')
      .replaceAllMapped(_euroThousands, (m) => '${m[1]}${m[2]}.${m[3]}')
      .replaceAllMapped(_decimalComma, (m) => '${m[1]}.${m[2]}')
      .replaceAllMapped(_spacedDecimal, (m) => '${m[1]}.${m[2]}');
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
    'pan seq',
    'pan:',
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
    'SD',
    'SIM',
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
    final tax = _tax(rows, total?.amount);
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
    final cleaned = normalise(text.trim()).replaceFirst(_trailingCode, '');
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
    final cleaned = normalise(text.trim()).replaceFirst(_trailingCode, '');
    final matches = _amount.allMatches(cleaned).toList();
    if (matches.isEmpty) return cleaned;
    return cleaned.substring(0, matches.last.start).trim();
  }

  // ------------------------------------------------------------------ shop

  /// Shop names that are also everyday words ("see you next time", "boots",
  /// "bramley apples"); trusted only in the header.
  static const _commonWordShops = {
    'next',
    'game',
    'shell',
    'apple',
    'boots',
    'iceland',
    'pret',
    'bp',
    'costa',
    'the range',
  };

  String? _shop(List<String> texts) {
    // The header: the rows above the first priced line. On a short receipt
    // the first eight rows can reach the footer ("See you next time").
    final header = texts
        .take(8)
        .takeWhile((t) => trailingAmount(t) == null)
        .join('\n')
        .toLowerCase();
    final all = texts.join('\n').toLowerCase();

    /// The known shop named earliest in [source].
    String? earliest(String source, {required bool anyName}) {
      String? best;
      var bestAt = -1;
      for (final entry in knownShops.entries) {
        if (!anyName && _commonWordShops.contains(entry.key)) continue;
        final key = RegExp.escape(entry.key);
        final m = RegExp('(^|[^a-z])$key([^a-z]|\$)').firstMatch(source);
        if (m != null && (bestAt < 0 || m.start < bestAt)) {
          best = entry.value;
          bestAt = m.start;
        }
      }
      return best;
    }

    final known =
        earliest(header, anyName: true) ?? earliest(all, anyName: false);
    if (known != null) return known;
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
      // Expiry, return and warranty dates are not the purchase date.
      if (_notPurchaseDate.hasMatch(text.toLowerCase())) continue;
      for (final m in _isoDate.allMatches(text)) {
        candidates.add(ReceiptDateParser.parse(m.group(1)!));
      }
      // Year-first dates are already taken; don't re-read their tail.
      final rest = text.replaceAll(_isoDate, ' ');
      for (final m in _numericDate.allMatches(rest)) {
        candidates.add(ReceiptDateParser.parse(m.group(1)!));
      }
      for (final m in _writtenDate.allMatches(rest)) {
        candidates.add(
          ReceiptDateParser.parse('${m.group(1)} ${m.group(2)} ${m.group(3)}'),
        );
      }
      for (final m in _writtenDateMonthFirst.allMatches(rest)) {
        candidates.add(
          ReceiptDateParser.parse('${m.group(2)} ${m.group(1)} ${m.group(3)}'),
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
      final amount = _amountFor(rows, i);
      if (amount == null || amount <= 0) continue;
      int? rank;
      if (strong.any(lower.contains)) {
        rank = 0;
      } else if (RegExp(r'(^|[^a-z])total([^a-z]|$)').hasMatch(lower) &&
          !lower.contains('sub') &&
          !lower.contains('saving') &&
          (!lower.contains('vat') || RegExp(r'\binc').hasMatch(lower)) &&
          !lower.contains('items') &&
          !lower.contains('discount') &&
          !lower.contains('excl') &&
          !RegExp(r'\bnet\b').hasMatch(lower)) {
        rank = 1;
      } else if (RegExp(
        r'^(card|visa|mastercard|debit|credit|contactless|cash|amex|paid)\b',
      ).hasMatch(lower.trim())) {
        rank = 2;
      } else if (lower.contains('balance')) {
        rank = 3;
      }
      if (rank == null) continue;
      // Two plain "Total" rows: the larger one includes VAT or delivery.
      final better =
          rank < bestRank ||
          (rank == 1 && bestRank == 1 && amount > best!.amount);
      if (better) {
        best = (amount: amount, index: i);
        bestRank = rank;
      }
    }
    return best;
  }

  int? _tax(List<_Row> rows, int? total) {
    for (var i = 0; i < rows.length; i++) {
      final lower = rows[i].text.toLowerCase();
      if (!lower.contains('vat') && !RegExp(r'\btax\b').hasMatch(lower)) {
        continue;
      }
      // `VAT No.`, `Total excl. VAT`, `Total inc VAT 1,128.00` are not the
      // VAT amount.
      if (lower.contains('vat no') ||
          lower.contains('vat reg') ||
          lower.contains('vat number') ||
          lower.contains('excl') ||
          lower.contains('incl') ||
          lower.contains('inc ') ||
          lower.contains('inc.') ||
          lower.contains('including') ||
          RegExp(r'\bnet\b').hasMatch(lower)) {
        continue;
      }
      final amount = _amountFor(rows, i);
      if (amount == null || amount <= 0) continue;
      if (total != null && amount >= total) continue;
      return amount;
    }
    return null;
  }

  /// The row's own amount, or the amount alone on the next row when OCR
  /// split a tilted `TOTAL ........ 12.99` line in two.
  int? _amountFor(List<_Row> rows, int i) {
    final own = trailingAmount(rows[i].text);
    if (own != null) return own;
    if (i + 1 >= rows.length) return null;
    final next = rows[i + 1].text;
    final amount = trailingAmount(next);
    return amount != null && _withoutAmount(next).isEmpty ? amount : null;
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
    // A name printed on its own row, waiting for a `2 @ 0.45  0.90` row or
    // for a price OCR placed on the next row.
    _Row? nameRow;
    // A price alone on its row, waiting for a name OCR placed just below.
    int? priceRow;
    for (var i = 0; i < end; i++) {
      final row = rows[i];
      final text = row.text.trim();
      final pendingName = nameRow;
      final pendingPrice = priceRow;
      nameRow = null;
      priceRow = null;

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
        if (_isNameOnly(text)) {
          if (pendingPrice != null) {
            // The price sat a little higher than its name (tilted photo).
            _addItem(items, text, pendingPrice, row.box, shop);
          } else {
            nameRow = row;
          }
        }
        continue;
      }
      if (amount <= 0) continue;
      final name = _withoutAmount(text);
      if (!_letters.hasMatch(name)) {
        if (pendingName != null) {
          // The price sat a little lower than its name.
          _addItem(items, pendingName.text, amount, pendingName.box, shop);
        } else if (name.isEmpty) {
          priceRow = amount;
        }
        continue;
      }
      _addItem(items, name, amount, row.box, shop);
    }
    return items;
  }

  /// A row that could be an item name waiting for its price.
  static bool _isNameOnly(String text) =>
      _letters.hasMatch(text) &&
      !_amount.hasMatch(text) &&
      !_isSkipped(text.toLowerCase());

  static bool _isSkipped(String lower) =>
      _skipWords.any((w) => _containsWord(lower, w)) ||
      _paymentCard.hasMatch(lower.trim());

  void _addItem(
    List<ParsedItem> items,
    String raw,
    int amount,
    LineBox box,
    String? shop,
  ) {
    var name = raw.trim();
    if (_isSkipped(name.toLowerCase())) return;
    if (_numericDate.hasMatch(name)) return;

    var quantity = 1;
    int? unit;
    final prefix = _qtyPrefix.firstMatch(name);
    final suffix = _qtySuffix.firstMatch(name);
    final midline = _qtyMidline.firstMatch(name);
    if (prefix != null) {
      quantity = int.parse(prefix.group(1)!);
      name = name.substring(prefix.end);
    } else if (midline != null) {
      // `LAMP 2 @ 24.00  48.00`
      quantity = int.parse(midline.group(1)!);
      unit = _toMinor(midline.group(2)!);
      name = name.substring(0, midline.start);
    } else if (suffix != null) {
      quantity = int.parse(suffix.group(1)!);
      name = name.substring(0, suffix.start);
    }
    name = name.replaceAll(_weighed, '');
    name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (name.length < 2 || !_letters.hasMatch(name)) return;
    if (shop != null && name.toLowerCase() == shop.toLowerCase()) return;
    if (quantity < 1) quantity = 1;

    items.add(
      ParsedItem(
        name: tidyName(name),
        rawText: raw.trim(),
        quantity: quantity,
        unitPriceMinor: unit ?? (quantity > 1 ? amount ~/ quantity : amount),
        lineTotalMinor: amount,
        category: guessCategory(name, shop: shop),
        box: box,
      ),
    );
  }

  /// A deadline from the returns wording: an explicit date, or the
  /// purchase date plus the stated number of days. Only ever a suggestion.
  static DateTime? returnDeadlineFrom(String wording, DateTime? purchased) {
    final written = _writtenDate.firstMatch(wording);
    if (written != null) {
      final d = ReceiptDateParser.parse(
        '${written.group(1)} ${written.group(2)} ${written.group(3)}',
      ).date;
      if (d != null) return d;
    }
    final numeric = _numericDate.firstMatch(wording);
    if (numeric != null) {
      final d = ReceiptDateParser.parse(numeric.group(1)!).date;
      if (d != null) return d;
    }
    final days = _returnDays.firstMatch(wording);
    if (days != null && purchased != null) {
      return Dates.addDays(purchased, int.parse(days.group(1)!));
    }
    return null;
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

  static final _wordPatterns = <String, RegExp>{};

  /// Whole words only, plurals allowed: `lamps` is a lamp, but `bookcase`
  /// is not a `case` and `motorbike` is not an `mot`.
  static bool _hasWord(String lower, String word) =>
      (_wordPatterns[word] ??= RegExp(
        '(^|[^a-z0-9])${RegExp.escape(word)}(s|es)?([^a-z]|\$)',
      )).hasMatch(lower);

  static Category guessCategory(String name, {String? shop}) {
    final lower = name.toLowerCase();
    for (final entry in _categoryWords.entries) {
      for (final word in entry.value) {
        if (_hasWord(lower, word)) return entry.key;
      }
    }
    if (shop != null && _grocers.contains(shop)) return Category.groceries;
    if (shop == 'Halfords') return Category.car;
    return Category.other;
  }
}
