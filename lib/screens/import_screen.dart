import 'package:flutter/material.dart';
import '../services/csv_service.dart';
import '../services/storage_service.dart';
import '../models/deck.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<List<dynamic>> csvData = [];
  bool isLoading = false;
  final TextEditingController deckNameController = TextEditingController();
  final TextEditingController deckDescController = TextEditingController();
  final TextEditingController csvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplate();
    });
  }

  Future<void> _previewCsv() async {
    if (csvController.text.isEmpty) {
      setState(() => csvData = []);
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = CsvService.parseCsv(csvController.text);
      setState(() {
        csvData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        csvData = [];
        isLoading = false;
      });
    }
  }

  void _loadTemplate() {
    csvController.text = CsvService.getCsvTemplate();
    _previewCsv();
  }

  Future<void> _importData() async {
    if (deckNameController.text.isEmpty) {
      _showError('Vui lòng nhập tên bộ thẻ');
      return;
    }

    if (csvController.text.isEmpty) {
      _showError('Vui lòng nhập nội dung CSV');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Tạo bộ thẻ
      final deck = Deck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: deckNameController.text,
        description: deckDescController.text,
      );

      // Nhập thẻ
      final flashcards = await CsvService.importFromCsv(csvController.text, deck.id);

      if (flashcards.isEmpty) {
        throw Exception('Không tìm thấy thẻ hợp lệ trong CSV');
      }

      // Lưu vào bộ nhớ
      await StorageService.saveDeck(deck);
      await StorageService.saveFlashcards(flashcards);

      // Cập nhật số thẻ
      deck.cardCount = flashcards.length;
      await StorageService.saveDeck(deck);

      // Hiển thị thông báo thành công
      _showSuccess(flashcards.length);
    } catch (e) {
      String errorMessage = 'Nhập thất bại: $e';
      
      // Hiển thị thông báo chi tiết hơn
      if (e.toString().contains('bị bỏ qua do thiếu dữ liệu')) {
        errorMessage = 'Nhập thất bại: Có dòng bị thiếu dữ liệu. Mỗi dòng cần có ít nhất 2 cột (Mặt trước và Mặt sau) không để trống.';
      } else if (e.toString().contains('thiếu dữ liệu mặt trước hoặc mặt sau')) {
        errorMessage = 'Nhập thất bại: Có dòng bị thiếu mặt trước hoặc mặt sau. Vui lòng kiểm tra lại.';
      }
      
      _showError(errorMessage);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccess(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo thành công'),
        content: Text('Đã tạo bộ thẻ với $count thẻ'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo thẻ mới từ CSV'), // ĐỔI TÊN
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin bộ thẻ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: deckNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên bộ thẻ *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: deckDescController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả (tuỳ chọn)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nội dung CSV',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mỗi dòng một thẻ, ngăn cách bằng dấu phẩy',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: csvController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                            hintText: 'Dán CSV vào đây...',
                          ),
                          onChanged: (value) {
                            _previewCsv();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadTemplate,
                        icon: const Icon(Icons.file_copy),
                        label: const Text('Tải mẫu'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (csvData.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Xem trước',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${csvData.length - 1} thẻ',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowHeight: 40,
                              dataRowMinHeight: 40,
                              dataRowMaxHeight: 60,
                              columns: const [
                                DataColumn(label: Text('Mặt trước')),
                                DataColumn(label: Text('Mặt sau')),
                                DataColumn(label: Text('Ví dụ')),
                              ],
                              rows: csvData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final row = entry.value;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        row.isNotEmpty ? row[0].toString() : '',
                                        style: TextStyle(
                                          fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(row.length > 1 ? row[1].toString() : '')),
                                    DataCell(Text(row.length > 2 ? row[2].toString() : '')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading || csvController.text.isEmpty ? null : _importData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Tạo thẻ mới', // ĐỔI TÊN
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}