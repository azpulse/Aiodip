class QuotaCode {
  QuotaCode({
    required this.id,
    required this.ownerId,
    required this.code,
    required this.useCount,
    this.unlockAt = 4,
    this.unlocked = false,
  });

  final String id;
  final String ownerId;
  final String code;
  final int useCount;
  final int unlockAt;
  final bool unlocked;

  factory QuotaCode.fromMap(Map<String, dynamic> m) {
    return QuotaCode(
      id: m['id'] as String,
      ownerId: m['owner_id'] as String,
      code: m['code'] as String,
      useCount: (m['use_count'] as num?)?.toInt() ?? 0,
      unlockAt: (m['unlock_at'] as num?)?.toInt() ?? 4,
      unlocked: m['unlocked'] as bool? ?? false,
    );
  }
}
