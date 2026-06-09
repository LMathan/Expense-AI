import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static const String settingsBox = 'settings';
  static const String transactionsBox = 'transactions';
  static const String budgetsBox = 'budgets';
  static const String goalsBox = 'goals';
  static const String subscriptionsBox = 'subscriptions';
  static const String billsBox = 'bills';
  static const String challengesBox = 'challenges';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(settingsBox);
    await Hive.openBox(transactionsBox);
    await Hive.openBox(budgetsBox);
    await Hive.openBox(goalsBox);
    await Hive.openBox(subscriptionsBox);
    await Hive.openBox(billsBox);
    await Hive.openBox(challengesBox);

    // Populate mock data if empty
    await _populateMockData();
  }

  static Future<void> _populateMockData() async {
    final tBox = Hive.box(transactionsBox);
    final bBox = Hive.box(budgetsBox);
    final gBox = Hive.box(goalsBox);
    final sBox = Hive.box(subscriptionsBox);
    final blBox = Hive.box(billsBox);
    final cBox = Hive.box(challengesBox);
    final sSettings = Hive.box(settingsBox);

    // Initial user settings
    if (sSettings.isEmpty) {
      await sSettings.put('user_name', 'Mathan');
      await sSettings.put('user_email', 'mathan@expenseai.com');
      await sSettings.put('user_currency', '₹');
      await sSettings.put('theme_mode', 'dark');
      await sSettings.put('biometrics_enabled', false);
      await sSettings.put('family_wallet_id', 'fw_12345');
      await sSettings.put('user_xp', 450);
      await sSettings.put('user_level', 2);
    }

    // Mock Budgets
    if (bBox.isEmpty) {
      await bBox.put('monthly_income', 65000.0);
      await bBox.put('category_Food', 12000.0);
      await bBox.put('category_Travel', 5000.0);
      await bBox.put('category_Shopping', 10000.0);
      await bBox.put('category_Entertainment', 4000.0);
      await bBox.put('category_Bills', 20000.0);
    }

    // Mock Transactions
    if (tBox.isEmpty) {
      final now = DateTime.now();
      final mockTx = [
        {
          'id': 't1',
          'amount': 450.0,
          'category': 'Food',
          'notes': 'Swiggy Dinner Order',
          'date': now.subtract(const Duration(hours: 3)).toIso8601String(),
          'paymentMethod': 'UPI (GPay)',
          'merchant': 'Swiggy',
          'isApproved': true,
          'isReceiptUploaded': false,
          'receiptPath': '',
          'isRecurring': false,
          'splitWith': <String>[],
        },
        {
          'id': 't2',
          'amount': 250.0,
          'category': 'Travel',
          'notes': 'Uber ride to office',
          'date': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
          'paymentMethod': 'UPI (PhonePe)',
          'merchant': 'Uber',
          'isApproved': true,
          'isReceiptUploaded': false,
          'receiptPath': '',
          'isRecurring': false,
          'splitWith': <String>[],
        },
        {
          'id': 't3',
          'amount': 649.0,
          'category': 'Entertainment',
          'notes': 'Netflix Monthly Premium',
          'date': now.subtract(const Duration(days: 4)).toIso8601String(),
          'paymentMethod': 'Card (HDFC)',
          'merchant': 'Netflix',
          'isApproved': true,
          'isReceiptUploaded': false,
          'receiptPath': '',
          'isRecurring': true,
          'splitWith': <String>[],
        },
        {
          'id': 't4',
          'amount': 4200.0,
          'category': 'Shopping',
          'notes': 'Zara New Jacket',
          'date': now.subtract(const Duration(days: 5)).toIso8601String(),
          'paymentMethod': 'Card (HDFC)',
          'merchant': 'Zara',
          'isApproved': true,
          'isReceiptUploaded': true,
          'receiptPath': 'mock_receipt_zara.png',
          'isRecurring': false,
          'splitWith': <String>[],
        },
        {
          'id': 't5',
          'amount': 15000.0,
          'category': 'Rent',
          'notes': 'Rent payment for June',
          'date': DateTime(now.year, now.month, 1).toIso8601String(),
          'paymentMethod': 'NetBanking',
          'merchant': 'Apartment Owner',
          'isApproved': true,
          'isReceiptUploaded': false,
          'receiptPath': '',
          'isRecurring': true,
          'splitWith': <String>[],
        },
        {
          'id': 't6',
          'amount': 850.0,
          'category': 'Bills',
          'notes': 'ACT FiberNet broadband',
          'date': now.subtract(const Duration(days: 7)).toIso8601String(),
          'paymentMethod': 'UPI (GPay)',
          'merchant': 'ACT FiberNet',
          'isApproved': true,
          'isReceiptUploaded': false,
          'receiptPath': '',
          'isRecurring': true,
          'splitWith': <String>[],
        },
        {
          'id': 't7',
          'amount': 1200.0,
          'category': 'Fuel',
          'notes': 'Shell Petrol station',
          'date': now.subtract(const Duration(days: 3)).toIso8601String(),
          'paymentMethod': 'UPI',
          'merchant': 'Shell India',
          'isApproved': true,
          'isReceiptUploaded': false,
          'receiptPath': '',
          'isRecurring': false,
          'splitWith': <String>[],
        },
      ];

      for (var tx in mockTx) {
        await tBox.put(tx['id'], tx);
      }
    }

    // Mock Goals
    if (gBox.isEmpty) {
      await gBox.put('g1', {
        'id': 'g1',
        'title': 'Buy MacBook Pro M4',
        'targetAmount': 160000.0,
        'currentAmount': 75000.0,
        'targetDate': DateTime.now().add(const Duration(days: 120)).toIso8601String(),
        'category': 'Electronics',
      });
      await gBox.put('g2', {
        'id': 'g2',
        'title': 'Europe Vacation',
        'targetAmount': 250000.0,
        'currentAmount': 90000.0,
        'targetDate': DateTime.now().add(const Duration(days: 270)).toIso8601String(),
        'category': 'Travel',
      });
      await gBox.put('g3', {
        'id': 'g3',
        'title': 'Emergency Savings Fund',
        'targetAmount': 100000.0,
        'currentAmount': 60000.0,
        'targetDate': DateTime.now().add(const Duration(days: 180)).toIso8601String(),
        'category': 'Savings',
      });
    }

    // Mock Subscriptions
    if (sBox.isEmpty) {
      await sBox.put('s1', {
        'id': 's1',
        'title': 'Netflix Premium',
        'amount': 649.0,
        'dueDate': DateTime.now().add(const Duration(days: 16)).toIso8601String(),
        'billingCycle': 'Monthly',
        'category': 'Entertainment',
        'reminderEnabled': true,
      });
      await sBox.put('s2', {
        'id': 's2',
        'title': 'Spotify Duo',
        'amount': 149.0,
        'dueDate': DateTime.now().add(const Duration(days: 9)).toIso8601String(),
        'billingCycle': 'Monthly',
        'category': 'Music',
        'reminderEnabled': true,
      });
      await sBox.put('s3', {
        'id': 's3',
        'title': 'ChatGPT Plus',
        'amount': 1999.0,
        'dueDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'billingCycle': 'Monthly',
        'category': 'Productivity',
        'reminderEnabled': true,
      });
    }

    // Mock Bill Reminders
    if (blBox.isEmpty) {
      await blBox.put('b1', {
        'id': 'b1',
        'title': 'Bescom Electricity Bill',
        'amount': 3200.0,
        'dueDate': DateTime.now().add(const Duration(days: 6)).toIso8601String(),
        'category': 'Electricity',
        'isPaid': false,
        'recurrence': 'Monthly',
      });
      await blBox.put('b2', {
        'id': 'b2',
        'title': 'Apartment Rent',
        'amount': 15000.0,
        'dueDate': DateTime.now().add(const Duration(days: 21)).toIso8601String(),
        'category': 'Rent',
        'isPaid': false,
        'recurrence': 'Monthly',
      });
      await blBox.put('b3', {
        'id': 'b3',
        'title': 'Water Bill',
        'amount': 450.0,
        'dueDate': DateTime.now().add(const Duration(days: 11)).toIso8601String(),
        'category': 'Water',
        'isPaid': true,
        'recurrence': 'Monthly',
      });
    }

    // Mock Challenges
    if (cBox.isEmpty) {
      await cBox.put('c1', {
        'id': 'c1',
        'title': 'No Swiggy Challenge',
        'description': 'Avoid food orders for 3 consecutive days.',
        'rewardXp': 150,
        'targetDays': 3,
        'currentStreak': 2,
        'isCompleted': false,
      });
      await cBox.put('c2', {
        'id': 'c2',
        'title': 'Save ₹100 Daily',
        'description': 'Keep daily budget ₹100 below average limit.',
        'rewardXp': 100,
        'targetDays': 7,
        'currentStreak': 5,
        'isCompleted': false,
      });
      await cBox.put('c3', {
        'id': 'c3',
        'title': 'No Shopping Weekend',
        'description': 'Complete Saturday and Sunday with zero shopping expenses.',
        'rewardXp': 250,
        'targetDays': 2,
        'currentStreak': 2,
        'isCompleted': true,
      });
    }
  }
}
