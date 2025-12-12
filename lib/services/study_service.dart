import '../models/flashcard.dart';

class StudyService {
  // Spaced Repetition Algorithm (SM-2 inspired)
  static void updateCardAfterReview(Flashcard card, int quality) {
    // quality: 0-5 (0=complete blackout, 5=perfect recall)
    
    if (quality < 3) {
      card.interval = 1;
      card.reviewCount = 0;
    } else {
      card.reviewCount += 1;
      
      if (card.reviewCount == 1) {
        card.interval = 1;
      } else if (card.reviewCount == 2) {
        card.interval = 6;
      } else {
        card.interval = (card.interval * card.easeFactor).round();
      }
      
      // Update ease factor
      card.easeFactor = card.easeFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      
      if (card.easeFactor < 1.3) {
        card.easeFactor = 1.3;
      }
    }
    
    card.lastReviewed = DateTime.now();
    card.isLearned = card.interval > 30; // Consider learned if interval > 30 days
  }

  static List<Flashcard> getCardsDueForReview(List<Flashcard> cards) {
    final now = DateTime.now();
    
    return cards.where((card) {
      if (card.isLearned) return false;
      
      final nextReviewDate = card.lastReviewed.add(Duration(days: card.interval));
      return now.isAfter(nextReviewDate) || now.isAtSameMomentAs(nextReviewDate);
    }).toList();
  }

  static int getCardsDueCount(List<Flashcard> cards) {
    return getCardsDueForReview(cards).length;
  }

  static double calculateDeckProgress(List<Flashcard> cards) {
    if (cards.isEmpty) return 0.0;
    
    final learnedCards = cards.where((card) => card.isLearned).length;
    return learnedCards / cards.length;
  }
}