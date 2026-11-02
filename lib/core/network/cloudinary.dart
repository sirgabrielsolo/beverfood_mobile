/// A Cloudinary image URL turned into a resized WebP of at most [width]
/// pixels, the size a card draws it at: Beck's cut-out is 7.6 KB at 300 px
/// instead of the 76.6 KB PNG. Other URLs are returned unchanged.
///
/// Cloudinary renders each size once and then serves it from its CDN.
String cloudinaryThumbnail(String url, {int width = 400}) {
  const marker = '/image/upload/';
  final at = url.indexOf(marker);
  if (at < 0 || !url.contains('res.cloudinary.com')) return url;
  final end = at + marker.length;
  return '${url.substring(0, end)}w_$width,c_limit,f_webp,q_auto/'
      '${url.substring(end)}';
}
