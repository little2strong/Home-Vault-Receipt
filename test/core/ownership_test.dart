import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/models/ownership_models.dart';
import 'package:home_vault_receipt/core/repositories/ownership_repository.dart';
import 'package:home_vault_receipt/features/inbox/controller/inbox_controller.dart';
import 'package:home_vault_receipt/features/insurance/controller/insurance_controller.dart';
import 'package:home_vault_receipt/features/protection/controller/protection_controller.dart';

void main() {
  test('sale details can be cleared without dropping the item', () {
    final item = Possession(
      id: 'p',
      name: 'Bicycle',
      room: 'Garage',
      purchaseDate: DateTime(2024, 5, 1),
      retailer: 'Local shop',
      saleDate: DateTime(2026, 1, 2),
      salePrice: 40000,
      buyerNote: 'Sam',
      status: OwnershipStatus.sold,
    );

    final cleared = item.copyWith(
      status: OwnershipStatus.owned,
      clearSaleDate: true,
      clearSalePrice: true,
      clearBuyerNote: true,
    );

    expect(cleared.status, OwnershipStatus.owned);
    expect(cleared.saleDate, isNull);
    expect(cleared.salePrice, isNull);
    expect(cleared.buyerNote, isNull);
    expect(cleared.purchaseDate, DateTime(2024, 5, 1));
    expect(cleared.retailer, 'Local shop');
  });

  test('inbox merge matches a possession named inside the draft', () {
    final ownership = OwnershipRepository();
    final inbox = InboxController(ownership: ownership);

    expect(inbox.mergeCandidate?.$1.name, 'Sony headphones');
    expect(inbox.mergeCandidate?.$2.name, 'Headphones');
    expect(InboxController.namesMatch('Air fryer', 'Coffee machine'), isFalse);
  });

  test('a missing purchase date is not treated as one year of age', () {
    final ownership = OwnershipRepository();
    final insurance = InsuranceController(ownership: ownership);
    final sofa = ownership.byId('p-sofa')!;

    expect(sofa.purchaseDate, isNull);
    expect(insurance.currentEstimate(sofa), sofa.purchasePrice);
    expect(insurance.replacementEstimate(sofa), sofa.purchasePrice);
  });

  test('logging maintenance keeps the work date and the next service', () {
    final ownership = OwnershipRepository();
    final protection = ProtectionController(ownership: ownership);
    final before = protection.history.length;

    ownership.addMaintenance(
      MaintenanceTask(
        id: 'm-new',
        item: 'Coffee machine',
        work: 'Descale',
        due: DateTime(2026, 10, 1),
        nextDue: ownership.today.add(const Duration(days: 30)),
        done: true,
      ),
    );

    expect(protection.history, hasLength(before + 1));
    expect(protection.history.first.due, DateTime(2026, 10, 1));
    expect(protection.upcoming.map((m) => m.id), contains('m-new'));
  });
}
