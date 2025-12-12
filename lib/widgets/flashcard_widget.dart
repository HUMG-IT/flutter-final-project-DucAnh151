import 'package:flutter/material.dart';

class FlashcardWidget extends StatelessWidget {
  final String front;
  final String back;
  final String example;
  final bool showAnswer;
  final bool soundEnabled;
  final VoidCallback? onToggleSound;

  const FlashcardWidget({
    Key? key,
    required this.front,
    required this.back,
    required this.example,
    required this.showAnswer,
    required this.soundEnabled,
    this.onToggleSound,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showAnswer
                ? _buildBackSide()
                : _buildFrontSide(),
          ),
          // ICON LOA Ở GÓC TRÊN BÊN PHẢI
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: soundEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  soundEnabled ? Icons.volume_up : Icons.volume_off,
                  size: 20,
                  color: soundEnabled ? Colors.blue : Colors.grey,
                ),
                onPressed: onToggleSound,
                tooltip: soundEnabled ? 'Tắt âm thanh' : 'Bật âm thanh',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      key: const ValueKey('front'),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              front,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.touch_app,
              size: 40,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            const Text(
              'Chạm để xem đáp án',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Câu hỏi (nhỏ hơn)
          Text(
            front,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Đáp án (chính)
          Text(
            back,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Chạm để lật lại',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}