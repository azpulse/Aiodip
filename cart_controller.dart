import 'package:flutter/foundation.dart';

import '../../models/media_asset.dart';

class CartController extends ChangeNotifier {
  final List<MediaAsset> _items = [];

  List<MediaAsset> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  bool contains(MediaAsset asset) => _items.any((a) => a.id == asset.id);

  void add(MediaAsset asset) {
    if (contains(asset)) return;
    _items.add(asset);
    notifyListeners();
  }

  void remove(MediaAsset asset) {
    _items.removeWhere((a) => a.id == asset.id);
    notifyListeners();
  }

  void toggle(MediaAsset asset) {
    if (contains(asset)) {
      remove(asset);
    } else {
      add(asset);
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
