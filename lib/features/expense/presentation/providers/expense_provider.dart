import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/hive_helper.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/models/budget_model.dart';
import '../../../../core/models/goal_model.dart';
import '../../../../core/models/subscription_model.dart';
import '../../../../core/models/bill_reminder_model.dart';
import '../../../../core/models/challenge_model.dart';

// 1. Transactions State Notifier
class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    loadTransactions();
  }

  void loadTransactions() {
    final box = Hive.box(HiveHelper.transactionsBox);
    final List<TransactionModel> items = [];
    for (var key in box.keys) {
      final map = Map<dynamic, dynamic>.from(box.get(key));
      items.add(TransactionModel.fromMap(map));
    }
    // Sort descending by date
    items.sort((a, b) => b.date.compareTo(a.date));
    state = items;
  }

  Future<void> addTransaction({
    required double amount,
    required String category,
    required String merchant,
    required String notes,
    required String paymentMethod,
    required DateTime date,
    bool isApproved = true,
    bool isRecurring = false,
    List<String> splitWith = const [],
  }) async {
    final box = Hive.box(HiveHelper.transactionsBox);
    final id = const Uuid().v4();
    final tx = TransactionModel(
      id: id,
      amount: amount,
      category: category,
      merchant: merchant,
      notes: notes,
      paymentMethod: paymentMethod,
      date: date,
      isApproved: isApproved,
      isReceiptUploaded: false,
      receiptPath: '',
      isRecurring: isRecurring,
      splitWith: splitWith,
    );

    await box.put(id, tx.toMap());
    
    // Add XP to user for logging a transaction!
    final sBox = Hive.box(HiveHelper.settingsBox);
    final currentXp = sBox.get('user_xp', defaultValue: 0) as int;
    await sBox.put('user_xp', currentXp + 15); // Log transaction rewards 15XP

    loadTransactions();
    _checkGoalProgress(amount, category);
  }

  Future<void> editTransaction(TransactionModel updated) async {
    final box = Hive.box(HiveHelper.transactionsBox);
    await box.put(updated.id, updated.toMap());
    loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box(HiveHelper.transactionsBox);
    await box.delete(id);
    loadTransactions();
  }

  void _checkGoalProgress(double amount, String category) {
    // If saving category, update goals
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  return TransactionNotifier();
});

// 2. Budget State Notifier
class BudgetNotifier extends StateNotifier<BudgetModel> {
  BudgetNotifier() : super(BudgetModel(monthlyIncome: 65000, categoryBudgets: {})) {
    loadBudget();
  }

  void loadBudget() {
    final box = Hive.box(HiveHelper.budgetsBox);
    final data = Map<dynamic, dynamic>.from(box.toMap());
    state = BudgetModel.fromMap(data);
  }

  Future<void> updateIncome(double income) async {
    final box = Hive.box(HiveHelper.budgetsBox);
    await box.put('monthly_income', income);
    loadBudget();
  }

  Future<void> updateCategoryBudget(String category, double limit) async {
    final box = Hive.box(HiveHelper.budgetsBox);
    await box.put('category_$category', limit);
    loadBudget();
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetModel>((ref) {
  return BudgetNotifier();
});

// 3. Goals State Notifier
class GoalsNotifier extends StateNotifier<List<GoalModel>> {
  GoalsNotifier() : super([]) {
    loadGoals();
  }

  void loadGoals() {
    final box = Hive.box(HiveHelper.goalsBox);
    final List<GoalModel> items = [];
    for (var key in box.keys) {
      items.add(GoalModel.fromMap(Map<dynamic, dynamic>.from(box.get(key))));
    }
    state = items;
  }

  Future<void> addGoal(String title, double target, double current, DateTime targetDate, String cat) async {
    final box = Hive.box(HiveHelper.goalsBox);
    final id = const Uuid().v4();
    final goal = GoalModel(id: id, title: title, targetAmount: target, currentAmount: current, targetDate: targetDate, category: cat);
    await box.put(id, goal.toMap());
    loadGoals();
  }

  Future<void> contributeToGoal(String id, double amount) async {
    final box = Hive.box(HiveHelper.goalsBox);
    final item = box.get(id);
    if (item != null) {
      final goal = GoalModel.fromMap(Map<dynamic, dynamic>.from(item));
      final updated = goal.copyWith(currentAmount: goal.currentAmount + amount);
      await box.put(id, updated.toMap());
      loadGoals();
    }
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalModel>>((ref) {
  return GoalsNotifier();
});

// 4. Subscriptions State Notifier
class SubscriptionsNotifier extends StateNotifier<List<SubscriptionModel>> {
  SubscriptionsNotifier() : super([]) {
    loadSubscriptions();
  }

  void loadSubscriptions() {
    final box = Hive.box(HiveHelper.subscriptionsBox);
    final List<SubscriptionModel> items = [];
    for (var key in box.keys) {
      items.add(SubscriptionModel.fromMap(Map<dynamic, dynamic>.from(box.get(key))));
    }
    state = items;
  }

  Future<void> toggleReminder(String id) async {
    final box = Hive.box(HiveHelper.subscriptionsBox);
    final item = box.get(id);
    if (item != null) {
      final sub = SubscriptionModel.fromMap(Map<dynamic, dynamic>.from(item));
      final updated = sub.copyWith(reminderEnabled: !sub.reminderEnabled);
      await box.put(id, updated.toMap());
      loadSubscriptions();
    }
  }
}

final subscriptionsProvider = StateNotifierProvider<SubscriptionsNotifier, List<SubscriptionModel>>((ref) {
  return SubscriptionsNotifier();
});

// 5. Bill Reminders State Notifier
class BillRemindersNotifier extends StateNotifier<List<BillReminderModel>> {
  BillRemindersNotifier() : super([]) {
    loadBills();
  }

  void loadBills() {
    final box = Hive.box(HiveHelper.billsBox);
    final List<BillReminderModel> items = [];
    for (var key in box.keys) {
      items.add(BillReminderModel.fromMap(Map<dynamic, dynamic>.from(box.get(key))));
    }
    state = items;
  }

  Future<void> togglePaid(String id) async {
    final box = Hive.box(HiveHelper.billsBox);
    final item = box.get(id);
    if (item != null) {
      final bill = BillReminderModel.fromMap(Map<dynamic, dynamic>.from(item));
      final updated = bill.copyWith(isPaid: !bill.isPaid);
      await box.put(id, updated.toMap());
      loadBills();
    }
  }
}

final billsProvider = StateNotifierProvider<BillRemindersNotifier, List<BillReminderModel>>((ref) {
  return billsProviderNotifier;
});

final billsProviderNotifier = BillRemindersNotifier();

// 6. Challenges State Notifier
class ChallengesNotifier extends StateNotifier<List<ChallengeModel>> {
  ChallengesNotifier() : super([]) {
    loadChallenges();
  }

  void loadChallenges() {
    final box = Hive.box(HiveHelper.challengesBox);
    final List<ChallengeModel> items = [];
    for (var key in box.keys) {
      items.add(ChallengeModel.fromMap(Map<dynamic, dynamic>.from(box.get(key))));
    }
    state = items;
  }

  Future<void> claimReward(String id) async {
    final box = Hive.box(HiveHelper.challengesBox);
    final item = box.get(id);
    if (item != null) {
      final challenge = ChallengeModel.fromMap(Map<dynamic, dynamic>.from(item));
      if (challenge.isCompleted) {
        // Reward XP to user
        final sBox = Hive.box(HiveHelper.settingsBox);
        final currentXp = sBox.get('user_xp', defaultValue: 0) as int;
        await sBox.put('user_xp', currentXp + challenge.rewardXp);
        
        // Remove completed challenge or keep logged
        await box.delete(id);
        loadChallenges();
      }
    }
  }
}

final challengesProvider = StateNotifierProvider<ChallengesNotifier, List<ChallengeModel>>((ref) {
  return ChallengesNotifier();
});
