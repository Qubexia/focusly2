import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

/// Handles `focusly://` URIs (payment return, etc.).
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;

  Future<void> initialize(GoRouter router) async {
    _router = router;
    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);

    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleUri(initial);
    }
  }

  void _handleUri(Uri uri) {
    final router = _router;
    if (router == null) return;
    if (uri.scheme != 'focusly') return;

    switch (uri.host) {
      case 'payment':
        _handlePaymentReturn(router, uri);
      case 'verify-email':
        _handleVerifyEmail(router, uri);
      default:
        break;
    }
  }

  void _handleVerifyEmail(GoRouter router, Uri uri) {
    final token = uri.queryParameters['token'] ?? '';
    if (token.isEmpty) return;
    router.go('/verify-email?token=${Uri.encodeQueryComponent(token)}');
  }

  void _handlePaymentReturn(GoRouter router, Uri uri) {
    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    if (segment == 'success') {
      router.go('/premium?paid=1');
      return;
    }
    if (segment == 'failure') {
      router.go('/premium?paid=0');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _router = null;
  }
}
