import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';

/// The active promotions, from the web app's API.
class PromoRepository {
  PromoRepository(this._api);

  final ApiClient _api;

  /// Active promos in the order of the Home banners. Throws [ApiException]
  /// when the server can't be reached.
  Future<List<Promo>> getActivePromos() async {
    final json = await _api.getJson('/api/v1/promos') as Map<String, Object?>;
    return [
      for (final promo in json['promos'] as List)
        Promo.fromJson(promo as Map<String, Object?>),
    ];
  }
}

/// Exposes the app's [PromoRepository]; `BeverfoodApp` owns it, so tests can
/// pass one backed by a fake HTTP client.
class PromoRepositoryScope extends InheritedWidget {
  const PromoRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final PromoRepository repository;

  static PromoRepository of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PromoRepositoryScope>()!
        .repository;
  }

  @override
  bool updateShouldNotify(PromoRepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
