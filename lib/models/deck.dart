class Deck {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  int cardCount;
  int masteredCount;
  bool isImportant;

  Deck({
    required this.id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    this.cardCount = 0,
    this.masteredCount = 0,
    this.isImportant = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'cardCount': cardCount,
        'masteredCount': masteredCount,
        'isImportant': isImportant,
      };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        cardCount: json['cardCount'] ?? 0,
        masteredCount: json['masteredCount'] ?? 0,
        isImportant: json['isImportant'] ?? false,
      );
}