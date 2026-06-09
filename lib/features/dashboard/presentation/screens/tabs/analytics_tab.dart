import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:espenseai/core/constants/colors.dart';
import 'package:espenseai/core/constants/text_styles.dart';
import 'package:espenseai/core/widgets/glass_card.dart';
import 'package:espenseai/core/widgets/interactive_chart.dart';
import 'package:espenseai/core/services/report_service.dart';
import 'dart:io';
import 'package:espenseai/features/expense/presentation/providers/expense_provider.dart';

class AnalyticsTab extends ConsumerStatefulWidget {
  const AnalyticsTab({super.key});

  @override
  ConsumerState<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<AnalyticsTab> {
  ChartType _selectedChartType = ChartType.pie;
  String _timeRange = 'Monthly';
  final ReportService _reportService = ReportService();
  bool _isExporting = false;

  void _exportAndShare(String type) async {
    setState(() {
      _isExporting = true;
    });

    try {
      File file;
      String subject;
      if (type == 'PDF') {
        file = await _reportService.generatePdfReport();
        subject = 'My ExpenseAI Statement - PDF';
      } else if (type == 'Excel') {
        file = await _reportService.generateExcelReport();
        subject = 'My ExpenseAI Statement - Spreadsheet';
      } else {
        file = await _reportService.generateCsvReport();
        subject = 'My ExpenseAI Statement - CSV';
      }

      await _reportService.shareReport(file, subject: subject);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: AppColors.accentPink),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Map<String, double> categorySums = {};
    final Map<String, double> merchantSums = {};
    double totalSpent = 0.0;
    
    final Map<String, double> dailySums = {};

    for (var tx in txs) {
      totalSpent += tx.amount;
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
      merchantSums[tx.merchant] = (merchantSums[tx.merchant] ?? 0.0) + tx.amount;
      
      final dateKey = tx.date.toString().substring(0, 10);
      dailySums[dateKey] = (dailySums[dateKey] ?? 0.0) + tx.amount;
    }

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedMerchants = merchantSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String mostExpensiveDay = 'N/A';
    double maxDailySpent = 0;
    dailySums.forEach((date, sum) {
      if (sum > maxDailySpent) {
        maxDailySpent = sum;
        mostExpensiveDay = date;
      }
    });

    final avgDailySpend = dailySums.isEmpty ? 0.0 : totalSpent / dailySums.length;

    final trendValues = _timeRange == 'Weekly' 
        ? [800.0, 1500.0, 3000.0, 1200.0, 4500.0, 2100.0, 1800.0]
        : [15000.0, 22000.0, 18000.0, 25000.0, 12000.0, totalSpent];

    final trendLabels = _timeRange == 'Weekly'
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isExporting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryPurple),
                    SizedBox(height: 16),
                    Text('Compiling statement reports...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Analytics & Reports',
                      style: AppTextStyles.heading2(isDark: isDark),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _buildTypePill(ChartType.pie, Icons.pie_chart_rounded, 'Pie'),
                        const SizedBox(width: 8),
                        _buildTypePill(ChartType.line, Icons.show_chart_rounded, 'Line'),
                        const SizedBox(width: 8),
                        _buildTypePill(ChartType.bar, Icons.bar_chart_rounded, 'Bar'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_selectedChartType != ChartType.pie) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildRangeButton('Weekly'),
                          const SizedBox(width: 8),
                          _buildRangeButton('Monthly'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    GlassCard(
                      child: InteractiveChart(
                        type: _selectedChartType,
                        data: categorySums,
                        trendData: trendValues,
                        labels: trendLabels,
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Avg Daily Spend', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${avgDailySpend.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Peak Spending Day', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                                const SizedBox(height: 4),
                                Text(
                                  mostExpensiveDay == 'N/A' ? 'N/A' : mostExpensiveDay.substring(5),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'TOP CATEGORIES',
                      style: AppTextStyles.caption(isDark: isDark).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: sortedCategories.isEmpty
                          ? const Center(child: Text('No details logged yet.', style: TextStyle(color: AppColors.textSecondaryDark)))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedCategories.length > 4 ? 4 : sortedCategories.length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.borderDark, height: 16),
                              itemBuilder: (context, index) {
                                final entry = sortedCategories[index];
                                final pct = totalSpent > 0 ? (entry.value / totalSpent * 100).toStringAsFixed(0) : '0';
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    Row(
                                      children: [
                                        Text('₹${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(width: 8),
                                        Text('$pct%', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'EXPORT STATEMENTS',
                      style: AppTextStyles.caption(isDark: isDark).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildExportButton('PDF', Icons.picture_as_pdf, Colors.redAccent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExportButton('Excel', Icons.table_chart_rounded, Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExportButton('CSV', Icons.notes_rounded, Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTypePill(ChartType type, IconData icon, String text) {
    final isSelected = _selectedChartType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.cardDark,
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderDark,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondaryDark),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeButton(String range) {
    final isSelected = _timeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primaryPurple : Colors.transparent,
        ),
        child: Text(
          range,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => _exportAndShare(label),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        borderRadius: 16,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              'Share $label',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
