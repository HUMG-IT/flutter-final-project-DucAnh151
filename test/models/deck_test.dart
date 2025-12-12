import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/deck.dart';

void main() {
  group('📦 Deck Model Tests', () {
    // TEST 1: Tạo deck mới
    test('✅ Tạo deck mới với giá trị mặc định', () {
      // Arrange
      final deck = Deck(
        id: 'deck_123',
        name: 'Tiếng Anh cơ bản',
      );
      
      // Assert (Kiểm tra)
      expect(deck.id, 'deck_123');
      expect(deck.name, 'Tiếng Anh cơ bản');
      expect(deck.description, ''); // Mặc định rỗng
      expect(deck.cardCount, 0); // Mặc định 0
      expect(deck.isImportant, false); // Mặc định false
      expect(deck.masteredCount, 0); // Mặc định 0
    });
    
    // TEST 2: Chuyển đổi JSON
    test('✅ Chuyển đổi Deck ↔ JSON', () {
      // Arrange
      final originalDeck = Deck(
        id: 'test_001',
        name: 'Test Deck',
        description: 'Mô tả test',
        isImportant: true,
        cardCount: 10,
        masteredCount: 3,
      );
      
      // Act
      final json = originalDeck.toJson();
      final restoredDeck = Deck.fromJson(json);
      
      // Assert
      expect(restoredDeck.id, originalDeck.id);
      expect(restoredDeck.name, originalDeck.name);
      expect(restoredDeck.description, originalDeck.description);
      expect(restoredDeck.isImportant, true);
      expect(restoredDeck.cardCount, 10);
      expect(restoredDeck.masteredCount, 3);
      expect(restoredDeck.createdAt, isA<DateTime>());
    });
    
    // TEST 3: Đánh dấu quan trọng
    test('✅ Bộ thẻ quan trọng hiển thị đúng', () {
      final importantDeck = Deck(
        id: 'imp_001',
        name: 'Quan trọng',
        isImportant: true,
      );
      
      final normalDeck = Deck(
        id: 'norm_001',
        name: 'Bình thường',
        isImportant: false,
      );
      
      expect(importantDeck.isImportant, true);
      expect(normalDeck.isImportant, false);
    });
  });
}