import 'package:flutter/material.dart';

class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EnhancedAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: const Text(
        'Quản lý Thực thể',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () => _showSearchDialog(context),
          icon: const Icon(Icons.search, color: Colors.white),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Nhập từ khóa tìm kiếm...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
