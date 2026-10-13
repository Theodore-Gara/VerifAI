// Rewards catalogue + spendable reward-token wallet. Plain classes (no codegen).

class Reward {
  final int id;
  final String code;
  final String title;
  final String subtitle;
  final int costTokens;
  final String imageAsset;
  final String? note;
  final bool canAfford;

  const Reward({
    required this.id,
    required this.code,
    required this.title,
    this.subtitle = '',
    this.costTokens = 0,
    this.imageAsset = '',
    this.note,
    this.canAfford = false,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: int.tryParse('${json['id']}') ?? 0,
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        costTokens: int.tryParse('${json['cost_tokens']}') ?? 0,
        imageAsset: json['image_asset'] as String? ?? '',
        note: json['note'] as String?,
        canAfford: json['can_afford'] as bool? ?? false,
      );
}

class RewardWallet {
  final int xp;
  final int level;
  final int tokens;
  final int nextLevelXp;

  const RewardWallet({this.xp = 0, this.level = 1, this.tokens = 0, this.nextLevelXp = 0});

  factory RewardWallet.fromJson(Map<String, dynamic> json) => RewardWallet(
        xp: int.tryParse('${json['xp']}') ?? 0,
        level: int.tryParse('${json['level']}') ?? 1,
        tokens: int.tryParse('${json['tokens']}') ?? 0,
        nextLevelXp: int.tryParse('${json['next_level_xp']}') ?? 0,
      );
}

class RewardsData {
  final List<Reward> rewards;
  final RewardWallet wallet;

  const RewardsData({this.rewards = const [], this.wallet = const RewardWallet()});

  factory RewardsData.fromJson(Map<String, dynamic> json) => RewardsData(
        rewards: (json['rewards'] as List<dynamic>? ?? const [])
            .map((e) => Reward.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        wallet: RewardWallet.fromJson((json['wallet'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

class RewardRedemptionResult {
  final String rewardCode;
  final String title;
  final int costTokens;
  final String status;
  final RewardWallet wallet;

  const RewardRedemptionResult({
    this.rewardCode = '',
    this.title = '',
    this.costTokens = 0,
    this.status = 'confirmed',
    this.wallet = const RewardWallet(),
  });

  factory RewardRedemptionResult.fromJson(Map<String, dynamic> json) {
    final r = (json['redemption'] as Map?)?.cast<String, dynamic>() ?? const {};
    return RewardRedemptionResult(
      rewardCode: r['reward_code'] as String? ?? r['code'] as String? ?? '',
      title: r['title'] as String? ?? '',
      costTokens: int.tryParse('${r['cost_tokens']}') ?? 0,
      status: r['status'] as String? ?? 'confirmed',
      wallet: RewardWallet.fromJson((json['wallet'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class TokenEvent {
  final int id;
  final int delta;
  final String reason;
  final String ref;
  final String createdAt;

  const TokenEvent({
    required this.id,
    required this.delta,
    required this.reason,
    required this.ref,
    required this.createdAt,
  });

  factory TokenEvent.fromJson(Map<String, dynamic> json) => TokenEvent(
        id: int.tryParse('${json['id']}') ?? 0,
        delta: int.tryParse('${json['delta']}') ?? 0,
        reason: json['reason'] as String? ?? '',
        ref: json['ref'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class TokenHistory {
  final List<TokenEvent> events;
  final RewardWallet wallet;

  const TokenHistory({this.events = const [], this.wallet = const RewardWallet()});

  factory TokenHistory.fromJson(Map<String, dynamic> json) => TokenHistory(
        events: (json['events'] as List<dynamic>? ?? const [])
            .map((e) => TokenEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        wallet: RewardWallet.fromJson((json['wallet'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}
