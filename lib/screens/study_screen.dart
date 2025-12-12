import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';
import '../services/study_service.dart';
import '../widgets/flashcard_widget.dart';

class StudyScreen extends StatefulWidget {
  final Deck deck;
  const StudyScreen({Key? key, required this.deck}) : super(key: key);

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  List<Flashcard> flashcards = [];
  List<Flashcard> dueCards = [];
  int currentIndex = 0;
  bool showAnswer = false;
  bool isLoading = true;
  bool studyCompleted = false;
  bool _isSoundEnabled = true;
  late AnimationController _cardFlipController;
  late Animation<double> _cardFlipAnimation;

  @override
  void initState() {
    super.initState();
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardFlipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardFlipController, curve: Curves.easeInOut),
    );
    
    _loadFlashcards();
    _loadSoundSetting();
  }

  @override
  void dispose() {
    _cardFlipController.dispose();
    super.dispose();
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _toggleSound() async {
    final newValue = !_isSoundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', newValue);
    if (!mounted) return;
    setState(() {
      _isSoundEnabled = newValue;
    });
  }

  Future<void> _loadFlashcards() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final allCards = await StorageService.getFlashcardsByDeck(widget.deck.id);
    final due = StudyService.getCardsDueForReview(allCards);

    if (!mounted) return;

    setState(() {
      flashcards = allCards;
      dueCards = due;
      currentIndex = 0;
      showAnswer = false;
      studyCompleted = dueCards.isEmpty && flashcards.isNotEmpty;
      isLoading = false;
    });
  }

  void _toggleCard() {
    if (showAnswer) {
      _cardFlipController.reverse();
    } else {
      _cardFlipController.forward();
    }
    setState(() {
      showAnswer = !showAnswer;
    });
  }

  Future<void> _restartAndStudyNow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Học lại từ đầu'),
        content: const Text('Tất cả thẻ sẽ được đặt lại như chưa học.\nBạn sẽ bắt đầu học lại ngay lập tức.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bắt đầu lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    for (var card in flashcards) {
      card.isLearned = false;
      card.interval = 1;
      card.reviewCount = 0;
      card.lastReviewed = DateTime.now().subtract(const Duration(days: 1));
      await StorageService.saveFlashcard(card);
    }

    widget.deck.masteredCount = 0;
    await StorageService.saveDeck(widget.deck);
    deckUpdateNotifier.value++;

    await _loadFlashcards();
    if (mounted) {
      setState(() {
        studyCompleted = false;
        currentIndex = 0;
        showAnswer = false;
        _cardFlipController.reset();
      });
    }
  }

  void _nextCard() {
    if (!mounted) return;
    if (currentIndex < dueCards.length - 1) {
      setState(() {
        currentIndex++;
        showAnswer = false;
        _cardFlipController.reset();
      });
    } else {
      setState(() => studyCompleted = true);
    }
  }

  void _rateCard(bool remembered) {
    if (!mounted || currentIndex >= dueCards.length) return;
    final card = dueCards[currentIndex];

    if (remembered) {
      card.isLearned = true;
      card.interval = 30;
      card.reviewCount = 10;
    } else {
      card.interval = 1;
      card.reviewCount = 0;
    }

    card.lastReviewed = DateTime.now();
    StorageService.saveFlashcard(card);

    final learnedCount = flashcards.where((c) => c.isLearned).length + (remembered ? 1 : 0);
    widget.deck.masteredCount = learnedCount;
    StorageService.saveDeck(widget.deck);
    deckUpdateNotifier.value++;

    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
              color: _isSoundEnabled ? Colors.blue : Colors.grey,
            ),
            onPressed: _toggleSound,
            tooltip: _isSoundEnabled ? 'Tắt âm thanh' : 'Bật âm thanh',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Học lại từ đầu',
            onPressed: _restartAndStudyNow,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : studyCompleted
              ? _buildCompletionScreen()
              : dueCards.isEmpty
                  ? _buildNoDueScreen()
                  : _buildStudyScreen(),
    );
  }

  Widget _buildStudyScreen() {
    if (currentIndex >= dueCards.length) return _buildCompletionScreen();
    final card = dueCards[currentIndex];
    final progress = (currentIndex + 1) / dueCards.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          color: Colors.blue,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thẻ ${currentIndex + 1}/${dueCards.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        ),
        // Flashcard với flip animation
        Expanded(
          child: GestureDetector(
            onTap: _toggleCard,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showAnswer
                    ? FlashcardWidget(
                        key: const ValueKey('back'),
                        front: card.front,
                        back: card.back,
                        example: card.example,
                        showAnswer: showAnswer,
                        soundEnabled: _isSoundEnabled,
                        onToggleSound: _toggleSound,
                      )
                    : FlashcardWidget(
                        key: const ValueKey('front'),
                        front: card.front,
                        back: card.back,
                        example: card.example,
                        showAnswer: showAnswer,
                        soundEnabled: _isSoundEnabled,
                        onToggleSound: _toggleSound,
                      ),
              ),
            ),
          ),
        ),
        // Action buttons
        if (showAnswer)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _rateCard(false),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Quên'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _rateCard(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Đã nhớ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!showAnswer)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _toggleCard,
              icon: const Icon(Icons.visibility),
              label: const Text('Xem đáp án'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    final learnedPercent = flashcards.isEmpty
        ? 0
        : (flashcards.where((c) => c.isLearned).length / flashcards.length * 100).toInt();

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 120, color: Colors.green),
              const SizedBox(height: 32),
              const Text(
                'Chúc mừng! 🎉',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Bạn đã hoàn thành tất cả thẻ cần ôn hôm nay!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      '$learnedPercent%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'tỉ lệ đã thuộc',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home),
                      label: const Text('Về trang chủ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _restartAndStudyNow,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Học lại từ đầu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDueScreen() {
    final learnedPercent = flashcards.isEmpty
        ? 0
        : (flashcards.where((c) => c.isLearned).length / flashcards.length * 100).toInt();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Hôm nay không có thẻ cần ôn!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn đã thuộc $learnedPercent% bộ thẻ này',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tiếp tục duy trì thói quen học tập nhé!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartAndStudyNow,
                icon: const Icon(Icons.refresh),
                label: const Text('Học lại từ đầu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}