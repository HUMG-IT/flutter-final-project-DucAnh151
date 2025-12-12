class Flashcard {
  final String id;
  final String deckId;
  String front;
  String back;
  String example;
  DateTime lastReviewed;
  int reviewCount;
  double easeFactor;
  int interval;
  bool isLearned;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.example = '',
    DateTime? lastReviewed,
    this.reviewCount = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.isLearned = false,
  }) : lastReviewed = lastReviewed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'example': example,
        'lastReviewed': lastReviewed.toIso8601String(),
        'reviewCount': reviewCount,
        'easeFactor': easeFactor,
        'interval': interval,
        'isLearned': isLearned,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'],
        deckId: json['deckId'],
        front: json['front'],
        back: json['back'],
        example: json['example'] ?? '',
        lastReviewed: DateTime.parse(json['lastReviewed']),
        reviewCount: json['reviewCount'] ?? 0,
        easeFactor: json['easeFactor']?.toDouble() ?? 2.5,
        interval: json['interval'] ?? 0,
        isLearned: json['isLearned'] ?? false,
      );
}