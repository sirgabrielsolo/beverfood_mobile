import 'package:flutter_test/flutter_test.dart';

import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/models/promo_selection.dart';

const _naturale = PromoProduct(
  id: 5031,
  name: 'LILIA NATURALE 500 ML 24 PZ',
  price: 4.3,
  iva: 22,
  imageUrl: '',
);
const _gas = PromoProduct(
  id: 5032,
  name: 'LILIA GAS 500 ML 24 PZ',
  price: 4.3,
  iva: 22,
  imageUrl: '',
);

/// PROMO ACQUA LILIA 10 + 3, as the API sends it.
const _lilia = Promo(
  id: 92,
  name: 'PROMO ACQUA LILIA 10 + 3',
  price: 43,
  iva: 22,
  imageUrl: '',
  title: 'Acqua Lilia',
  highlight: '10+3',
  subtitle: '',
  groups: [
    PromoGroup(
      role: PromoRole.paid,
      mode: PromoMode.total,
      quantity: 10,
      products: [_naturale, _gas],
    ),
    PromoGroup(
      role: PromoRole.free,
      mode: PromoMode.total,
      quantity: 3,
      products: [_naturale, _gas],
    ),
  ],
);

void main() {
  test('a mixed promo is complete once every group is filled', () {
    var s = PromoSelection(_lilia);
    expect(s.firstMissing?.remaining, 10);
    expect(s.firstMissing?.group.role, PromoRole.paid);

    s = s.withCount(0, 5031, 6).withCount(0, 5032, 4);
    expect(s.chosen(0), 10);
    expect(s.firstMissing?.group.role, PromoRole.free);
    expect(s.firstMissing?.remaining, 3);

    s = s.withCount(1, 5031, 2).withCount(1, 5032, 1);
    expect(s.isComplete, isTrue);
  });

  test('a group never takes more than its quantity', () {
    final s = PromoSelection(
      _lilia,
    ).withCount(0, 5031, 8).withCount(0, 5032, 5);
    expect(s.countOf(0, 5032), 2);
    expect(s.withCount(0, 5031, -1).countOf(0, 5031), 0);
  });

  test('savings are the free items at catalogue prices', () {
    // 13 × 4,30 = 55,90 of value for 43,00.
    expect(PromoSelection(_lilia).savings, closeTo(12.9, 0.001));
  });

  test('the order note lists the mix with database names', () {
    final s = PromoSelection(
      _lilia,
    ).withCount(0, 5031, 6).withCount(0, 5032, 4).withCount(1, 5032, 3);
    expect(
      s.orderNote,
      'PROMO ACQUA LILIA 10 + 3 — '
      'pagati: 6 × LILIA NATURALE 500 ML 24 PZ, 4 × LILIA GAS 500 ML 24 PZ; '
      'omaggio: 3 × LILIA GAS 500 ML 24 PZ',
    );
  });

  test('a promo with fixed groups needs no choice and no note', () {
    const alix = PromoProduct(
      id: 6550,
      name: 'ALIX BARBERA SUPERIORE 750 ML',
      price: 7,
      iva: 22,
      imageUrl: '',
    );
    const promo = Promo(
      id: 901,
      name: 'PROMO ALIX BARBERA SUPERIORE 5 + 1',
      price: 35,
      iva: 22,
      imageUrl: '',
      title: 'Alix Barbera Superiore',
      highlight: '5+1',
      subtitle: '',
      groups: [
        PromoGroup(
          role: PromoRole.paid,
          mode: PromoMode.each,
          quantity: 5,
          products: [alix],
        ),
        PromoGroup(
          role: PromoRole.free,
          mode: PromoMode.each,
          quantity: 1,
          products: [alix],
        ),
      ],
    );
    final s = PromoSelection(promo);
    expect(s.isComplete, isTrue);
    expect(s.countOf(0, 6550), 5);
    expect(s.savings, closeTo(7, 0.001));
    expect(s.orderNote, isNull);
  });

  test('same choices compare equal', () {
    final a = PromoSelection(_lilia).withCount(0, 5031, 2);
    expect(
      a.sameChoicesAs(PromoSelection(_lilia).withCount(0, 5031, 2)),
      isTrue,
    );
    expect(a.sameChoicesAs(a.withCount(0, 5032, 1)), isFalse);
  });
}
