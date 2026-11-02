import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/features/products/models/product.dart';

/// Ids of the user's favourite products.
///
/// In memory only for now, so favourites are lost after a restart.
class FavouritesController extends ChangeNotifier {
  final _ids = <String>{};

  bool isFavourite(Product product) => _ids.contains(product.id);

  void toggle(Product product) {
    if (!_ids.remove(product.id)) _ids.add(product.id);
    notifyListeners();
  }
}

/// Makes the [FavouritesController] available to the widget tree.
class FavouritesScope extends InheritedNotifier<FavouritesController> {
  const FavouritesScope({
    super.key,
    required FavouritesController controller,
    required super.child,
  }) : super(notifier: controller);

  static FavouritesController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FavouritesScope>()!
        .notifier!;
  }
}
