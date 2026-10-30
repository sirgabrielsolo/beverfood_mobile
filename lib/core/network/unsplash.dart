/// Builds a resized, cropped Unsplash CDN URL for a photo id.
///
/// Used by the mock repositories until a real backend serves image URLs.
String unsplashImage(String photoId, {int width = 600}) {
  return 'https://images.unsplash.com/photo-$photoId'
      '?w=$width&q=80&fit=crop&auto=format';
}
