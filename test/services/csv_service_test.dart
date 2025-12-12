import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/csv_service.dart';
import '../../lib/models/flashcard.dart';

void main() {
  group('📄 CSV Service Tests', () {
    // TEST 6: Parse CSV đơn giản
    test('✅ Parse CSV với 2 cột', () {
      final csvContent = '''Mặt trước,Mặt sau
Hello,Xin chào
Thank you,Cảm ơn''';
      
      final result = CsvService.parseCsv(csvContent);
      
      expect(result.length, 3); // Header + 2 dòng
      expect(result[0], ['Mặt trước', 'Mặt sau']);
      expect(result[1], ['Hello', 'Xin chào']);
      expect(result[2], ['Thank you', 'Cảm ơn']);
    });
    
    // TEST 7: Parse CSV với 3 cột
    test('✅ Parse CSV với ví dụ', () {
      final csvContent = '''Front,Back,Example
Cat,Con mèo,The cat is sleeping''';
      
      final result = CsvService.parseCsv(csvContent);
      
      expect(result.length, 2);
      expect(result[0], ['Front', 'Back', 'Example']);
      expect(result[1], ['Cat', 'Con mèo', 'The cat is sleeping']);
    });
    
    // TEST 8: Export to CSV
    test('✅ Export flashcards to CSV', () {
      final flashcards = [
        Flashcard(
          id: '1',
          deckId: 'deck1',
          front: 'Hello',
          back: 'Xin chào',
          example: 'Hello everyone!',
        ),
        Flashcard(
          id: '2',
          deckId: 'deck1',
          front: 'Thank you',
          back: 'Cảm ơn',
          example: 'Thank you very much',
        ),
      ];
      
      final csv = CsvService.exportToCsv(flashcards);
      
      expect(csv, contains('Mặt trước'));
      expect(csv, contains('Mặt sau'));
      expect(csv, contains('Ví dụ'));
      expect(csv, contains('Hello'));
      expect(csv, contains('Xin chào'));
      expect(csv, contains('Thank you'));
      expect(csv, contains('Cảm ơn'));
    });
  });
}