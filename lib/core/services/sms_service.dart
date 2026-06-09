import 'dart:developer';

class SmsService {
  // Extract transaction details from SMS body text
  Map<String, dynamic>? parseSms(String smsBody) {
    try {
      final cleanText = smsBody.toLowerCase();
      
      // Look for debit indicators: debited, paid, spent, sent, txn of Rs
      if (!cleanText.contains('debit') && 
          !cleanText.contains('paid') && 
          !cleanText.contains('spent') && 
          !cleanText.contains('sent') && 
          !cleanText.contains('debited')) {
        return null; // Not a debit transaction SMS
      }

      // 1. Amount Extraction (supports ₹, Rs, Rs., INR)
      double amount = 0.0;
      final amountRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]+)?)');
      final amountMatch = amountRegex.firstMatch(cleanText);
      if (amountMatch != null) {
        final amtStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
        amount = double.tryParse(amtStr) ?? 0.0;
      } else {
        // Fallback for number without currency symbol if simple debit text
        final numRegex = RegExp(r'(?:debited|paid|spent)\s+([0-9,]+(?:\.[0-9]+)?)');
        final numMatch = numRegex.firstMatch(cleanText);
        if (numMatch != null) {
          final amtStr = numMatch.group(1)?.replaceAll(',', '') ?? '0';
          amount = double.tryParse(amtStr) ?? 0.0;
        }
      }

      if (amount == 0.0) return null;

      // 2. Merchant Extraction
      String merchant = 'Unknown Merchant';
      final merchantRegexs = [
        RegExp(r'(?:to|at|on|info|vpa)\s+([a-z0-9\s\.]+)(?:\s+on|\s+at|\s+via|\s+date|\s+balance|\s+ref|$)'),
        RegExp(r'spent\s+([a-z0-9\s\.]+)\s+on'),
      ];

      for (var reg in merchantRegexs) {
        final match = reg.firstMatch(cleanText);
        if (match != null) {
          final rawMerchant = match.group(1)?.trim() ?? '';
          if (rawMerchant.isNotEmpty && rawMerchant.length < 30) {
            // Capitalize merchant name
            merchant = rawMerchant
                .split(' ')
                .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
                .join(' ');
            break;
          }
        }
      }

      // 3. Category Prediction
      String category = _predictCategory(merchant, cleanText);

      return {
        'amount': amount,
        'merchant': merchant,
        'category': category,
        'date': DateTime.now().toIso8601String(),
        'paymentMethod': cleanText.contains('card') ? 'Credit Card' : 'UPI (Auto)',
        'notes': 'Automatically detected via SMS from bank',
      };
    } catch (e) {
      log('Error parsing SMS: $e');
      return null;
    }
  }

  String _predictCategory(String merchant, String smsText) {
    final mLower = merchant.toLowerCase();
    final sLower = smsText.toLowerCase();

    if (mLower.contains('swiggy') || mLower.contains('zomato') || mLower.contains('restaurant') || mLower.contains('food') || mLower.contains('cafe')) {
      return 'Food';
    }
    if (mLower.contains('uber') || mLower.contains('ola') || mLower.contains('metro') || mLower.contains('irctc') || mLower.contains('railway') || mLower.contains('cab')) {
      return 'Travel';
    }
    if (mLower.contains('netflix') || mLower.contains('spotify') || mLower.contains('prime') || mLower.contains('hotstar') || mLower.contains('youtube')) {
      return 'Entertainment';
    }
    if (mLower.contains('zara') || mLower.contains('amazon') || mLower.contains('flipkart') || mLower.contains('myntra') || mLower.contains('shopping') || mLower.contains('mall')) {
      return 'Shopping';
    }
    if (mLower.contains('bescom') || mLower.contains('electricity') || mLower.contains('broadband') || mLower.contains('act fiber') || mLower.contains('recharge') || mLower.contains('airtel') || mLower.contains('jio')) {
      return 'Bills';
    }
    if (mLower.contains('shell') || mLower.contains('petrol') || mLower.contains('hpcl') || mLower.contains('bpcl') || mLower.contains('fuel')) {
      return 'Fuel';
    }
    if (mLower.contains('rent') || mLower.contains('landlord') || mLower.contains('owner')) {
      return 'Rent';
    }
    if (mLower.contains('hospital') || mLower.contains('pharmacy') || mLower.contains('medical') || mLower.contains('apollo') || mLower.contains('healthcare')) {
      return 'Healthcare';
    }

    // Secondary scans
    if (sLower.contains('dining') || sLower.contains('eats')) return 'Food';
    if (sLower.contains('travel') || sLower.contains('ride') || sLower.contains('ticket')) return 'Travel';
    if (sLower.contains('movie') || sLower.contains('ticketnew')) return 'Entertainment';
    if (sLower.contains('petrol') || sLower.contains('diesel')) return 'Fuel';

    return 'Other';
  }
}
