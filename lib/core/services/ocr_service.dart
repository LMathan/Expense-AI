import 'dart:io';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source, imageQuality: 85);
    } catch (_) {
      return null;
    }
  }

  // Simulates OCR processing and returns extracted data
  Future<Map<String, dynamic>> scanReceipt(File file) async {
    // Simulate network/OCR processing delay
    await Future.delayed(const Duration(milliseconds: 2500));

    // Determine filename to create a smart custom mockup scan
    final fileName = file.path.split('/').last.toLowerCase();
    
    if (fileName.contains('starbuck') || fileName.contains('coffee') || fileName.contains('cafe')) {
      return {
        'merchant': 'Starbucks Coffee',
        'amount': 380.00,
        'tax': 18.10,
        'date': DateTime.now().toIso8601String(),
        'category': 'Food',
        'notes': 'OCR Scan: Starbucks Beverage',
      };
    } else if (fileName.contains('amazon') || fileName.contains('delivery') || fileName.contains('box')) {
      return {
        'merchant': 'Amazon India',
        'amount': 1249.00,
        'tax': 224.82,
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'category': 'Shopping',
        'notes': 'OCR Scan: Amazon Purchase',
      };
    } else if (fileName.contains('fuel') || fileName.contains('petrol') || fileName.contains('shell')) {
      return {
        'merchant': 'Shell Petrol Station',
        'amount': 1500.00,
        'tax': 0.00,
        'date': DateTime.now().toIso8601String(),
        'category': 'Fuel',
        'notes': 'OCR Scan: Vehicle Refuel',
      };
    } else if (fileName.contains('bill') || fileName.contains('electric') || fileName.contains('power')) {
      return {
        'merchant': 'Electricity Board',
        'amount': 2840.00,
        'tax': 142.00,
        'date': DateTime.now().toIso8601String(),
        'category': 'Bills',
        'notes': 'OCR Scan: Monthly Utility Bill',
      };
    }

    // Default high-fidelity return if file name is generic
    return {
      'merchant': 'Reliance Retail',
      'amount': 450.00,
      'tax': 22.50,
      'date': DateTime.now().toIso8601String(),
      'category': 'Shopping',
      'notes': 'OCR Scan: Groceries & General Items',
    };
  }
}
