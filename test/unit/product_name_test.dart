import 'package:flutter_test/flutter_test.dart';

import 'package:beverfood_mobile/core/formatting/product_name.dart';

void main() {
  test('splits the ERP name into a name and its pack', () {
    expect(splitProductName('LILIA NATURALE 500 ML 24 PZ'), (
      name: 'Lilia Naturale',
      pack: '500 ml · 24 pz',
    ));
    // Size glued to its unit, a final accent written as an apostrophe, and
    // the container abbreviation.
    expect(splitProductName("ESTATHE' PESCA LAT 330ML 24 PZ"), (
      name: 'Estathè Pesca lattina',
      pack: '330 ml · 24 pz',
    ));
    expect(splitProductName("ESTATHE' LIMONE BT 1,5 LT 6 PZ"), (
      name: 'Estathè Limone bottiglia',
      pack: '1,5 l · 6 pz',
    ));
    expect(
      splitProductName('COCA COLA VAP 330 ML 24 PZ').name,
      'Coca Cola vetro',
    );
    expect(
      splitProductName('SCHWEPPES SELECTION LEMON & QUININE 200 ML 12 PZ').name,
      'Schweppes Selection Lemon & Quinine',
    );
  });

  test('a name without a pack keeps an empty pack', () {
    expect(splitProductName('ALIX BARBERA SUPERIORE 750 ML'), (
      name: 'Alix Barbera Superiore',
      pack: '750 ml',
    ));
    expect(splitProductName("CAFFE' IN GRANI"), (
      name: 'Caffè In Grani',
      pack: '',
    ));
  });
}
