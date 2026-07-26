import '../../../models/media_asset.dart';

abstract class PlatformAdapter {
  PlatformId get platform;
  String get displayName;
  Future<bool> signIn();
  Future<void> signOut();
  bool get isSignedIn;
  Future<List<MediaAsset>> listAssets();
}

class MockPlatformAdapter implements PlatformAdapter {
  MockPlatformAdapter({
    required this.platform,
    required List<MediaAsset> catalog,
  }) : _catalog = catalog;

  @override
  final PlatformId platform;

  final List<MediaAsset> _catalog;
  bool _signedIn = false;

  @override
  String get displayName => platform.label;

  @override
  bool get isSignedIn => _signedIn;

  @override
  Future<bool> signIn() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _signedIn = true;
    return true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
  }

  @override
  Future<List<MediaAsset>> listAssets() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!_signedIn) return const [];
    return List.unmodifiable(_catalog);
  }
}

class PlatformRegistry {
  PlatformRegistry(this.adapters);

  final Map<PlatformId, PlatformAdapter> adapters;

  PlatformAdapter get(PlatformId id) {
    final adapter = adapters[id];
    if (adapter == null) {
      throw StateError('No adapter registered for $id');
    }
    return adapter;
  }

  static PlatformRegistry mock() {
    return PlatformRegistry({
      for (final id in PlatformId.values) id: MockPlatformAdapter(
        platform: id,
        catalog: _mockCatalog(id),
      ),
    });
  }
}

List<MediaAsset> _mockCatalog(PlatformId platform) {
  final samples = <(String, String, MediaType, String)>[
    ('Night Drive Official', 'Label Records', MediaType.audio, 'all rights'),
    ('Sunset Bounce Remix', 'DJ Nova', MediaType.audio, 'remix'),
    ('Open Roof CC0 Beat', 'FreeWave', MediaType.audio, 'creative commons'),
    ('City Lights Clip', 'Visual Lab', MediaType.video, 'unverified'),
    ('Royalty Free Pulse', 'OpenKit', MediaType.audio, 'royalty free'),
    ('Club Anthem 2024', 'Major Label', MediaType.audio, 'copyright'),
  ];

  return [
    for (var i = 0; i < samples.length; i++)
      MediaAsset(
        id: '${platform.name}_$i',
        platform: platform,
        title: samples[i].$1,
        artist: samples[i].$2,
        mediaType: samples[i].$3,
        copyrightStatus: CopyrightStatus.caution,
        durationLabel: i.isEven ? '3:24' : '2:58',
        licenseHint: samples[i].$4,
      ),
  ];
}
