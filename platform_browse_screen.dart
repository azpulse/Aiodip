import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/media_asset.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_review_screen.dart';
import '../copyright/copyright_analyzer.dart';
import '../copyright/copyright_badge.dart';
import 'adapters/platform_adapter.dart';

class PlatformBrowseScreen extends StatefulWidget {
  const PlatformBrowseScreen({super.key, required this.platformId});

  final PlatformId platformId;

  @override
  State<PlatformBrowseScreen> createState() => _PlatformBrowseScreenState();
}

class _PlatformBrowseScreenState extends State<PlatformBrowseScreen> {
  final _analyzer = CopyrightAnalyzer();
  late final PlatformAdapter _adapter;

  bool _loading = false;
  bool _signingIn = false;
  String? _error;
  List<MediaAsset> _assets = const [];

  @override
  void initState() {
    super.initState();
    _adapter = context.read<PlatformRegistry>().get(widget.platformId);
    if (_adapter.isSignedIn) {
      _loadAssets();
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await _adapter.signIn();
      await _loadAssets();
    } catch (e) {
      setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _adapter.listAssets();
      final scanned = _analyzer.scanAll(raw);
      if (mounted) setState(() => _assets = scanned);
    } catch (e) {
      if (mounted) setState(() => _error = 'Browse failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.platformId.label),
        actions: [
          TextButton.icon(
            onPressed: cart.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CartReviewScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text('${cart.count}'),
          ),
        ],
      ),
      body: !_adapter.isSignedIn
          ? _AuthPane(
              platform: widget.platformId.label,
              signingIn: _signingIn,
              error: _error,
              onSignIn: _signIn,
            )
          : _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : Column(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.copyrightRed),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _assets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final asset = _assets[index];
                          final inCart = cart.contains(asset);
                          return _AssetTile(
                            asset: asset,
                            inCart: inCart,
                            onAdd: () => cart.add(asset),
                            onRemove: () => cart.remove(asset),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CartReviewScreen(),
                      ),
                    );
                  },
                  child: Text('Done — cart (${cart.count})'),
                ),
              ),
            ),
    );
  }
}

class _AuthPane extends StatelessWidget {
  const _AuthPane({
    required this.platform,
    required this.signingIn,
    required this.onSignIn,
    this.error,
  });

  final String platform;
  final bool signingIn;
  final VoidCallback onSignIn;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connect $platform',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Phase 1 uses a mock sign-in so you can browse demo catalogs. '
                'Real OAuth will plug into each platform adapter later.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: AppColors.copyrightRed)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: signingIn ? null : onSignIn,
                child: signingIn
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Log in to $platform'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.asset,
    required this.inCart,
    required this.onAdd,
    required this.onRemove,
  });

  final MediaAsset asset;
  final bool inCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              asset.mediaType == MediaType.video
                  ? Icons.movie_outlined
                  : Icons.audiotrack,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${asset.artist} · ${asset.durationLabel} · ${asset.mediaType.name}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                CopyrightBadge(status: asset.copyrightStatus, compact: true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (inCart)
            OutlinedButton(
              onPressed: onRemove,
              child: const Text('Added'),
            )
          else
            ElevatedButton(
              onPressed: asset.copyrightStatus == CopyrightStatus.restricted
                  ? null
                  : onAdd,
              child: const Text('Add to Cart'),
            ),
        ],
      ),
    );
  }
}
