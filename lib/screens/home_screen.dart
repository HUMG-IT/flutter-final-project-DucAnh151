import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'main.dart';
import '../models/deck.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import 'study_screen.dart';
import 'progress_screen.dart';
import 'import_screen.dart';
import 'settings_screen.dart';
import '../widgets/deck_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool)? toggleDarkMode;
  final bool? isDarkMode;
  
  const HomeScreen({Key? key, this.toggleDarkMode, this.isDarkMode}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Deck> decks = [];
  List<Deck> filteredDecks = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortOption = 'newest'; // newest, name, important, progress
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDecks();
    deckUpdateNotifier.addListener(_loadDecks);
  }

  @override
  void dispose() {
    deckUpdateNotifier.removeListener(_loadDecks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final loadedDecks = await StorageService.getDecks();
    
    // Sắp xếp
    _sortDecks(loadedDecks);
    
    if (mounted) {
      setState(() {
        decks = loadedDecks;
        filteredDecks = List.from(decks);
        isLoading = false;
      });
    }
  }

  void _sortDecks(List<Deck> list) {
    switch (sortOption) {
      case 'name':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'important':
        list.sort((a, b) {
          if (a.isImportant && !b.isImportant) return -1;
          if (!a.isImportant && b.isImportant) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'progress':
        // Sắp xếp theo tiến độ (cao đến thấp)
        list.sort((a, b) {
          final progressA = a.masteredCount / (a.cardCount == 0 ? 1 : a.cardCount);
          final progressB = b.masteredCount / (b.cardCount == 0 ? 1 : b.cardCount);
          return progressB.compareTo(progressA);
        });
        break;
    }
  }

  void _filterDecks(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredDecks = List.from(decks);
      } else {
        filteredDecks = decks.where((deck) {
          return deck.name.toLowerCase().contains(query.toLowerCase()) ||
                 deck.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _changeSortOption(String? value) {
    if (value != null) {
      setState(() {
        sortOption = value;
        _sortDecks(decks);
        _filterDecks(searchQuery);
      });
    }
  }

  void _startStudy(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(deck: deck),
        fullscreenDialog: true,
      ),
    ).then((_) => _loadDecks());
  }

  void _showDeckOptions(Deck deck) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              deck.isImportant ? Icons.star : Icons.star_border,
              color: deck.isImportant ? Colors.amber : null,
            ),
            title: Text(deck.isImportant ? 'Bỏ đánh dấu quan trọng' : 'Đánh dấu quan trọng'),
            onTap: () {
              Navigator.pop(context);
              _toggleImportantDeck(deck);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Chỉnh sửa bộ thẻ'),
            onTap: () {
              Navigator.pop(context);
              _editDeckWithCsv(deck);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xoá bộ thẻ', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteDeck(deck);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _toggleImportantDeck(Deck deck) async {
    deck.isImportant = !deck.isImportant;
    await StorageService.saveDeck(deck);
    deckUpdateNotifier.value++;
  }

  void _editDeckWithCsv(Deck deck) async {
    final currentCards = await StorageService.getFlashcardsByDeck(deck.id);
    final currentCsv = CsvService.exportToCsv(currentCards);

    final nameCtrl = TextEditingController(text: deck.name);
    final descCtrl = TextEditingController(text: deck.description);
    final csvCtrl = TextEditingController(text: currentCsv);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Chỉnh sửa bộ thẻ: ${deck.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên bộ thẻ *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tuỳ chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nội dung CSV', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: csvCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'Mặt trước,Mặt sau,Ví dụ\nHello,Xin chào,...',
                  ),
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tên không được để trống')),
                );
                return;
              }

              try {
                final newCards = await CsvService.importFromCsv(csvCtrl.text, deck.id);
                deck.name = nameCtrl.text.trim();
                deck.description = descCtrl.text.trim();
                deck.cardCount = newCards.length;

                await StorageService.replaceFlashcardsForDeck(deck.id, newCards);
                await StorageService.saveDeck(deck);

                Navigator.pop(context);
                deckUpdateNotifier.value++;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cập nhật thành công! (${newCards.length} thẻ)')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá bộ thẻ'),
        content: Text('Xoá vĩnh viễn "${deck.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.deleteDeck(deck.id);
      deckUpdateNotifier.value++;
    }
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Tạo từ file CSV'),
            onTap: () {
              Navigator.pop(context);
              _importFromFile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Tạo từ văn bản CSV'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImportScreen(),
                  fullscreenDialog: true,
                ),
              ).then((_) => deckUpdateNotifier.value++);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      
      if (result == null || result.files.single.path == null) return;

      final csvContent = await File(result.files.single.path!).readAsString();
      final nameCtrl = TextEditingController();
      final descCtrl = TextEditingController();

      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tạo bộ thẻ mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên bộ thẻ *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: nameCtrl.text.trim().isNotEmpty
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Tạo'),
            ),
          ],
        ),
      );

      if (ok == true && nameCtrl.text.trim().isNotEmpty) {
        final deck = Deck(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
        final cards = await CsvService.importFromCsv(csvContent, deck.id);
        deck.cardCount = cards.length;
        await StorageService.saveDeck(deck);
        await StorageService.saveFlashcards(cards);
        deckUpdateNotifier.value++;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo bộ thẻ với ${cards.length} thẻ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterDecks('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Học Tập'),
        actions: [
          // Dropdown sắp xếp
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: sortOption,
              icon: const Icon(Icons.sort),
              underline: Container(),
              onChanged: _changeSortOption,
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                DropdownMenuItem(value: 'name', child: Text('A-Z')),
                DropdownMenuItem(value: 'important', child: Text('Quan trọng')),
                DropdownMenuItem(value: 'progress', child: Text('Tiến độ')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Tiến độ học tập',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProgressScreen(),
                fullscreenDialog: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () {
              if (widget.toggleDarkMode != null && widget.isDarkMode != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      toggleDarkMode: widget.toggleDarkMode!,
                      isDarkMode: widget.isDarkMode!,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      toggleDarkMode: (value) {},
                      isDarkMode: false,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : decks.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportOptions,
        icon: const Icon(Icons.add),
        label: const Text('Tạo thẻ mới'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books, size: 100, color: Colors.grey),
          const Text('Chưa có bộ thẻ nào', style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showImportOptions,
            icon: const Icon(Icons.add),
            label: const Text('Tạo bộ thẻ đầu tiên'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search bar với animation
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bộ thẻ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: _filterDecks,
          ),
        ),
        // Thống kê nhanh
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Chip(
                label: Text('${decks.length} bộ thẻ'),
                backgroundColor: Colors.blue.shade50,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${decks.where((d) => d.isImportant).length} quan trọng'),
                backgroundColor: Colors.amber.shade50,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDecks,
            child: filteredDecks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy bộ thẻ nào',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tìm kiếm: "$searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredDecks.length,
                    itemBuilder: (_, i) => DeckWidget(
                      deck: filteredDecks[i],
                      onTap: () => _startStudy(filteredDecks[i]),
                      onLongPress: () => _showDeckOptions(filteredDecks[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}