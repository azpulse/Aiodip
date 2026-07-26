class Profile {
  Profile({
    required this.id,
    this.email,
    this.displayName,
    this.plan = 'none',
    this.priceCents = 1600,
    this.subscriptionStatus = 'inactive',
    this.appliedQuotaCode,
    this.trialEndsAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String plan;
  final int priceCents;
  final String subscriptionStatus;
  final String? appliedQuotaCode;
  final DateTime? trialEndsAt;

  bool get isEntitled =>
      subscriptionStatus == 'active' || subscriptionStatus == 'trialing';

  bool get isQuotaPrice => priceCents <= 320;

  factory Profile.fromMap(Map<String, dynamic> m) {
    return Profile(
      id: m['id'] as String,
      email: m['email'] as String?,
      displayName: m['display_name'] as String?,
      plan: (m['plan'] as String?) ?? 'none',
      priceCents: (m['price_cents'] as num?)?.toInt() ?? 1600,
      subscriptionStatus: (m['subscription_status'] as String?) ?? 'inactive',
      appliedQuotaCode: m['applied_quota_code'] as String?,
      trialEndsAt: m['trial_ends_at'] != null
          ? DateTime.tryParse(m['trial_ends_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'plan': plan,
        'price_cents': priceCents,
        'subscription_status': subscriptionStatus,
        'applied_quota_code': appliedQuotaCode,
        'trial_ends_at': trialEndsAt?.toIso8601String(),
      };

  Profile copyWith({
    String? email,
    String? displayName,
    String? plan,
    int? priceCents,
    String? subscriptionStatus,
    String? appliedQuotaCode,
    DateTime? trialEndsAt,
  }) {
    return Profile(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      plan: plan ?? this.plan,
      priceCents: priceCents ?? this.priceCents,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      appliedQuotaCode: appliedQuotaCode ?? this.appliedQuotaCode,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
    );
  }
}
