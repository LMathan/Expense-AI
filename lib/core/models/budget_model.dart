class BudgetModel {
  final double monthlyIncome;
  final Map<String, double> categoryBudgets;

  BudgetModel({
    required this.monthlyIncome,
    required this.categoryBudgets,
  });

  factory BudgetModel.fromMap(Map<dynamic, dynamic> map) {
    final Map<String, double> cats = {};
    map.forEach((key, val) {
      if (key.toString().startsWith('category_')) {
        final catName = key.toString().replaceFirst('category_', '');
        cats[catName] = (val as num?)?.toDouble() ?? 0.0;
      }
    });
    return BudgetModel(
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: cats,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'monthly_income': monthlyIncome,
    };
    categoryBudgets.forEach((cat, limit) {
      map['category_$cat'] = limit;
    });
    return map;
  }
}
