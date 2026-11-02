import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_banner.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_carousel.dart';

/// Home's promo carousel, loaded from the API once (the Home tab stays alive).
/// Shows placeholders of the banners' size while loading, and a retry row if
/// the server can't be reached.
class PromoSection extends StatefulWidget {
  const PromoSection({super.key, this.onPromoTap});

  final ValueChanged<Promo>? onPromoTap;

  @override
  State<PromoSection> createState() => _PromoSectionState();
}

class _PromoSectionState extends State<PromoSection> {
  Future<List<Promo>>? _promos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _promos ??= _load();
  }

  Future<List<Promo>> _load() {
    return PromoRepositoryScope.of(context).getActivePromos().catchError((
      Object error,
    ) {
      debugPrint('Promos not loaded: $error');
      throw error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _promos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return LoadErrorRow(
            message: 'Promozioni non disponibili',
            onRetry: () => setState(() {
              _promos = _load();
            }),
          );
        }
        final promos = snapshot.data;
        if (promos == null) return const _Loading();
        if (promos.isEmpty) return const SizedBox.shrink();
        return PromoCarousel(promos: promos, onPromoTap: widget.onPromoTap);
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final color = context.palette.surface;
    final box = DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: AppRadii.card),
      child: const SizedBox(
        width: PromoBanner.width,
        height: PromoBanner.height,
      ),
    );
    return SizedBox(
      height: PromoBanner.height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [box, const SizedBox(width: 12), box],
      ),
    );
  }
}
