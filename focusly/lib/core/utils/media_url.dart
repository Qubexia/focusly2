import '../constants/api_endpoints.dart';

/// Resolves a media path/URL against the configured API base when needed.
///
/// - Absolute `http(s)://...` URLs (e.g. Google avatar) are kept as-is.
/// - Relative `/uploads/...` paths are prefixed with [ApiEndpoints.baseUrl].
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return trimmed;
  }

  if (trimmed.startsWith('/')) {
    return '${ApiEndpoints.baseUrl}$trimmed';
  }

  return '${ApiEndpoints.baseUrl}/$trimmed';
}
