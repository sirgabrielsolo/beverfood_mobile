import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';

/// Network image that fills its parent, with a neutral placeholder while
/// loading and when the download fails.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(this.url, {super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _Placeholder(),
      errorBuilder: (context, error, stackTrace) =>
          const _Placeholder(icon: Icons.image_not_supported_outlined),
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
