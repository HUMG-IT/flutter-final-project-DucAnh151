import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) toggleDarkMode;
  final bool isDarkMode;
  
  const SettingsScreen({
    Key? key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _soundEnabled = true;
  int _dailyGoal = 20;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _dailyGoal = prefs.getInt('daily_goal') ?? 20;
    });
  }

  Future<void> _saveDarkMode(bool value) async {
    widget.toggleDarkMode(value);
    if (!mounted) return;
    setState(() => _darkMode = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Đã bật chế độ tối' : 'Đã tắt chế độ tối'),
          backgroundColor: value ? Colors.purple : Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    if (!mounted) return;
    setState(() => _notifications = value);
  }

  Future<void> _saveSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    if (!mounted) return;
    setState(() => _soundEnabled = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Đã bật âm thanh' : 'Đã tắt âm thanh'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveDailyGoal(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', value);
    if (!mounted) return;
    setState(() => _dailyGoal = value);
  }

  Future<void> _confirmClearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red, size: 50),
        title: const Text('Xoá toàn bộ dữ liệu?'),
        content: const Text(
          'Tất cả bộ thẻ và tiến độ học tập sẽ bị xoá vĩnh viễn.\n'
          'Hành động này KHÔNG THỂ HOÀN TÁC!',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá tất cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await StorageService.clearAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xoá toàn bộ dữ liệu ứng dụng'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Giao diện
          _buildSectionHeader('Giao diện'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Chế độ tối'),
            subtitle: const Text('Giao diện tối, dễ nhìn ban đêm'),
            value: _darkMode,
            onChanged: _saveDarkMode,
          ),

          // Học tập
          _buildSectionHeader('Học tập'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Bật/Tắt âm thanh'),
            subtitle: const Text('Chuyển văn bản thành lời nói'),
            value: _soundEnabled,
            onChanged: _saveSoundEnabled,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Thông báo nhắc học'),
            subtitle: const Text('Nhận nhắc nhở hàng ngày'),
            value: _notifications,
            onChanged: _saveNotifications,
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Mục tiêu hàng ngày'),
            subtitle: Text('Hiện tại: $_dailyGoal thẻ/ngày'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _dailyGoal > 5 ? () => _saveDailyGoal(_dailyGoal - 5) : null,
                ),
                Text('$_dailyGoal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _dailyGoal < 200 ? () => _saveDailyGoal(_dailyGoal + 5) : null,
                ),
              ],
            ),
          ),

          // Dữ liệu
          _buildSectionHeader('Dữ liệu & Bảo mật'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xoá toàn bộ dữ liệu'),
            subtitle: const Text('Xóa sạch bộ thẻ và tiến độ'),
            onTap: _confirmClearAllData,
          ),

          // Về ứng dụng
          _buildSectionHeader('Thông tin'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Về ứng dụng'),
            subtitle: const Text('Phiên bản 1.1.0'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Flashcard Học Tập',
              applicationVersion: '1.1.0',
              applicationIcon: const Icon(Icons.menu_book, size: 60, color: Colors.blue),
              children: const [
                SizedBox(height: 16),
                Text('Ứng dụng học từ vựng thông minh bằng flashcard'),
                SizedBox(height: 12),
                Text('• Thuật toán Spaced Repetition'),
                Text('• Chuyển văn bản thành lời nói'),
                Text('• Import từ CSV'),
                Text('• Thống kê chi tiết'),
                Text('• Hoàn toàn offline'),
                SizedBox(height: 16),
                Text('© 2025 Flashcard Học Tập', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}