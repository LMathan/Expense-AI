class BillReminderModel {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isPaid;
  final String recurrence;

  BillReminderModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.isPaid,
    required this.recurrence,
  });

  factory BillReminderModel.fromMap(Map<dynamic, dynamic> map) {
    return BillReminderModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      category: map['category'] ?? '',
      isPaid: map['isPaid'] ?? false,
      recurrence: map['recurrence'] ?? 'Monthly',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'isPaid': isPaid,
      'recurrence': recurrence,
    };
  }

  BillReminderModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isPaid,
    String? recurrence,
  }) {
    return BillReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
      recurrence: recurrence ?? this.recurrence,
    );
  }
}
