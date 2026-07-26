enum PlatformId {
  youtube,
  soundcloud,
  spotify,
  tiktok,
  instagramReels,
  snapchatSpotlight,
}

extension PlatformIdX on PlatformId {
  String get label => switch (this) {
        PlatformId.youtube => 'YouTube',
        PlatformId.soundcloud => 'SoundCloud',
        PlatformId.spotify => 'Spotify',
        PlatformId.tiktok => 'TikTok',
        PlatformId.instagramReels => 'Instagram Reels',
        PlatformId.snapchatSpotlight => 'Snapchat Spotlight',
      };

  String get shortLabel => switch (this) {
        PlatformId.youtube => 'YT',
        PlatformId.soundcloud => 'SC',
        PlatformId.spotify => 'SP',
        PlatformId.tiktok => 'TT',
        PlatformId.instagramReels => 'IG',
        PlatformId.snapchatSpotlight => 'SNAP',
      };
}

enum MediaType { audio, video }

enum CopyrightStatus {
  /// Re-use / publishing prohibited
  restricted,

  /// Potential restrictions — use with caution
  caution,

  /// Safe / open for use
  clear,
}

extension CopyrightStatusX on CopyrightStatus {
  String get label => switch (this) {
        CopyrightStatus.restricted => 'Restricted',
        CopyrightStatus.caution => 'Caution',
        CopyrightStatus.clear => 'Clear',
      };
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.platform,
    required this.title,
    required this.artist,
    required this.mediaType,
    required this.copyrightStatus,
    this.durationLabel = '3:00',
    this.previewUrl,
    this.licenseHint,
  });

  final String id;
  final PlatformId platform;
  final String title;
  final String artist;
  final MediaType mediaType;
  final CopyrightStatus copyrightStatus;
  final String durationLabel;
  final String? previewUrl;
  final String? licenseHint;

  MediaAsset copyWith({CopyrightStatus? copyrightStatus}) {
    return MediaAsset(
      id: id,
      platform: platform,
      title: title,
      artist: artist,
      mediaType: mediaType,
      copyrightStatus: copyrightStatus ?? this.copyrightStatus,
      durationLabel: durationLabel,
      previewUrl: previewUrl,
      licenseHint: licenseHint,
    );
  }
}
