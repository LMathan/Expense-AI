class SubscriptionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String billingCycle;
  final String category;
  final bool reminderEnabled;

  SubscriptionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.billingCycle,
    required this.category,
    required this.reminderEnabled,
  });

  factory SubscriptionModel.fromMap(Map<dynamic, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      billingCycle: map['billingCycle'] ?? 'Monthly',
      category: map['category'] ?? '',
      reminderEnabled: map['reminderEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'billingCycle': billingCycle,
      'category': category,
      'reminderEnabled': reminderEnabled,
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? billingCycle,
    String? category,
    bool? reminderEnabled,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}
