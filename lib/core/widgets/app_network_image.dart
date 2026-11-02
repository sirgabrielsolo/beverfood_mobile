import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';

/// Network image that fills its parent, with a neutral placeholder while
/// loading and when the download fails.
///
/// The image is decoded at the size it's drawn rather than at full
/// resolution, which keeps scrolling smooth. This assumes the source has the
/// box's aspect ratio, or is square (see `unsplashImage`): its width is
/// decoded to the box's longer side.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;

  /// `BoxFit.contain` for product cut-outs, which should never be cropped.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The longer side, so `BoxFit.cover` never has to upscale.
        final side = constraints.biggest.longestSide;
        final cacheSize = side.isFinite ? (side * pixelRatio).ceil() : null;

        return Image.network(
          url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheSize,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const _Placeholder(),
          errorBuilder: (context, error, stackTrace) =>
              const _Placeholder(icon: Icons.image_not_supported_outlined),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.imagePlaceholder,
      child: icon == null
          ? const SizedBox.expand()
          : Center(child: Icon(icon, color: context.palette.textSecondary)),
    );
  }
}
