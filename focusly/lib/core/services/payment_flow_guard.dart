/// Prevents duplicate payment-success handling when Paymob SDK, deep links,
/// and paywall listeners all fire for the same transaction.
class PaymentFlowGuard {
  PaymentFlowGuard._();

  static final PaymentFlowGuard instance = PaymentFlowGuard._();

  DateTime? _lastSuccessHandledAt;
  bool _syncInProgress = false;

  static const _dedupeWindow = Duration(seconds: 12);

  /// Returns `true` when this caller should run success UI/sync logic.
  bool claimSuccessHandling() {
    final now = DateTime.now();
    final last = _lastSuccessHandledAt;
    if (last != null && now.difference(last) < _dedupeWindow) {
      return false;
    }
    _lastSuccessHandledAt = now;
    return true;
  }

  bool get isSyncInProgress => _syncInProgress;

  Future<void> runSync(Future<void> Function() action) async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      await action();
    } finally {
      _syncInProgress = false;
    }
  }
}
