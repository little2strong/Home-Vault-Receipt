import '../models/product_category.dart';
import '../utils/dates.dart';
import '../models/receipt_document.dart';
import '../models/receipt_item.dart';
import '../models/receipt_model.dart';

/// Synthetic vault used in debug builds so every screen has something to
/// show. Dates are relative to [today] so deadlines never go stale.
abstract final class SampleData {
  static List<Receipt> receipts(DateTime today) {
    DateTime ago(int days) => Dates.addDays(today, -days);
    ReceiptItem item(
      String id,
      String name,
      int total,
      ProductCategory category, {
      String? source,
      int quantity = 1,
    }) => ReceiptItem(
      id: id,
      name: name,
      lineTotal: total,
      category: category,
      sourceDescription: source,
      quantity: quantity,
    );
    ReceiptDocument image(String id, String name) => ReceiptDocument(
      id: id,
      kind: DocumentKind.image,
      fileName: name,
      sizeBytes: 1450000,
      uploaded: true,
    );

    const groceries = [
      ('Milk', 145), ('Bread', 135), ('Eggs', 289), ('Apples', 210), //
      ('Pasta', 95), ('Coffee beans', 650), ('Cheese', 375),
      ('Chicken', 699), ('Rice', 220), ('Olive oil', 799),
      ('Washing liquid', 1050), ('Salmon', 1815),
    ];

    return [
      Receipt(
        id: 'sample-currys',
        retailer: 'Currys',
        purchaseDate: ago(2),
        total: 17900,
        createdAt: ago(2),
        reference: 'CR-${today.year}-10482',
        items: [
          item(
            's-1',
            'Sony wireless headphones',
            17900,
            ProductCategory.electronics,
            source: 'SONY WH-1000XM5',
          ),
        ],
        returnDeadline: Dates.addDays(today, 11),
        deadlineSource: DeadlineSource.statedOnReceipt,
        source: ReceiptSource.camera,
        documents: [image('d-1', 'currys.jpg')],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-shoes',
        retailer: 'Runners Need',
        purchaseDate: ago(24),
        total: 8999,
        createdAt: ago(24),
        items: [item('s-2', 'Running shoes', 8999, ProductCategory.clothing)],
        returnDeadline: Dates.addDays(today, 6),
        deadlineSource: DeadlineSource.addedByUser,
        source: ReceiptSource.photos,
        documents: [image('d-2', 'shoes.jpg')],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-ikea',
        retailer: 'IKEA',
        purchaseDate: ago(14),
        total: 42800,
        createdAt: ago(14),
        reference: 'IK-${today.year}-55120',
        items: [
          item('s-3', 'LANDSKRONA sofa', 34900, ProductCategory.home),
          item('s-4', 'LACK side table', 2900, ProductCategory.home),
          item('s-5', 'Floor lamp', 5000, ProductCategory.home),
        ],
        source: ReceiptSource.photos,
        documents: [image('d-3', 'ikea.jpg')],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-john-lewis',
        retailer: 'John Lewis',
        purchaseDate: ago(18),
        total: 24900,
        createdAt: ago(18),
        reference: 'JL-${today.year}-88317',
        items: [
          item(
            's-6',
            'Coffee machine',
            24900,
            ProductCategory.appliances,
            source: 'BARISTA ESPRESSO BES870',
          ),
        ],
        notes: 'Birthday gift',
        source: ReceiptSource.pdf,
        documents: const [
          ReceiptDocument(
            id: 'd-4',
            kind: DocumentKind.pdf,
            fileName: 'invoice-john-lewis.pdf',
            pageCount: 2,
            sizeBytes: 820 * 1024,
            uploaded: true,
          ),
        ],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-tesco',
        retailer: 'Tesco',
        purchaseDate: ago(21),
        total: 6482,
        createdAt: ago(21),
        items: [
          for (final (i, (name, price)) in groceries.indexed)
            item('g-$i', name, price, ProductCategory.groceries),
        ],
        source: ReceiptSource.camera,
        documents: [image('d-5', 'tesco.jpg')],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-apple',
        retailer: 'Apple',
        purchaseDate: ago(30),
        total: 109900,
        createdAt: ago(30),
        reference: 'W${today.year}4471',
        items: [
          item(
            's-7',
            'MacBook Air',
            109900,
            ProductCategory.electronics,
            source: 'MACBOOK AIR 13-INCH M3',
          ),
        ],
        source: ReceiptSource.pdf,
        documents: const [
          ReceiptDocument(
            id: 'd-6',
            kind: DocumentKind.pdf,
            fileName: 'apple-invoice.pdf',
            sizeBytes: 310 * 1024,
            uploaded: true,
          ),
        ],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-stand',
        retailer: 'Currys',
        purchaseDate: ago(39),
        total: 3999,
        createdAt: ago(39),
        items: [item('s-8', 'Laptop stand', 3999, ProductCategory.electronics)],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-dell',
        retailer: 'Dell',
        purchaseDate: ago(45),
        total: 29900,
        createdAt: ago(45),
        items: [item('s-9', 'Monitor', 29900, ProductCategory.electronics)],
        status: ReceiptStatus.saved,
      ),
      Receipt(
        id: 'sample-draft',
        retailer: 'Argos',
        purchaseDate: ago(1),
        total: 3499,
        createdAt: ago(1),
        items: [item('s-10', 'Kettle', 3499, ProductCategory.appliances)],
        source: ReceiptSource.camera,
        documents: [
          const ReceiptDocument(
            id: 'd-7',
            kind: DocumentKind.image,
            fileName: 'argos.jpg',
            sizeBytes: 980000,
          ),
        ],
      ),
    ];
  }
}
