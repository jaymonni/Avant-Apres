import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Discreet ads: never block an export, never interrupt photo editing.
class ExpressAdsService {
  InterstitialAd? _ad;
  bool _disposed = false;
  int _successfulExports = 0;
  DateTime _openedAt = DateTime.now();
  DateTime? _lastShownAt;

  // Test-only until a dedicated production interstitial unit is configured.
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  void load() {
    if (_disposed || _ad != null) return;
    InterstitialAd.load(
      adUnitId: _testAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
          } else {
            _ad = ad;
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('Express interstitial unavailable: $error');
        },
      ),
    );
  }

  void onSuccessfulExport() {
    if (_disposed) return;
    _successfulExports++;
    final now = DateTime.now();
    if (_successfulExports < 3 ||
        now.difference(_openedAt) < const Duration(minutes: 5) ||
        (_lastShownAt != null &&
            now.difference(_lastShownAt!) < const Duration(minutes: 5))) {
      return;
    }
    final ad = _ad;
    if (ad == null) return;
    _ad = null;
    _successfulExports = 0;
    _lastShownAt = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        load();
      },
    );
    ad.show();
  }

  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }
}
