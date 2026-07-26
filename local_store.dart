import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import '../models/project.dart';
import '../models/quota_code.dart';

/// Persistent local backend when Supabase keys are not set.
/// Still dynamic (not hardcoded UI) — survives app restarts.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStore> open() async {
    final p = await SharedPreferences.getInstance();
    return LocalStore(p);
  }

  Profile? loadProfile() {
    final raw = _prefs.getString('profile');
    if (raw == null) return null;
    return Profile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(Profile p) async {
    await _prefs.setString('profile', jsonEncode(p.toMap()));
  }

  QuotaCode? loadQuota() {
    final raw = _prefs.getString('quota');
    if (raw == null) return null;
    return QuotaCode.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  QuotaCode? loadQuotaByCode(String code) {
    final q = loadQuota();
    if (q?.code == code.toUpperCase()) return q;
    final registry = _prefs.getStringList('quota_registry') ?? [];
    for (final r in registry) {
      final m = jsonDecode(r) as Map<String, dynamic>;
      if ((m['code'] as String).toUpperCase() == code.toUpperCase()) {
        return QuotaCode.fromMap(m);
      }
    }
    return null;
  }

  bool codeExists(String code) => loadQuotaByCode(code) != null;

  Future<void> saveQuota(QuotaCode q) async {
    await _prefs.setString(
      'quota',
      jsonEncode({
        'id': q.id,
        'owner_id': q.ownerId,
        'code': q.code,
        'use_count': q.useCount,
        'unlock_at': q.unlockAt,
        'unlocked': q.unlocked,
      }),
    );
    final registry = _prefs.getStringList('quota_registry') ?? [];
    registry.removeWhere((r) {
      final m = jsonDecode(r) as Map<String, dynamic>;
      return m['owner_id'] == q.ownerId || m['code'] == q.code;
    });
    registry.add(jsonEncode({
      'id': q.id,
      'owner_id': q.ownerId,
      'code': q.code,
      'use_count': q.useCount,
      'unlock_at': q.unlockAt,
      'unlocked': q.unlocked,
    }));
    await _prefs.setStringList('quota_registry', registry);
  }

  int redemptionCount(String code) {
    final list = _prefs.getStringList('redemptions_${code.toUpperCase()}') ?? [];
    return list.length;
  }

  Future<void> addRedemption(String code, String userId) async {
    final key = 'redemptions_${code.toUpperCase()}';
    final list = _prefs.getStringList(key) ?? [];
    if (!list.contains(userId)) {
      list.add(userId);
      await _prefs.setStringList(key, list);
    }
  }

  List<ProjectItem> loadProjects() {
    final raw = _prefs.getString('projects');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ProjectItem.fromMap(
              Map<String, dynamic>.from(e as Map),
              trackCount: (e['trackCount'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  Future<void> saveProjects(List<ProjectItem> items) async {
    await _prefs.setString(
      'projects',
      jsonEncode(items
          .map((p) => {
                'id': p.id,
                'title': p.title,
                'status': p.status,
                'trackCount': p.trackCount,
              })
          .toList()),
    );
  }

  Future<void> saveTracks(String projectId, List<TrackItem> tracks) async {
    await _prefs.setString(
      'tracks_$projectId',
      jsonEncode(tracks
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'storage_path': t.storagePath,
                'durationLabel': t.durationLabel,
              })
          .toList()),
    );
  }
}
