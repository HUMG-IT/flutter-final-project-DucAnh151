import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/flashcard.dart';

void main() {
  group('🎴 Flashcard Model Tests', () {
    // TEST 4: Tạo flashcard mới
    test('✅ Tạo flashcard với giá trị mặc định', () {
      final card = Flashcard(
        id: 'card_001',
        deckId: 'deck_123',
        front: 'Hello',
        back: 'Xin chào',
      );
      
      expect(card.id, 'card_001');
      expect(card.deckId, 'deck_123');
      expect(card.front, 'Hello');
      expect(card.back, 'Xin chào');
      expect(card.example, ''); // Mặc định rỗng
      expect(card.reviewCount, 0); // Mặc định 0
      expect(card.easeFactor, 2.5); // Mặc định 2.5
      expect(card.interval, 0); // Mặc định 0
      expect(card.isLearned, false); // Mặc định false
      expect(card.lastReviewed, isA<DateTime>());
    });
    
    // TEST 5: Chuyển đổi JSON flashcard
    test('✅ Chuyển đổi Flashcard ↔ JSON', () {
      final originalCard = Flashcard(
        id: 'card_json',
        deckId: 'deck_json',
        front: 'Good morning',
        back: 'Chào buổi sáng',
        example: 'Good morning, how are you?',
        reviewCount: 5,
        easeFactor: 2.8,
        interval: 10,
        isLearned: true,
      );
      
      final json = originalCard.toJson();
      final restoredCard = Flashcard.fromJson(json);
      
      expect(restoredCard.id, originalCard.id);
      expect(restoredCard.deckId, originalCard.deckId);
      expect(restoredCard.front, originalCard.front);
      expect(restoredCard.back, originalCard.back);
      expect(restoredCard.example, originalCard.example);
      expect(restoredCard.reviewCount, 5);
      expect(restoredCard.easeFactor, 2.8);
      expect(restoredCard.interval, 10);
      expect(restoredCard.isLearned, true);
    });
  });
}