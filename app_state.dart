import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/supabase_config.dart';
import '../models/profile.dart';
import '../models/project.dart';
import '../models/quota_code.dart';
import 'billing_service.dart';
import 'local_store.dart';

/// App session: auth, quota, entitlement, projects.
/// Billing is native App Store / Google Play only (never web).
class AppState extends ChangeNotifier {
  AppState({BillingService? billing}) : billing = billing ?? BillingService();

  final BillingService billing;
  final _uuid = const Uuid();
  LocalStore? _local;

  Profile? profile;
  QuotaCode? myQuota;
  String? pendingQuotaCode; // invitee code for $3.20 checkout
  bool checkoutQuota = false;
  bool unlockedByInvites = false;
  List<ProjectItem> projects = [];
  List<TrackItem> draftTracks = [];
  String? currentProjectId;
  String? error;
  bool busy = false;
  bool ready = false;

  bool get usingSupabase => SupabaseConfig.isConfigured;
  SupabaseClient? get _sb =>
      usingSupabase ? Supabase.instance.client : null;

  bool get isLoggedIn => profile != null;
  bool get isEntitled => profile?.isEntitled ?? false;

  Future<void> init() async {
    _local = await LocalStore.open();
    billing.onVerifiedPurchase = (purchase) async {
      if (profile == null) return;
      try {
        await _applyStoreEntitlement(productId: purchase.productID);
        notifyListeners();
      } catch (_) {}
    };
    await billing.init();
    billing.addListener(notifyListeners);
    if (usingSupabase) {
      final session = _sb!.auth.currentSession;
      if (session != null) {
        await refreshProfile();
        await refreshQuota();
        await refreshProjects();
      }
    } else {
      profile = _local!.loadProfile();
      myQuota = _local!.loadQuota();
      projects = _local!.loadProjects();
    }
    ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    billing.removeListener(notifyListeners);
    billing.dispose();
    super.dispose();
  }

  Future<void> _setBusy(Future<void> Function() fn) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await fn();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ——— Auth ———
  Future<void> signUp(String email, String password, {String? name}) async {
    await _setBusy(() async {
      if (usingSupabase) {
        final res = await _sb!.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'display_name': name ?? email.split('@').first},
        );
        if (res.user == null) throw Exception('Sign up failed');
        await refreshProfile();
      } else {
        final id = _uuid.v4();
        profile = Profile(
          id: id,
          email: email.trim(),
          displayName: name ?? email.split('@').first,
        );
        await _local!.saveProfile(profile!);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    await _setBusy(() async {
      if (usingSupabase) {
        await _sb!.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        await refreshProfile();
        await refreshQuota();
        await refreshProjects();
      } else {
        var p = _local!.loadProfile();
        if (p == null || p.email != email.trim()) {
          // create local session for demo if missing
          p = Profile(
            id: _uuid.v4(),
            email: email.trim(),
            displayName: email.split('@').first,
          );
        }
        profile = p;
        await _local!.saveProfile(p);
        myQuota = _local!.loadQuota();
        projects = _local!.loadProjects();
      }
    });
  }

  Future<void> signOut() async {
    if (usingSupabase) await _sb!.auth.signOut();
    profile = null;
    myQuota = null;
    projects = [];
    draftTracks = [];
    pendingQuotaCode = null;
    checkoutQuota = false;
    unlockedByInvites = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!usingSupabase) return;
    final uid = _sb!.auth.currentUser?.id;
    if (uid == null) return;
    final row =
        await _sb!.from('profiles').select().eq('id', uid).maybeSingle();
    if (row != null) {
      profile = Profile.fromMap(Map<String, dynamic>.from(row));
    }
    notifyListeners();
  }

  Future<void> saveProfile({required String name, required String email}) async {
    await _setBusy(() async {
      if (profile == null) throw Exception('Not logged in');
      if (usingSupabase) {
        await _sb!.from('profiles').update({
          'display_name': name.trim(),
          'email': email.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', profile!.id);
        await refreshProfile();
      } else {
        profile = profile!.copyWith(
          displayName: name.trim(),
          email: email.trim(),
        );
        await _local!.saveProfile(profile!);
      }
    });
  }

  // ——— Quota ———
  Future<void> refreshQuota() async {
    if (profile == null) return;
    if (usingSupabase) {
      final row = await _sb!
          .from('quota_codes')
          .select()
          .eq('owner_id', profile!.id)
          .maybeSingle();
      myQuota = row == null
          ? null
          : QuotaCode.fromMap(Map<String, dynamic>.from(row));
    } else {
      myQuota = _local!.loadQuota();
      // recompute unlock from redemptions
      if (myQuota != null) {
        final count = _local!.redemptionCount(myQuota!.code);
        myQuota = QuotaCode(
          id: myQuota!.id,
          ownerId: myQuota!.ownerId,
          code: myQuota!.code,
          useCount: count,
          unlockAt: AppConstants.quotaUnlockAt,
          unlocked: count >= AppConstants.quotaUnlockAt,
        );
        await _local!.saveQuota(myQuota!);
      }
    }
    notifyListeners();
  }

  Future<void> createQuotaCode(String raw) async {
    await _setBusy(() async {
      if (profile == null) throw Exception('Log in first to create a code');
      var code = raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');
      if (!code.startsWith('AIODIP-')) code = 'AIODIP-$code';
      if (code.length < 8) throw Exception('Code is too short');

      if (usingSupabase) {
        final row = await _sb!.rpc('create_quota_code', params: {'p_code': code});
        myQuota = QuotaCode.fromMap(Map<String, dynamic>.from(row as Map));
      } else {
        myQuota = QuotaCode(
          id: _uuid.v4(),
          ownerId: profile!.id,
          code: code,
          useCount: 0,
          unlockAt: AppConstants.quotaUnlockAt,
          unlocked: false,
        );
        await _local!.saveQuota(myQuota!);
      }
    });
  }

  Future<void> applyQuotaCode(String raw) async {
    await _setBusy(() async {
      final code = raw.trim().toUpperCase();
      if (code.length < 4) throw Exception('Enter a valid quota code');

      if (profile == null) {
        // allow applying before login — stash for checkout
        pendingQuotaCode = code;
        checkoutQuota = true;
        unlockedByInvites = false;
        return;
      }

      if (usingSupabase) {
        await _sb!.rpc('redeem_quota_code', params: {'p_code': code});
        await refreshProfile();
        pendingQuotaCode = code;
        checkoutQuota = true;
        unlockedByInvites = false;
      } else {
        if (myQuota?.code == code) {
          throw Exception('You cannot use your own code');
        }
        // Validate against stored codes map
        final ok = _local!.codeExists(code) || code.startsWith('AIODIP-');
        if (!ok) throw Exception('Invalid quota code');
        await _local!.addRedemption(code, profile!.id);
        profile = profile!.copyWith(
          appliedQuotaCode: code,
          plan: 'quota',
          priceCents: AppConstants.priceQuotaCents,
        );
        await _local!.saveProfile(profile!);
        // bump owner if local
        final ownerQuota = _local!.loadQuotaByCode(code);
        if (ownerQuota != null) {
          final c = _local!.redemptionCount(code);
          await _local!.saveQuota(QuotaCode(
            id: ownerQuota.id,
            ownerId: ownerQuota.ownerId,
            code: ownerQuota.code,
            useCount: c,
            unlockAt: ownerQuota.unlockAt,
            unlocked: c >= ownerQuota.unlockAt,
          ));
        }
        pendingQuotaCode = code;
        checkoutQuota = true;
        unlockedByInvites = false;
        await refreshQuota();
      }
    });
  }

  void prepareFullCheckout() {
    checkoutQuota = false;
    unlockedByInvites = false;
    pendingQuotaCode = null;
    notifyListeners();
  }

  void prepareInviterQuotaCheckout() {
    if (myQuota == null || !myQuota!.unlocked) return;
    checkoutQuota = true;
    unlockedByInvites = true;
    pendingQuotaCode = null;
    notifyListeners();
  }

  /// Opens App Store / Google Play sheet, then unlocks entitlement only after purchase.
  Future<void> subscribeViaStore() async {
    await _setBusy(() async {
      if (profile == null) throw Exception('Create an account or log in first');

      final purchase = await billing.purchaseSubscription(
        quotaPrice: checkoutQuota,
      );

      await _applyStoreEntitlement(productId: purchase.productID);
    });
  }

  Future<void> restoreStorePurchases() async {
    await _setBusy(() async {
      if (profile == null) throw Exception('Log in first');
      await billing.restorePurchases();
      // Entitlement is applied when purchaseStream delivers restored items.
      // If products already active, mark from known product ids after short wait.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (billing.monthlyProduct != null || billing.quotaProduct != null) {
        // Restore does not always re-emit; keep user on gate until a purchase event.
      }
    });
  }

  Future<void> _applyStoreEntitlement({required String productId}) async {
    final isQuota = productId == AppConstants.productQuotaMonthly || checkoutQuota;
    if (isQuota) {
      profile = profile!.copyWith(
        plan: 'quota',
        priceCents: AppConstants.priceQuotaCents,
        subscriptionStatus: 'active',
        appliedQuotaCode: pendingQuotaCode ?? profile!.appliedQuotaCode,
      );
      if (pendingQuotaCode != null && !usingSupabase) {
        await _local!.addRedemption(pendingQuotaCode!, profile!.id);
      }
    } else {
      // 7-day free trial is configured on the store product itself.
      final trialEnd =
          DateTime.now().add(const Duration(days: AppConstants.trialDays));
      profile = profile!.copyWith(
        plan: 'trial',
        priceCents: AppConstants.priceFullCents,
        subscriptionStatus: 'trialing',
        trialEndsAt: trialEnd,
      );
    }

    if (usingSupabase) {
      await _sb!.from('profiles').update({
        'plan': profile!.plan,
        'price_cents': profile!.priceCents,
        'subscription_status': profile!.subscriptionStatus,
        'trial_ends_at': profile!.trialEndsAt?.toIso8601String(),
        'applied_quota_code': profile!.appliedQuotaCode,
        'store_product_id': productId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profile!.id);
    } else {
      await _local!.saveProfile(profile!);
      await refreshQuota();
    }
  }

  // ——— Projects / tracks ———
  Future<void> refreshProjects() async {
    if (profile == null) return;
    if (usingSupabase) {
      final rows = await _sb!
          .from('projects')
          .select('id, title, status')
          .eq('owner_id', profile!.id)
          .order('updated_at', ascending: false);
      final list = <ProjectItem>[];
      for (final r in rows as List) {
        final m = Map<String, dynamic>.from(r as Map);
        final tracks = await _sb!
            .from('project_tracks')
            .select('id')
            .eq('project_id', m['id']);
        list.add(ProjectItem.fromMap(m, trackCount: (tracks as List).length));
      }
      projects = list;
    } else {
      projects = _local!.loadProjects();
    }
    notifyListeners();
  }

  Future<void> addDraftTrack(String fileName, {String? path}) async {
    draftTracks = [
      ...draftTracks,
      TrackItem(
        id: _uuid.v4(),
        name: fileName,
        storagePath: path,
        durationLabel: 'Track ${draftTracks.length + 1}',
      ),
    ];
    notifyListeners();
  }

  Future<void> saveDraftProject({String title = 'New mix'}) async {
    await _setBusy(() async {
      if (profile == null) throw Exception('Not logged in');
      if (draftTracks.isEmpty) throw Exception('Add at least one audio file');

      if (usingSupabase) {
        final proj = await _sb!.from('projects').insert({
          'owner_id': profile!.id,
          'title': title,
          'status': 'ready',
        }).select().single();
        final pid = proj['id'] as String;
        currentProjectId = pid;
        var i = 0;
        for (final t in draftTracks) {
          await _sb!.from('project_tracks').insert({
            'project_id': pid,
            'name': t.name,
            'storage_path': t.storagePath,
            'sort_order': i++,
          });
        }
        draftTracks = [];
        await refreshProjects();
      } else {
        final id = _uuid.v4();
        currentProjectId = id;
        final item = ProjectItem(
          id: id,
          title: title,
          trackCount: draftTracks.length,
          status: 'ready',
        );
        projects = [item, ...projects];
        await _local!.saveProjects(projects);
        await _local!.saveTracks(id, draftTracks);
        draftTracks = [];
      }
    });
  }
}
