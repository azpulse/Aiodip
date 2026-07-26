class AppConstants {
  static const int priceFullCents = 1600;
  static const int priceQuotaCents = 320;
  static const int quotaUnlockAt = 4;
  static const int trialDays = 7;

  /// App Store Connect + Google Play Console subscription product IDs.
  /// Configure 7-day free trial on [productMonthly] in the store consoles.
  static const String productMonthly = 'dj_aiodip_pro_monthly';

  /// Separate $3.20/mo subscription (or Play/App offer mapped to this id).
  static const String productQuotaMonthly = 'dj_aiodip_pro_quota_monthly';

  static String money(int cents) {
    final dollars = cents / 100;
    if (dollars == dollars.roundToDouble()) {
      return '\$${dollars.toInt()}';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }
}
