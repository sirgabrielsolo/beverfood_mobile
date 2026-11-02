/// Builds an Unsplash CDN URL for a photo id, cropped to a [size] × [size]
/// square.
///
/// Every image in the app is shown square (or nearly), so a square crop lets
/// `AppNetworkImage` decode it at exactly the size it's drawn.
/// Used by the mock repositories until a real backend serves image URLs.
String unsplashImage(String photoId, {int size = 600}) {
  return 'https://images.unsplash.com/photo-$photoId'
      '?w=$size&h=$size&q=80&fit=crop&auto=format';
}
