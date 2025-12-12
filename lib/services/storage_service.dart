import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';

class StorageService {
  static const String _decksKey = 'flashcard_decks';
  static const String _cardsKey = 'flashcard_cards';
  static const String _studyProgressKey = 'study_progress';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Deck operations
  static Future<void> saveDeck(Deck deck) async {
    final prefs = await _prefs;
    final decks = await getDecks();
    
    final index = decks.indexWhere((d) => d.id == deck.id);
    if (index != -1) {
      decks[index] = deck;
    } else {
      decks.add(deck);
    }
    
    final decksJson = decks.map((deck) => deck.toJson()).toList();
    await prefs.setString(_decksKey, json.encode(decksJson));
  }

  static Future<List<Deck>> getDecks() async {
    final prefs = await _prefs;
    final decksJson = prefs.getString(_decksKey);
    
    if (decksJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(decksJson);
      return decoded.map((json) => Deck.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteDeck(String deckId) async {
    final prefs = await _prefs;
    
    // Xoá deck
    final decks = await getDecks();
    final updatedDecks = decks.where((deck) => deck.id != deckId).toList();
    final decksJson = updatedDecks.map((deck) => deck.toJson()).toList();
    await prefs.setString(_decksKey, json.encode(decksJson));
    
    // Xoá flashcards của deck
    final allCards = await getFlashcards();
    final updatedCards = allCards.where((card) => card.deckId != deckId).toList();
    final cardsJson = updatedCards.map((card) => card.toJson()).toList();
    await prefs.setString(_cardsKey, json.encode(cardsJson));
    
    // Xoá progress của deck
    final progress = await getStudyProgress();
    progress.remove(deckId);
    await prefs.setString(_studyProgressKey, json.encode(progress));
  }

  // Flashcard operations
  static Future<void> saveFlashcard(Flashcard flashcard) async {
    final prefs = await _prefs;
    final cards = await getFlashcards();
    
    final index = cards.indexWhere((c) => c.id == flashcard.id);
    if (index != -1) {
      cards[index] = flashcard;
    } else {
      cards.add(flashcard);
    }
    
    final cardsJson = cards.map((card) => card.toJson()).toList();
    await prefs.setString(_cardsKey, json.encode(cardsJson));
  }

  static Future<void> saveFlashcards(List<Flashcard> flashcards) async {
    final prefs = await _prefs;
    final allCards = await getFlashcards();
    final Map<String, Flashcard> cardMap = {
      for (var card in allCards) card.id: card
    };
    
    for (var card in flashcards) {
      cardMap[card.id] = card;
    }
    
    final cardsJson = cardMap.values.map((card) => card.toJson()).toList();
    await prefs.setString(_cardsKey, json.encode(cardsJson));
  }

  // HÀM MỚI: Thay thế toàn bộ flashcard của một deck
  static Future<void> replaceFlashcardsForDeck(String deckId, List<Flashcard> newCards) async {
    final prefs = await _prefs;
    final allCards = await getFlashcards();
    
    // Giữ lại thẻ của các deck khác
    final otherCards = allCards.where((card) => card.deckId != deckId).toList();
    
    // Kết hợp với thẻ mới
    final updatedCards = [...otherCards, ...newCards];
    final cardsJson = updatedCards.map((card) => card.toJson()).toList();
    
    await prefs.setString(_cardsKey, json.encode(cardsJson));
  }

  static Future<List<Flashcard>> getFlashcards() async {
    final prefs = await _prefs;
    final cardsJson = prefs.getString(_cardsKey);
    
    if (cardsJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(cardsJson);
      return decoded.map((json) => Flashcard.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Flashcard>> getFlashcardsByDeck(String deckId) async {
    final allCards = await getFlashcards();
    return allCards.where((card) => card.deckId == deckId).toList();
  }

  // Progress tracking
  static Future<void> saveStudyProgress(String deckId, int cardsReviewed) async {
    final prefs = await _prefs;
    final progress = await getStudyProgress();
    progress[deckId] = {
      'lastStudied': DateTime.now().toIso8601String(),
      'cardsReviewed': cardsReviewed,
    };
    await prefs.setString(_studyProgressKey, json.encode(progress));
  }

  static Future<Map<String, dynamic>> getStudyProgress() async {
    final prefs = await _prefs;
    final progressJson = prefs.getString(_studyProgressKey);
    
    if (progressJson == null) return {};
    
    try {
      final Map<String, dynamic> decoded = 
          Map<String, dynamic>.from(json.decode(progressJson));
      return decoded;
    } catch (e) {
      return {};
    }
  }

  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.remove(_decksKey);
    await prefs.remove(_cardsKey);
    await prefs.remove(_studyProgressKey);
  }
}