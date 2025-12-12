import 'package:csv/csv.dart';
import '../models/flashcard.dart';

class CsvService {
  /// Import từ chuỗi CSV → trả về List<Flashcard>
  static Future<List<Flashcard>> importFromCsv(String csvContent, String deckId) async {
    try {
      // Chuẩn hóa xuống dòng
      csvContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

      if (csvContent.isEmpty) {
        throw Exception('Nội dung CSV trống');
      }

      final lines = csvContent.split('\n');
      final List<Flashcard> flashcards = [];
      int skippedLines = 0;

      // Bỏ qua dòng đầu nếu là header (Mặt trước, Mặt sau, Ví dụ)
      int startIndex = 0;
      if (lines.isNotEmpty &&
          lines[0].trim().toLowerCase().contains('mặt trước') ||
          lines[0].trim().toLowerCase().contains('front')) {
        startIndex = 1;
      }

      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Tách bằng dấu phẩy (hỗ trợ cả dấu phẩy trong ngoặc kép nếu cần sau này)
        final parts = const CsvToListConverter(eol: '\n').convert(line).first;

        if (parts.length < 2) {
          skippedLines++;
          continue;
        }

        final front = parts[0].toString().trim();
        final back = parts[1].toString().trim();
        final example = parts.length > 2 ? parts[2].toString().trim() : '';

        if (front.isEmpty || back.isEmpty) {
          skippedLines++;
          continue;
        }

        flashcards.add(Flashcard(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          deckId: deckId,
          front: front,
          back: back,
          example: example,
        ));
      }

      if (flashcards.isEmpty) {
        throw Exception('Không có thẻ hợp lệ nào được nhập');
      }

      if (skippedLines > 0) {
        print('Đã bỏ qua $skippedLines dòng không hợp lệ');
      }

      return flashcards;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi định dạng CSV: $e');
    }
  }

  /// Export danh sách thẻ → chuỗi CSV để chỉnh sửa
  static String exportToCsv(List<Flashcard> flashcards) {
    final rows = <List<String>>[];

    // Header
    rows.add(['Mặt trước', 'Mặt sau', 'Ví dụ']);

    // Dữ liệu
    for (final card in flashcards) {
      rows.add([
        card.front,
        card.back,
        card.example,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Dùng để xem trước CSV (trong màn hình import)
  static List<List<dynamic>> parseCsv(String csvContent) {
    try {
      csvContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final lines = csvContent.split('\n');
      final result = <List<dynamic>>[];

      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        result.add(parts.map((e) => e.trim()).toList());
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Mẫu CSV để người dùng dán vào
  static String getCsvTemplate() {
    return '''Mặt trước,Mặt sau,Ví dụ
Hello,Xin chào,Hello everyone!
Thank you,Cảm ơn,Thank you very much!
Good morning,Chào buổi sáng,Good morning, how are you?
Apple,Quả táo,I eat an apple every day.
Cat,Con mèo,The cat is sleeping.''';
  }
}