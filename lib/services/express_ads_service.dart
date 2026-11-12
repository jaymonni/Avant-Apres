import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shared, discreet interstitials at natural transitions after completed actions.
/// Debug uses Google's test unit; Android release uses the production unit.
class ExpressAdsService {
  factory ExpressAdsService() => _instance;
  ExpressAdsService._();
  static final ExpressAdsService _instance = ExpressAdsService._();

  static const int actionsPerAd = 6;
  static const Duration minimumInterval = Duration(minutes: 5);
  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _productionAdUnitId =
      'ca-app-pub-6335107042829950/8099311749';

  bool get _supported => Platform.isAndroid;
  String get _adUnitId => kReleaseMode ? _productionAdUnitId : _testAdUnitId;

  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;
  int _completedActions = 0;
  final DateTime _openedAt = DateTime.now();
  DateTime? _lastShownAt;

  void load() {
    if (!_supported || _loading || _showing || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Interstitial ad unavailable: $error');
        },
      ),
    );
  }

  /// Call only after a successful create, complete, save, export or share.
  /// Never interrupts an editor or a user action in progress.
  void onCompletedAction() {
    if (!_supported) return;
    _completedActions++;
    load();
    if (_completedActions < actionsPerAd) return;
    final now = DateTime.now();
    if (now.difference(_openedAt) < minimumInterval ||
        (_lastShownAt != null &&
            now.difference(_lastShownAt!) < minimumInterval)) {
      return;
    }
    final ad = _ad;
    if (ad == null || _showing) return;
    _ad = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showing = false;
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _showing = false;
        // Keep the count so a later completed action can retry.
        load();
      },
    );
    ad.show();
    _completedActions = 0;
    _lastShownAt = now;
  }

  void onSuccessfulExport() => onCompletedAction();
}
