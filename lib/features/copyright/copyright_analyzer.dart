import '../../models/media_asset.dart';

/// Phase 1 copyright scanner — heuristic stub.
/// Later: Supabase Edge Function + stronger AI model.
class CopyrightAnalyzer {
  CopyrightStatus analyze(MediaAsset asset) {
    final blob =
        '${asset.title} ${asset.artist} ${asset.licenseHint ?? ''}'.toLowerCase();

    if (blob.contains('official') ||
        blob.contains('label') ||
        blob.contains('copyright') ||
        blob.contains('all rights')) {
      return CopyrightStatus.restricted;
    }

    if (blob.contains('remix') ||
        blob.contains('cover') ||
        blob.contains('sample') ||
        blob.contains('unverified')) {
      return CopyrightStatus.caution;
    }

    if (blob.contains('creative commons') ||
        blob.contains('cc0') ||
        blob.contains('royalty free') ||
        blob.contains('open license') ||
        blob.contains('public domain')) {
      return CopyrightStatus.clear;
    }

    // Default platform bias for demo catalogs
    return switch (asset.platform) {
      PlatformId.spotify => CopyrightStatus.restricted,
      PlatformId.youtube => CopyrightStatus.caution,
      PlatformId.tiktok => CopyrightStatus.caution,
      PlatformId.instagramReels => CopyrightStatus.caution,
      PlatformId.snapchatSpotlight => CopyrightStatus.caution,
      PlatformId.soundcloud => CopyrightStatus.clear,
    };
  }

  MediaAsset scan(MediaAsset asset) {
    return asset.copyWith(copyrightStatus: analyze(asset));
  }

  List<MediaAsset> scanAll(List<MediaAsset> assets) {
    return assets.map(scan).toList(growable: false);
  }
}
