import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/models/deck.dart';

void main() {
  group('💾 Storage Service Tests', () {
    // Setup mock SharedPreferences
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    
    // TEST 9: Lưu và đọc deck
    test('✅ Lưu và đọc deck từ storage', () async {
      final deck = Deck(
        id: 'test_save',
        name: 'Test Save Deck',
        description: 'Test description',
        cardCount: 5,
        masteredCount: 2,
        isImportant: true,
      );
      
      // Lưu deck
      await StorageService.saveDeck(deck);
      
      // Đọc lại
      final decks = await StorageService.getDecks();
      
      expect(decks.length, 1);
      expect(decks[0].id, 'test_save');
      expect(decks[0].name, 'Test Save Deck');
      expect(decks[0].isImportant, true);
    });
    
    // TEST 10: Xóa deck
    test('✅ Xóa deck khỏi storage', () async {
      final deck1 = Deck(id: '1', name: 'Deck 1');
      final deck2 = Deck(id: '2', name: 'Deck 2');
      
      await StorageService.saveDeck(deck1);
      await StorageService.saveDeck(deck2);
      
      // Xóa deck1
      await StorageService.deleteDeck('1');
      
      final remainingDecks = await StorageService.getDecks();
      
      expect(remainingDecks.length, 1);
      expect(remainingDecks[0].id, '2');
      expect(remainingDecks[0].name, 'Deck 2');
    });
  });
}