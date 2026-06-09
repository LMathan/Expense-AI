import 'package:hive/hive.dart';
import '../storage/hive_helper.dart';

class AiService {
  // Generates customized financial insights cards for the AI dashboard
  List<Map<String, dynamic>> generateInsights() {
    final tBox = Hive.box(HiveHelper.transactionsBox);
    final bBox = Hive.box(HiveHelper.budgetsBox);

    final income = bBox.get('monthly_income', defaultValue: 65000.0) as double;
    
    // Calculate category spending
    double foodSpent = 0;
    double shoppingSpent = 0;
    double totalSpent = 0;

    for (var key in tBox.keys) {
      final tx = Map<String, dynamic>.from(tBox.get(key));
      final amt = tx['amount'] as double;
      final cat = tx['category'] as String;
      totalSpent += amt;
      if (cat == 'Food') foodSpent += amt;
      if (cat == 'Shopping') shoppingSpent += amt;
    }

    final savings = income - totalSpent;
    final List<Map<String, dynamic>> insights = [];

    // Insight 1: Food spend warning
    if (foodSpent > 4000) {
      insights.add({
        'title': 'High Food Spending Alert',
        'description': 'You have spent ₹${foodSpent.toStringAsFixed(0)} on food delivery and dining. Reducing online orders by 20% could save you ₹1,500.',
        'type': 'warning',
        'savingPotential': 1500.0,
      });
    }

    // Insight 2: Shopping speed check
    if (shoppingSpent > 3000) {
      insights.add({
        'title': 'Shopping Momentum',
        'description': 'Shopping accounts for ${(shoppingSpent / income * 100).toStringAsFixed(0)}% of your monthly income. Wait 48 hours before your next check-out to avoid impulse buys.',
        'type': 'suggestion',
        'savingPotential': 1200.0,
      });
    }

    // Insight 3: General positive check
    if (savings > income * 0.3) {
      insights.add({
        'title': 'Healthy Savings Rate',
        'description': 'Amazing job! You have saved ₹${savings.toStringAsFixed(0)} (${(savings / income * 100).toStringAsFixed(0)}% of income) so far this month.',
        'type': 'success',
        'savingPotential': 0.0,
      });
    } else {
      insights.add({
        'title': 'Savings Boost Opportunity',
        'description': 'Your current savings rate is below 15%. Directing ₹3,000 into a recurring deposit immediately on payday can automate your savings goals.',
        'type': 'tip',
        'savingPotential': 3000.0,
      });
    }

    return insights;
  }

  // Answers custom questions in natural language, using actual user budget parameters
  String answerFinancialQuery(String query) {
    final tBox = Hive.box(HiveHelper.transactionsBox);
    final bBox = Hive.box(HiveHelper.budgetsBox);

    final income = bBox.get('monthly_income', defaultValue: 65000.0) as double;
    double totalSpent = 0;
    for (var key in tBox.keys) {
      final tx = Map<String, dynamic>.from(tBox.get(key));
      totalSpent += tx['amount'] as double;
    }

    final balance = income - totalSpent;
    final q = query.toLowerCase();

    // 1. Can I afford question
    if (q.contains('afford') || q.contains('buy')) {
      // Extract amount
      final amtMatch = RegExp(r'(\d+[\d,]*\d*)').firstMatch(q);
      if (amtMatch != null) {
        final rawAmt = amtMatch.group(1)?.replaceAll(',', '') ?? '0';
        final itemAmt = double.tryParse(rawAmt) ?? 0.0;

        if (itemAmt <= 0) {
          return "I can help you calculate if you can afford an item. Could you specify the price of the item you want to buy?";
        }

        if (itemAmt > income * 3) {
          return "At ₹${itemAmt.toStringAsFixed(0)}, this is a major long-term capital expense (exceeds 3 months of your gross income). Buying this immediately is NOT recommended unless you have a designated savings bucket, as it would severely compromise your financial security.";
        }

        if (itemAmt > balance) {
          final monthsNeeded = ((itemAmt - balance) / (income * 0.3)).ceil();
          return "Currently, your remaining balance is ₹${balance.toStringAsFixed(0)}. A purchase of ₹${itemAmt.toStringAsFixed(0)} exceeds your current free cash. To buy this safely, you will need to save for approximately $monthsNeeded more months at a 30% monthly savings rate.";
        }

        if (itemAmt <= balance * 0.2) {
          return "Yes! You can absolutely afford this. A purchase of ₹${itemAmt.toStringAsFixed(0)} represents only ${(itemAmt / balance * 100).toStringAsFixed(0)}% of your remaining monthly balance (₹${balance.toStringAsFixed(0)}). Go ahead and buy it!";
        }

        // Mid-range affordability
        return "You have the funds (₹${balance.toStringAsFixed(0)} remaining), but spending ₹${itemAmt.toStringAsFixed(0)} will consume ${(itemAmt / balance * 100).toStringAsFixed(1)}% of your monthly cash flow. I suggest waiting 5 days. If you still want it, consider a 3-month no-cost EMI to preserve your emergency cash.";
      }
      return "To give you precise advice on what you can afford, please tell me the price of the purchase (e.g., 'Can I afford a 45000 laptop?').";
    }

    // 2. How much should I save question
    if (q.contains('save') || q.contains('savings')) {
      final recommendedSavings = income * 0.2;
      return "Based on your monthly income of ₹${income.toStringAsFixed(0)}, following the 50/30/20 rule, you should aim to save at least 20% (₹${recommendedSavings.toStringAsFixed(0)}) every month. Currently, your remaining balance is ₹${balance.toStringAsFixed(0)}. Saving a portion of this in a designated 'Goals' fund is a smart choice.";
    }

    // 3. General greetings/help
    return "Hi, I am your ExpenseAI Financial Advisor. I have analyzed your income (₹${income.toStringAsFixed(0)}) and expenses (₹${totalSpent.toStringAsFixed(0)}). You can ask me questions like:\n- 'Can I afford a ₹15,000 smartwatch?'\n- 'How much should I save monthly?'\n- 'Should I buy a bike of ₹1,20.000?'";
  }
}
