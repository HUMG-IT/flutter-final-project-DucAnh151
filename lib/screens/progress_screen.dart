import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';
import '../services/study_service.dart';
import '../widgets/progress_chart.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Deck> decks = [];
  Map<String, List<Flashcard>> deckCards = {};
  bool isLoading = true;
  bool _isRefreshing = false;

  int totalCards = 0;
  int learnedCards = 0;
  int dueCards = 0;
  int forgottenCards = 0;
  int totalStudyTime = 0; // Phút

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      if (!isLoading) isLoading = true;
    });

    final loadedDecks = await StorageService.getDecks();
    final allCards = await StorageService.getFlashcards();

    totalCards = allCards.length;
    learnedCards = allCards.where((c) => c.isLearned).length;
    dueCards = StudyService.getCardsDueCount(allCards);

    // Thẻ bị quên hôm nay
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    forgottenCards = allCards
        .where((c) => c.lastReviewed.isAfter(todayStart) && c.interval == 1 && c.reviewCount == 0)
        .length;

    // Tính tổng thời gian học (giả định mỗi thẻ học 30 giây)
    totalStudyTime = (allCards.fold(0, (sum, card) => sum + card.reviewCount) * 0.5).round();

    final Map<String, List<Flashcard>> grouped = {};
    for (var deck in loadedDecks) {
      grouped[deck.id] = allCards.where((c) => c.deckId == deck.id).toList();
    }

    if (mounted) {
      setState(() {
        decks = loadedDecks;
        deckCards = grouped;
        isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiến độ học tập'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tổng quan - DẠNG ROW VỪA VẶN
          const Text(
            'Tổng quan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Tổng thẻ', totalCards, Icons.library_books, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Đã thuộc', learnedCards, Icons.check_circle, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Cần ôn', dueCards, Icons.access_time, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Quên hôm nay', forgottenCards, Icons.close, Colors.red)),
            ],
          ),
          const SizedBox(height: 20),

          // Biểu đồ donut
          const Text(
            'Tiến độ học tập',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ProgressChart(
            total: totalCards,
            learned: learnedCards,
            due: dueCards,
            forgotten: forgottenCards,
          ),
          
          // Thống kê học tập
          if (totalStudyTime > 0) ...[
            const SizedBox(height: 20),
            const Text(
              'Thống kê học tập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng thời gian học',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          totalStudyTime >= 60
                              ? '${(totalStudyTime / 60).toStringAsFixed(1)} giờ'
                              : '$totalStudyTime phút',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.emoji_events,
                    size: 30,
                    color: Colors.purple.shade600,
                  ),
                ],
              ),
            ),
          ],
          
          // Thống kê từng bộ thẻ
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thống kê bộ thẻ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${decks.length} bộ',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...decks.map((deck) => _buildDeckStat(deck)),
          
          // Lời khuyên học tập
          if (dueCards > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lời khuyên học tập',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dueCards == 1
                              ? 'Bạn có 1 thẻ cần ôn. Hãy dành 5 phút để ôn tập ngay!'
                              : 'Bạn có $dueCards thẻ cần ôn. Ôn tập đều đặn để đạt hiệu quả tốt nhất!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // THẺ THỐNG KÊ DẠNG ROW VỪA VẶN
  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Container(
      height: 90, // CHIỀU CAO CỐ ĐỊNH - VỪA VẶN
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon và số trên cùng 1 hàng
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20, // Số vừa đủ to
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Tiêu đề
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckStat(Deck deck) {
    final cards = deckCards[deck.id] ?? [];
    final learned = cards.where((c) => c.isLearned).length;
    final due = StudyService.getCardsDueCount(cards);
    final progress = cards.isEmpty ? 0.0 : learned / cards.length;
    final progressPercent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        deck.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (deck.isImportant)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProgressColor(progress).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(progress),
                  ),
                ),
              ),
            ],
          ),
          if (deck.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                deck.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: _getProgressColor(progress),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildMiniChip('${cards.length} thẻ', Colors.blue),
                  const SizedBox(width: 6),
                  _buildMiniChip('$learned đã thuộc', Colors.green),
                  if (due > 0) ...[
                    const SizedBox(width: 6),
                    _buildMiniChip('$due cần ôn', Colors.orange),
                  ],
                ],
              ),
              Text(
                DateFormat('dd/MM/yy').format(deck.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }
}