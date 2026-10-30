import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_card.dart';

/// Swipeable promo banners. Each page is narrower than the screen so the
/// next banner peeks in from the right edge.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.promos, this.onPromoTap});

  final List<Promo> promos;
  final ValueChanged<Promo>? onPromoTap;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            // Align pages to the left instead of centering them.
            padEnds: false,
            itemCount: widget.promos.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final promo = widget.promos[index];
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: PromoCard(
                  promo: promo,
                  onTap: widget.onPromoTap == null
                      ? null
                      : () => widget.onPromoTap!(promo),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _PageIndicator(count: widget.promos.length, current: _currentPage),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == current ? 20 : 6,
            decoration: BoxDecoration(
              color: i == current
                  ? Theme.of(context).colorScheme.primary
                  : context.palette.textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
