import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function(bool isListening) onSoundLevelChanged,
  }) async {
    final hasInit = await initialize();
    if (!hasInit) return;

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 4),
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;

  // Parses voice commands into transaction segments
  Map<String, dynamic>? parseVoiceCommand(String spokenText) {
    final clean = spokenText.toLowerCase();

    // 1. Amount Extraction
    double amount = 0.0;
    // Look for digits like 250, 1000, 45.50
    final amountRegex = RegExp(r'\b([0-9]+(?:\.[0-9]+)?)\b');
    final match = amountRegex.firstMatch(clean);
    if (match != null) {
      amount = double.tryParse(match.group(1) ?? '') ?? 0.0;
    }

    if (amount == 0.0) return null;

    // 2. Category prediction
    String category = 'Other';
    if (clean.contains('lunch') || clean.contains('dinner') || clean.contains('food') || clean.contains('eat') || clean.contains('restaurant') || clean.contains('swiggy') || clean.contains('zomato')) {
      category = 'Food';
    } else if (clean.contains('uber') || clean.contains('cab') || clean.contains('travel') || clean.contains('ticket') || clean.contains('metro') || clean.contains('ola')) {
      category = 'Travel';
    } else if (clean.contains('shopping') || clean.contains('clothes') || clean.contains('zara') || clean.contains('amazon')) {
      category = 'Shopping';
    } else if (clean.contains('netflix') || clean.contains('spotify') || clean.contains('movie') || clean.contains('entertainment')) {
      category = 'Entertainment';
    } else if (clean.contains('bill') || clean.contains('electricity') || clean.contains('broadband') || clean.contains('rent')) {
      if (clean.contains('rent')) {
        category = 'Rent';
      } else {
        category = 'Bills';
      }
    } else if (clean.contains('fuel') || clean.contains('petrol') || clean.contains('diesel') || clean.contains('shell')) {
      category = 'Fuel';
    }

    // 3. Merchant Name
    String merchant = 'Unknown Merchant';
    // Match "at [merchant]" or "to [merchant]" or "on [merchant]"
    final merchantMatch = RegExp(r'\b(?:at|to|on)\s+([a-z0-9\s]+)\b').firstMatch(clean);
    if (merchantMatch != null) {
      final rawM = merchantMatch.group(1)?.trim() ?? '';
      // Exclude simple categories or prepositions
      if (rawM.isNotEmpty && 
          rawM != 'food' && 
          rawM != 'lunch' && 
          rawM != 'dinner' && 
          rawM != 'fuel' && 
          rawM != 'petrol' &&
          rawM.length < 25) {
        merchant = rawM
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
      }
    }

    // Guess default merchant if none specified but category matches
    if (merchant == 'Unknown Merchant') {
      if (category == 'Food') merchant = 'Restaurant';
      if (category == 'Travel') merchant = 'Cab Service';
      if (category == 'Fuel') merchant = 'Fuel Station';
      if (category == 'Shopping') merchant = 'Store';
      if (category == 'Bills') merchant = 'Utility Provider';
    }

    return {
      'amount': amount,
      'category': category,
      'merchant': merchant,
      'date': DateTime.now().toIso8601String(),
      'paymentMethod': 'Cash', // Default for spoken entry
      'notes': 'Recorded via voice command: "$spokenText"',
    };
  }
}
