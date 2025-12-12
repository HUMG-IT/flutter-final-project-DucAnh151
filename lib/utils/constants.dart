import 'package:flutter/material.dart';

// App constants and configurations
class AppConstants {
  // App info
  static const String appName = 'Flashcard App';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String storageDecksKey = 'flashcard_decks';
  static const String storageCardsKey = 'flashcard_cards';
  static const String storageProgressKey = 'study_progress';
  static const String storageSettingsKey = 'app_settings';
  
  // Study settings
  static const int dailyReviewLimit = 50;
  static const double initialEaseFactor = 2.5;
  static const int newCardsPerDay = 20;
  
  // CSV settings
  static const List<String> csvHeaders = ['Front', 'Back', 'Example'];
  static const String csvDateFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // UI constants
  static const double cardCornerRadius = 16.0;
  static const double buttonCornerRadius = 12.0;
  static const Duration cardFlipDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 2);
  
  // Color mappings
  static final Map<int, Color> ratingColors = {
    0: Colors.red,     // Again
    1: Colors.orange,  // Hard
    2: Colors.blue,    // Good
    3: Colors.green,   // Easy
  };
  
  static final Map<String, Color> progressColors = {
    'notStarted': Colors.grey,
    'beginner': Colors.red,
    'intermediate': Colors.orange,
    'advanced': Colors.blue,
    'mastered': Colors.green,
  };
}

// App routes
class AppRoutes {
  static const String home = '/';
  static const String study = '/study';
  static const String import = '/import';
  static const String progress = '/progress';
  static const String settings = '/settings';
}

// CSV template
class CsvTemplate {
  static const String sample = '''Front,Back,Example
Hello,Xin chào,Hello everyone!
Thank you,Cảm ơn,Thank you very much!
Goodbye,Tạm biệt,Goodbye and see you soon!
Cat,Con mèo,The cat is sleeping.
Dog,Con chó,The dog is barking.''';

  static String getTemplate() {
    return '${AppConstants.csvHeaders.join(',')}\n$sample';
  }
}

// Study intervals (in days) for SRS algorithm
class StudyIntervals {
  static const List<int> intervals = [1, 2, 4, 7, 15, 30, 90, 180];
  
  static int getNextInterval(int currentInterval, double easeFactor) {
    if (currentInterval == 0) return intervals.first;
    
    final next = (currentInterval * easeFactor).round();
    return next;
  }
}

// Error messages
class ErrorMessages {
  static const String csvImportFailed = 'Failed to import CSV file';
  static const String csvFormatInvalid = 'Invalid CSV format';
  static const String deckNameEmpty = 'Deck name cannot be empty';
  static const String noFileSelected = 'Please select a file';
  static const String storageError = 'Error saving data';
  static const String networkError = 'Network error occurred';
  
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error.toString().contains('csv')) return csvImportFailed;
    if (error.toString().contains('storage')) return storageError;
    return 'An unexpected error occurred';
  }
}

// Success messages
class SuccessMessages {
  static const String importSuccess = 'Flashcards imported successfully';
  static const String saveSuccess = 'Progress saved successfully';
  static const String deckCreated = 'Deck created successfully';
  static const String studyComplete = 'Study session completed!';
}