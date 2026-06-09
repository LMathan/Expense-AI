class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int rewardXp;
  final int targetDays;
  final int currentStreak;
  final bool isCompleted;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXp,
    required this.targetDays,
    required this.currentStreak,
    required this.isCompleted,
  });

  factory ChallengeModel.fromMap(Map<dynamic, dynamic> map) {
    return ChallengeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rewardXp: map['rewardXp'] ?? 0,
      targetDays: map['targetDays'] ?? 1,
      currentStreak: map['currentStreak'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardXp': rewardXp,
      'targetDays': targetDays,
      'currentStreak': currentStreak,
      'isCompleted': isCompleted,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardXp,
    int? targetDays,
    int? currentStreak,
    bool? isCompleted,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardXp: rewardXp ?? this.rewardXp,
      targetDays: targetDays ?? this.targetDays,
      currentStreak: currentStreak ?? this.currentStreak,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
