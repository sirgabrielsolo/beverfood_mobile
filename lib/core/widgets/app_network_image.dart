import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';

/// Network image that fills its parent, with a neutral placeholder while
/// loading and when the download fails.
///
/// The image is decoded at the size it's drawn rather than at full
/// resolution, which keeps scrolling smooth. This assumes the source has the
/// box's aspect ratio, or is square: its width is
/// decoded to the box's longer side.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(this.url, {super.key, this.fit = BoxFit.cover});

  /// Where images come from. `main()` sets a provider that keeps them on the
  /// device's disk (`CachedNetworkImageProvider`), so a photo seen once isn't
  /// downloaded again; tests keep the plain [NetworkImage].
  static ImageProvider Function(String url) provider = NetworkImage.new;

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

        return Image(
          image: ResizeImage.resizeIfNeeded(cacheSize, null, provider(url)),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
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
