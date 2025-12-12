import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';

class DeckManageScreen extends StatefulWidget {
  final Deck deck;

  const DeckManageScreen({super.key, required this.deck});

  @override
  State<DeckManageScreen> createState() => _DeckManageScreenState();
}

class _DeckManageScreenState extends State<DeckManageScreen> {
  List<Flashcard> flashcards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() => isLoading = true);
    final cards = await StorageService.getFlashcardsByDeck(widget.deck.id);
    if (!mounted) return;
    setState(() {
      flashcards = cards;
      isLoading = false;
    });
  }

  void _showAddFlashcardDialog() {
    final TextEditingController frontController = TextEditingController();
    final TextEditingController backController = TextEditingController();
    final TextEditingController exampleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm thẻ mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frontController,
                  decoration: const InputDecoration(
                    labelText: 'Mặt trước *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: backController,
                  decoration: const InputDecoration(
                    labelText: 'Mặt sau *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: exampleController,
                  decoration: const InputDecoration(
                    labelText: 'Ví dụ (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                  final flashcard = Flashcard(
                    id: '${DateTime.now().millisecondsSinceEpoch}',
                    deckId: widget.deck.id,
                    front: frontController.text.trim(),
                    back: backController.text.trim(),
                    example: exampleController.text.trim(),
                  );
                  
                  await StorageService.saveFlashcard(flashcard);
                  
                  // Cập nhật số thẻ trong deck
                  widget.deck.cardCount = flashcards.length + 1;
                  await StorageService.saveDeck(widget.deck);
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadFlashcards();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm thẻ mới')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ mặt trước và mặt sau')),
                    );
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _showEditFlashcardDialog(Flashcard flashcard) {
    final TextEditingController frontController = TextEditingController(text: flashcard.front);
    final TextEditingController backController = TextEditingController(text: flashcard.back);
    final TextEditingController exampleController = TextEditingController(text: flashcard.example);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa thẻ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: frontController,
                  decoration: const InputDecoration(
                    labelText: 'Mặt trước *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: backController,
                  decoration: const InputDecoration(
                    labelText: 'Mặt sau *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: exampleController,
                  decoration: const InputDecoration(
                    labelText: 'Ví dụ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                  flashcard.front = frontController.text.trim();
                  flashcard.back = backController.text.trim();
                  flashcard.example = exampleController.text.trim();
                  
                  await StorageService.saveFlashcard(flashcard);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadFlashcards();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu thay đổi')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoá thẻ'),
          content: const Text('Bạn có chắc muốn xoá thẻ này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xoá', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final allCards = await StorageService.getFlashcards();
      final updatedCards = allCards.where((c) => c.id != flashcard.id).toList();
      await StorageService.saveFlashcards(updatedCards);
      
      // Cập nhật số thẻ trong deck
      widget.deck.cardCount = updatedCards.where((c) => c.deckId == widget.deck.id).length;
      await StorageService.saveDeck(widget.deck);
      
      _loadFlashcards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá thẻ')),
        );
      }
    }
  }

  void _resetAllCards() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset tất cả thẻ'),
          content: const Text('Bạn có chắc muốn reset tiến độ học của tất cả thẻ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Reset', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      for (var card in flashcards) {
        card.isLearned = false;
        card.reviewCount = 0;
        card.interval = 0;
        card.easeFactor = 2.5;
        card.lastReviewed = DateTime.now();
        await StorageService.saveFlashcard(card);
      }
      
      widget.deck.masteredCount = 0;
      await StorageService.saveDeck(widget.deck);
      
      _loadFlashcards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã reset tất cả thẻ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAllCards,
            tooltip: 'Reset tất cả thẻ',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFlashcardDialog,
            tooltip: 'Thêm thẻ mới',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : flashcards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.note_add, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có thẻ nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: flashcards.length,
                  itemBuilder: (context, index) {
                    final card = flashcards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          card.front,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.back),
                            if (card.example.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Ví dụ: ${card.example}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (card.isLearned)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đã thuộc',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditFlashcardDialog(card),
                              tooltip: 'Sửa',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteFlashcard(card),
                              tooltip: 'Xoá',
                            ),
                          ],
                        ),
                        onTap: () => _showEditFlashcardDialog(card),
                      ),
                    );
                  },
                ),
    );
  }
}